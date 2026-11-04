const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function testAssignments(status = null) {
  const client = await pool.connect();
  try {
    let query = 'SELECT * FROM assignments';
    const params = [];
    if (status) {
      query += ' WHERE status = $1';
      params.push(status);
    }
    query += ' ORDER BY created_at DESC';
    const result = await client.query(query, params);
    console.log(`Found ${result.rows.length} assignments`);
  } finally {
    client.release();
  }
}

const status = process.argv[2] || null;
testAssignments(status).catch(err => { console.error(err); process.exit(1); });
