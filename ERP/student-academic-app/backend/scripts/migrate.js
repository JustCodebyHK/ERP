require('dotenv').config();
const fs = require('fs');
const path = require('path');
const db = require('../src/db');

// Versioned SQL migrations, applied in filename order and recorded so each
// runs exactly once. The same files can be replayed on any Postgres host,
// which is what keeps the "move to scalable DB later" path cheap.
async function migrate() {
  if (!db.isConfigured()) {
    console.error('DATABASE_URL is not configured. Set it in .env first.');
    process.exit(1);
  }

  await db.query(`
    CREATE TABLE IF NOT EXISTS _migrations (
      name TEXT PRIMARY KEY,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `);

  const migrationsDir = path.join(__dirname, '..', 'migrations');
  const files = fs
    .readdirSync(migrationsDir)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  const applied = await db.query('SELECT name FROM _migrations');
  const done = new Set(applied.rows.map((r) => r.name));

  for (const file of files) {
    if (done.has(file)) continue;
    const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
    console.log(`Applying ${file}...`);
    await db.query('BEGIN');
    try {
      await db.query(sql);
      await db.query('INSERT INTO _migrations (name) VALUES ($1)', [file]);
      await db.query('COMMIT');
    } catch (err) {
      await db.query('ROLLBACK');
      console.error(`Failed on ${file}: ${err.message}`);
      process.exit(1);
    }
  }

  console.log('Migrations up to date.');
  process.exit(0);
}

migrate();
