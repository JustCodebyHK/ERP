const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const db = require('../db');
const { authRequired } = require('../middleware/auth');

const router = express.Router();
const ROLES = ['student', 'teacher', 'parent'];
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// Ensure email verification columns exist (idempotent, safe on every start).
// Adds email_verified and verification_token to users if absent.
async function ensureSchema() {
  try {
    await db.query(
      `ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT FALSE`
    );
    await db.query(
      `ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_token VARCHAR(255)`
    );
    await db.query(
      `ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_expires TIMESTAMPTZ`
    );
  } catch (err) {
    // Non-fatal: schema may already be up to date or table may not exist yet.
    console.error('Auth schema ensure warning:', err.message);
  }
}
ensureSchema();

// Simple in-memory rate limiter (no external deps).
// Key = IP, value = { count, windowStart }. Resets every 60 seconds.
const rateLimitMap = new Map();
function rateLimiter(req, res, next) {
  const ip = req.ip || req.connection.remoteAddress || 'unknown';
  const now = Date.now();
  const entry = rateLimitMap.get(ip);
  if (!entry || now - entry.windowStart > 60000) {
    rateLimitMap.set(ip, { count: 1, windowStart: now });
    return next();
  }
  if (entry.count >= 10) {
    return res.status(429).json({ error: 'Too many requests. Try again later.' });
  }
  entry.count += 1;
  next();
}

function signToken(user) {
  return jwt.sign(
    { sub: user.id, role: user.role, name: user.name },
    process.env.JWT_SECRET,
    { expiresIn: '15m' }
  );
}

function signRefreshToken(user) {
  return jwt.sign(
    { sub: user.id, role: user.role, type: 'refresh' },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );
}

function publicUser(user) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    role: user.role,
    email_verified: user.email_verified === true,
  };
}

// POST /api/auth/register — creates account with email_verified = false
router.post('/register', rateLimiter, async (req, res, next) => {
  try {
    const { name, email, password, role } = req.body || {};
    if (!name || typeof name !== 'string' || !name.trim()) {
      return res.status(400).json({ error: 'Name is required' });
    }
    if (!email || !EMAIL_RE.test(email)) {
      return res.status(400).json({ error: 'Valid college email is required' });
    }
    const emailLower = email.toLowerCase();
    if (!emailLower.endsWith('@ybit.ac.in')) {
      return res.status(400).json({ error: 'Email must end with @ybit.ac.in' });
    }
    if (!password || password.length < 12) {
      return res.status(400).json({ error: 'Password must be at least 12 characters' });
    }
    if (!ROLES.includes(role)) {
      return res.status(400).json({ error: `Role must be one of: ${ROLES.join(', ')}` });
    }

    const hash = await bcrypt.hash(password, 10);
    const verificationToken = crypto.randomBytes(32).toString('hex');
    const verificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24h

    const result = await db.query(
      `INSERT INTO users (name, email, password_hash, role, email_verified, verification_token, verification_expires)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id, name, email, role, email_verified`,
      [name.trim(), emailLower, hash, role, false, verificationToken, verificationExpires]
    );
    const user = result.rows[0];

    // In production, send the verification token out-of-band (email/SMS).
    // For this app we return it so the client can call /api/auth/verify-email.
    res.status(201).json({
      user: publicUser(user),
      verificationToken,
      message: 'Account created. Verify your email before signing in.',
    });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'An account with this email already exists' });
    }
    next(err);
  }
});

// POST /api/auth/login — requires email_verified
router.post('/login', rateLimiter, async (req, res, next) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    const result = await db.query(
      'SELECT id, name, email, role, password_hash, email_verified FROM users WHERE email = $1',
      [email.toLowerCase()]
    );
    const user = result.rows[0];
    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    if (user.email_verified !== true) {
      return res.status(403).json({
        error: 'Email not verified',
        message: 'Please verify your email before signing in.',
      });
    }
    res.json({ token: signToken(user), refreshToken: signRefreshToken(user), user: publicUser(user) });
  } catch (err) {
    next(err);
  }
});

// GET /api/auth/verify-email — verify email with token
router.get('/verify-email', async (req, res, next) => {
  try {
    const { token } = req.query;
    if (!token) {
      return res.status(400).json({ error: 'Verification token is required' });
    }
    const result = await db.query(
      `SELECT id, name, email, role, email_verified, verification_token, verification_expires
       FROM users WHERE verification_token = $1`,
      [token]
    );
    const user = result.rows[0];
    if (!user) {
      return res.status(400).json({ error: 'Invalid verification token' });
    }
    if (user.email_verified === true) {
      return res.json({ message: 'Email already verified' });
    }
    if (!user.verification_expires || new Date(user.verification_expires) < new Date()) {
      return res.status(400).json({ error: 'Verification token has expired' });
    }
    await db.query(
      `UPDATE users SET email_verified = TRUE, verification_token = NULL, verification_expires = NULL WHERE id = $1`,
      [user.id]
    );
    res.json({ message: 'Email verified successfully. You can now sign in.' });
  } catch (err) {
    next(err);
  }
});

// POST /api/auth/resend-verification — re-send verification token
router.post('/resend-verification', rateLimiter, async (req, res, next) => {
  try {
    const { email } = req.body || {};
    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }
    const result = await db.query(
      'SELECT id, name, email, email_verified, verification_token, verification_expires FROM users WHERE email = $1',
      [email.toLowerCase()]
    );
    const user = result.rows[0];
    if (!user) {
      // Don't reveal whether email exists
      return res.json({ message: 'If an account exists, a verification token has been sent.' });
    }
    if (user.email_verified === true) {
      return res.json({ message: 'Email already verified.' });
    }
    // Generate new token (rotate if existing one is still valid)
    const verificationToken = crypto.randomBytes(32).toString('hex');
    const verificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24h
    await db.query(
      `UPDATE users SET verification_token = $1, verification_expires = $2 WHERE id = $3`,
      [verificationToken, verificationExpires, user.id]
    );
    // In production, send the token out-of-band (email/SMS).
    res.json({
      message: 'Verification token resent.',
      verificationToken,
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/auth/refresh — exchange refresh token for new access token
router.post('/refresh', async (req, res, next) => {
  try {
    const { refreshToken } = req.body || {};
    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token is required' });
    }
    let payload;
    try {
      payload = jwt.verify(refreshToken, process.env.JWT_SECRET);
    } catch {
      return res.status(401).json({ error: 'Invalid or expired refresh token' });
    }
    if (payload.type !== 'refresh') {
      return res.status(401).json({ error: 'Invalid token type' });
    }
    const result = await db.query(
      'SELECT id, name, email, role, email_verified FROM users WHERE id = $1',
      [payload.sub]
    );
    const user = result.rows[0];
    if (!user) {
      return res.status(401).json({ error: 'Account no longer exists' });
    }
    if (user.email_verified !== true) {
      return res.status(403).json({ error: 'Email not verified' });
    }
    res.json({ token: signToken(user), user: publicUser(user) });
  } catch (err) {
    next(err);
  }
});

// GET /api/auth/me
router.get('/me', authRequired, async (req, res, next) => {
  try {
    const result = await db.query(
      'SELECT id, name, email, role, email_verified FROM users WHERE id = $1',
      [req.user.sub]
    );
    if (!result.rows[0]) {
      return res.status(401).json({ error: 'Account no longer exists' });
    }
    res.json({ user: publicUser(result.rows[0]) });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
