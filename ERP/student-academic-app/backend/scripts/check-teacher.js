const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function checkTeacher(teacherId, subjectId = null) {
  const client = await pool.connect();
  try {
    let query = 'SELECT * FROM teachers WHERE id = ';
    const params = [teacherId];
    if (subjectId) {
      query += ' AND subject_id = ';
      params.push(subjectId);
    }
    const result = await client.query(query, params);
    if (result.rows.length === 0) {
      console.log('Teacher not found or not assigned to subject.');
    } else {
      console.log('Teacher verified:', result.rows[0]);
    }
  } finally {
    client.release();
  }
}

const teacherId = process.argv[2];
const subjectId = process.argv[3] || null;
if (!teacherId) {
  console.error('Usage: node check-teacher.js <teacher_id> [subject_id]');
  process.exit(1);
}
checkTeacher(teacherId, subjectId).catch(err => { console.error(err); process.exit(1); });
