require('dotenv').config();
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const migrationDir = path.join(__dirname, '..', 'migrations');

async function ensureMigrationTable(client) {
  await client.query(`CREATE TABLE IF NOT EXISTS schema_migrations (version VARCHAR(50) PRIMARY KEY)`);

  // Older versions of this app recorded applied migrations in `_migrations`.
  // Import those records so existing databases aren't migrated a second time.
  const legacy = await client.query(`SELECT to_regclass('public._migrations') AS table_name`);
  if (legacy.rows[0].table_name) {
    await client.query(
      `INSERT INTO schema_migrations (version)
       SELECT name FROM _migrations
       ON CONFLICT (version) DO NOTHING`
    );
  }
}

async function runMigrations(dryRun = false) {
  const files = fs.readdirSync(migrationDir).sort();
  const client = await pool.connect();
  try {
    await ensureMigrationTable(client);
    const applied = await client.query('SELECT version FROM schema_migrations');
    const appliedSet = new Set(applied.rows.map(r => r.version));
    for (const file of files) {
      if (appliedSet.has(file)) continue;
      const sql = fs.readFileSync(path.join(migrationDir, file), 'utf8');
      if (dryRun) {
        console.log(`[DRY-RUN] Would run: ${file}`);
      } else {
        await client.query(sql);
        await client.query('INSERT INTO schema_migrations (version) VALUES ($1)', [file]);
        console.log(`Applied: ${file}`);
      }
    }
    console.log('Migrations complete.');
  } finally {
    client.release();
  }
}

async function showStatus() {
  const client = await pool.connect();
  try {
    await ensureMigrationTable(client);
    const applied = await client.query('SELECT version FROM schema_migrations');
    const appliedSet = new Set(applied.rows.map(r => r.version));
    const files = fs.readdirSync(migrationDir).sort();
    console.log('Migration status:');
    for (const file of files) {
      const status = appliedSet.has(file) ? 'applied' : 'pending';
      console.log(`  [${status}] ${file}`);
    }
  } finally {
    client.release();
  }
}

const args = process.argv.slice(2);
const command = args.includes('--status') || args.includes('-s')
  ? showStatus()
  : runMigrations(args.includes('--dry-run'));
command
  .catch(err => { console.error(err); process.exitCode = 1; })
  .finally(() => pool.end());
