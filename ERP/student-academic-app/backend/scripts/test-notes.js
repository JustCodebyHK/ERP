const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function testNotes(subjectId = null) {
  const client = await pool.connect();
  try {
    let query = 'SELECT * FROM notes';
    const params = [];
    if (subjectId) {
      query += ' WHERE subject_id = $1';
      params.push(subjectId);
    }
    query += ' ORDER BY created_at DESC';
    const result = await client.query(query, params);
    console.log(`Found ${result.rows.length} notes`);
  } finally {
    client.release();
  }
}

const subjectId = process.argv[2] || null;
testNotes(subjectId).catch(err => { console.error(err); process.exit(1); });
