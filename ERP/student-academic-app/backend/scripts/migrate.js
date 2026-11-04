const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const migrationDir = path.join(__dirname, '..', 'migrations');

async function runMigrations(dryRun = false) {
  const files = fs.readdirSync(migrationDir).sort();
  const client = await pool.connect();
  try {
    await client.query(`CREATE TABLE IF NOT EXISTS schema_migrations (version VARCHAR(50) PRIMARY KEY)`);
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
    await client.query(`CREATE TABLE IF NOT EXISTS schema_migrations (version VARCHAR(50) PRIMARY KEY)`);
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
if (args.includes('--status') || args.includes('-s')) {
  showStatus().catch(err => { console.error(err); process.exit(1); });
} else {
  const dryRun = args.includes('--dry-run');
  runMigrations(dryRun).catch(err => { console.error(err); process.exit(1); });
}
