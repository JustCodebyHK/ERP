const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function seed(count = 5) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    for (let i = 0; i < count; i++) {
      await client.query(
        `INSERT INTO students (name, email, roll_number) VALUES ($1, $2, $3)`,
        [`Student ${i + 1}`, `student${i + 1}@ybit.ac.in`, `ST${String(i + 1).padStart(3, '0')}`]
      );
    }
    await client.query('COMMIT');
    console.log(`Seeded ${count} students.`);
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

const count = parseInt(process.argv.find(a => a.startsWith('--count='))?.split('=')[1]) || 5;
seed(count).catch(err => { console.error(err); process.exit(1); });
