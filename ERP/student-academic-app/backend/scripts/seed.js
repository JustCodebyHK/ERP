require('dotenv').config();
const bcrypt = require('bcryptjs');
const db = require('../src/db');

// Demo data for development. Safe to re-run (all inserts are upserts).
async function seed() {
  const hash = await bcrypt.hash('password123', 10);

  async function upsertUser(name, email, role) {
    const r = await db.query(
      `INSERT INTO users (name, email, password_hash, role)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (email) DO UPDATE
       SET name = EXCLUDED.name,
           role = EXCLUDED.role,
           password_hash = EXCLUDED.password_hash
       RETURNING id`,
      [name, email, hash, role]
    );
    return r.rows[0].id;
  }

  const teacher = await upsertUser('Prof. Rao', 'rao@ybit.ac.in', 'teacher');
  const student = await upsertUser('Asha', 'asha@ybit.ac.in', 'student');

  const batch = await db.query(
    `INSERT INTO batches (name) VALUES ('BSc IT - Sem 3 (2026)')
     ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
     RETURNING id`
  );
  const batchId = batch.rows[0].id;

  const subjectIds = [];
  for (const [code, name] of [
    ['IT301', 'Computer Networks'],
    ['IT302', 'Operating Systems'],
    ['IT303', 'Database Management Systems'],
    ['IT304', 'Python Programming'],
  ]) {
    const r = await db.query(
      `INSERT INTO subjects (code, name) VALUES ($1, $2)
       ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name
       RETURNING id`,
      [code, name]
    );
    subjectIds.push(r.rows[0].id);
  }

  for (const subjectId of subjectIds) {
    await db.query(
      `INSERT INTO batch_subjects (batch_id, subject_id, teacher_id)
       VALUES ($1, $2, $3)
       ON CONFLICT (batch_id, subject_id) DO UPDATE SET teacher_id = EXCLUDED.teacher_id`,
      [batchId, subjectId, teacher]
    );
  }

  await db.query(
    `INSERT INTO enrollments (student_id, batch_id) VALUES ($1, $2)
     ON CONFLICT DO NOTHING`,
    [student, batchId]
  );

  // Seed attendance (sample data for last 2 weeks)
  const now = new Date();
  for (let i = 0; i < 10; i++) {
    const date = new Date(now);
    date.setDate(date.getDate() - i);
    // Skip weekends
    if (date.getDay() === 0 || date.getDay() === 6) continue;
    
    for (const subjectId of subjectIds) {
      // 90% attendance rate
      const present = Math.random() > 0.1;
      await db.query(
        `INSERT INTO attendance (batch_id, subject_id, student_id, date, start_time, end_time, present, marked_by)
         VALUES ($1, $2, $3, $4, '09:00', '10:30', $5, $6)
         ON CONFLICT DO NOTHING`,
        [batchId, subjectId, student, date.toISOString().split('T')[0], present, teacher]
      );
    }
  }

  // Seed marks (sample grades)
const markData = [
    { subjectIndex: 0, type: 'assignment', title: 'CN Assignment 1', score: 45, maxScore: 50 },
    { subjectIndex: 0, type: 'quiz', title: 'CN Quiz 1', score: 18, maxScore: 20 },
    { subjectIndex: 1, type: 'assignment', title: 'OS Assignment 1', score: 40, maxScore: 50 },
    { subjectIndex: 2, type: 'assignment', title: 'DBMS Assignment 1', score: 42, maxScore: 50 },
    { subjectIndex: 3, type: 'assignment', title: 'Python Assignment 1', score: 48, maxScore: 50 },
    { subjectIndex: 0, type: 'midterm', title: 'CN Midterm', score: 75, maxScore: 100 },
    { subjectIndex: 1, type: 'midterm', title: 'OS Midterm', score: 80, maxScore: 100 },
  ];
  
  for (const m of markData) {
    await db.query(
      `INSERT INTO marks (batch_id, subject_id, student_id, type, title, score, max_score, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       ON CONFLICT DO NOTHING`,
      [batchId, subjectIds[m.subjectIndex], student, m.type, m.title, m.score, m.maxScore, teacher]
    );
  }

  console.log('Seed complete.');
  console.log('  teacher login: rao@ybit.ac.in / password123');
  console.log('  student login: asha@ybit.ac.in / password123');
  process.exit(0);
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
