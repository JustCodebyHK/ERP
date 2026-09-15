require('dotenv').config();
const db = require('../src/db');

async function check() {
  const teacher = await db.query('SELECT id, name, email FROM users WHERE email = $1', ['rao@ybit.ac.in']);
  console.log('Teacher:', teacher.rows[0]);
  
  if (!teacher.rows[0]) {
    console.log('Teacher not found!');
    return;
  }
  
  const batchSubjects = await db.query('SELECT * FROM batch_subjects WHERE teacher_id = $1', [teacher.rows[0].id]);
  console.log('Batch Subjects:', batchSubjects.rows);
  
  const batches = await db.query('SELECT * FROM batches');
  console.log('Batches:', batches.rows);
  
  const subjects = await db.query('SELECT * FROM subjects');
  console.log('Subjects:', subjects.rows);
  
  process.exit(0);
}

check().catch(e => { console.error(e); process.exit(1); });