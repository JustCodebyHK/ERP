const jwt = require('jsonwebtoken');

const rateLimitMap = new Map();
const RATE_LIMIT_WINDOW = 60000;
const RATE_LIMIT_MAX = 10;

const blacklistedTokens = new Set();

function rateLimiter(req, res, next) {
  const ip = req.ip || req.connection.remoteAddress || 'unknown';
  const now = Date.now();
  const entry = rateLimitMap.get(ip);
  if (!entry || now - entry.windowStart > RATE_LIMIT_WINDOW) {
    rateLimitMap.set(ip, { count: 1, windowStart: now });
    return next();
  }
  if (entry.count >= RATE_LIMIT_MAX) {
    return res.status(429).json({ error: 'Too many requests. Try again later.' });
  }
  entry.count += 1;
  next();
}

function blacklistToken(token) {
  blacklistedTokens.add(token);
}

function isBlacklisted(token) {
  return blacklistedTokens.has(token);
}

function extractToken(req) {
  const header = req.headers.authorization || '';
  return header.startsWith('Bearer ') ? header.slice(7) : null;
}

function getTokenExpiry(token) {
  try {
    const decoded = jwt.decode(token);
    return decoded ? decoded.exp : null;
  } catch {
    return null;
  }
}

function isTokenExpired(token) {
  const exp = getTokenExpiry(token);
  if (!exp) return true;
  return Date.now() >= exp * 1000;
}

function authRequired(req, res, next) {
  const token = extractToken(req);
  if (!token) {
    return res.status(401).json({ error: 'Missing bearer token' });
  }
  if (isBlacklisted(token)) {
    return res.status(401).json({ error: 'Token has been revoked' });
  }
  if (isTokenExpired(token)) {
    return res.status(401).json({ error: 'Token has expired' });
  }
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}

function optionalAuth(req, res, next) {
  const token = extractToken(req);
  if (!token) {
    return next();
  }
  if (isBlacklisted(token)) {
    return next();
  }
  if (isTokenExpired(token)) {
    return next();
  }
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
  } catch {
    // ignore invalid tokens for optional auth
  }
  next();
}

function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Insufficient role' });
    }
    next();
  };
}

function requireAnyRole(...roles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Authentication required' });
    }
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Insufficient role' });
    }
    next();
  };
}

module.exports = { authRequired, optionalAuth, requireRole, requireAnyRole, rateLimiter, blacklistToken, isBlacklisted, extractToken, getTokenExpiry, isTokenExpired };
