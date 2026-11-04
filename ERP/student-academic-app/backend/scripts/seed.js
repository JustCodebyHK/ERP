const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function seed(count = 5) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    for (let i = 0; i < count; i++) {
      await client.query(
        \INSERT INTO students (name, email, roll_number) VALUES (, , )\,
        [\Student \\, \student\@ybit.ac.in\, \ST\\]
      );
    }
    await client.query('COMMIT');
    console.log(\Seeded \ students.\);
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

const count = parseInt(process.argv.find(a => a.startsWith('--count='))?.split('=')[1]) || 5;
seed(count).catch(err => { console.error(err); process.exit(1); });
