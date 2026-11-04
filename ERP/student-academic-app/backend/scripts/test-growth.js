const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function testGrowth(studentId = null) {
  const client = await pool.connect();
  try {
    let query = 'SELECT * FROM growth_records';
    const params = [];
    if (studentId) {
      query += ' WHERE student_id = ';
      params.push(studentId);
    }
    query += ' ORDER BY recorded_at DESC';
    const result = await client.query(query, params);
    console.log(\Found \ growth records\);
  } finally {
    client.release();
  }
}

const studentId = process.argv[2] || null;
testGrowth(studentId).catch(err => { console.error(err); process.exit(1); });
