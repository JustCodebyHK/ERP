const { Pool } = require('pg');

// All DB access goes through this single pool, configured by DATABASE_URL.
// To move to a hosted/scalable Postgres (Supabase, Neon, RDS) later, only
// DATABASE_URL in .env changes — no code changes required.
const pool = process.env.DATABASE_URL
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
    })
  : null;

function isConfigured() {
  return pool !== null;
}

async function query(text, params) {
  if (!pool) {
    throw new Error('DATABASE_URL is not configured');
  }
  return pool.query(text, params);
}

module.exports = { query, isConfigured };
