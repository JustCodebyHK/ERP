// Structured, sanitizing logger for server-side errors.
// Redacts sensitive fields (DATABASE_URL, JWT_SECRET, stack traces) so they
// are not written to stdout/stderr or log aggregation in production.
const SENSITIVE_KEYS = [
  'DATABASE_URL',
  'JWT_SECRET',
  'CORS_ORIGIN',
  'UPLOAD_DIR',
  'NODE_ENV',
  'PORT',
];

function sanitize(value) {
  if (value === undefined) return '[undefined]';
  if (value === null) return '[null]';
  if (typeof value === 'string') {
    // Redact values that look like connection strings or secrets.
    if (/postgres(?:ql)?:\/\//i.test(value)) return '[REDACTED DATABASE_URL]';
    if (value.length > 200) return value.slice(0, 200) + '...[truncated]';
    return value;
  }
  if (typeof value === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(value)) {
      if (SENSITIVE_KEYS.includes(k.toUpperCase())) {
        out[k] = '[REDACTED]';
      } else if (k === 'stack' || k === 'password' || k === 'secret' || k === 'token') {
        out[k] = '[REDACTED]';
      } else {
        out[k] = sanitize(v);
      }
    }
    return out;
  }
  return value;
}

/**
 * Log an error safely. In production (NODE_ENV === 'production') this writes
 * only a sanitized summary — no stack traces, no secrets. In development it
 * writes the full error for debugging.
 */
function logError(err, req) {
  const entry = {
    timestamp: new Date().toISOString(),
    level: 'error',
    message: err.message || String(err),
    path: req ? req.path : undefined,
    method: req ? req.method : undefined,
    ip: req ? (req.ip || req.connection.remoteAddress || 'unknown') : undefined,
  };

  if (process.env.NODE_ENV === 'production') {
    // Production: sanitized only, no stack trace.
    console.error(JSON.stringify(sanitize(entry)));
  } else {
    // Development: full error for debugging.
    console.error(JSON.stringify(sanitize(entry), null, 2));
    if (err.stack) {
      console.error(err.stack);
    }
  }
}

module.exports = { logError, sanitize };
