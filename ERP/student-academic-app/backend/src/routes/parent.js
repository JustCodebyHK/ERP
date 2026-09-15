const express = require('express');
const db = require('../db');
const { authRequired, requireRole } = require('../middleware/auth');

const router = express.Router();

// POST /api/parent/link — parent links to a student (or admin creates link)
// Body: { student_email, relationship }
router.post('/link', authRequired, requireRole('parent'), async (req, res, next) => {
  try {
    const { student_email, relationship } = req.body || {};
    if (!student_email) {
      return res.status(400).json({ error: 'student_email required' });
    }

    const student = await db.query(
      'SELECT id FROM users WHERE email = $1 AND role = $2',
      [student_email.toLowerCase(), 'student']
    );
    if (!student.rows[0]) {
      return res.status(404).json({ error: 'Student not found' });
    }

    await db.query(
      `INSERT INTO parent_student_links (parent_id, student_id, relationship)
       VALUES ($1, $2, $3)
       ON CONFLICT (parent_id, student_id) DO UPDATE SET relationship = EXCLUDED.relationship`,
      [req.user.sub, student.rows[0].id, relationship || 'parent']
    );

    res.status(201).json({ success: true });
  } catch (err) {
    next(err);
  }
});

// GET /api/parent/children — list linked students
router.get('/children', authRequired, requireRole('parent'), async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT u.id, u.name, u.email, psl.relationship, u.created_at
       FROM parent_student_links psl
       JOIN users u ON u.id = psl.student_id
       WHERE psl.parent_id = $1`,
      [req.user.sub]
    );
    res.json({ children: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/parent/children/:studentId/overview — comprehensive child overview
router.get('/children/:studentId/overview', authRequired, requireRole('parent'), async (req, res, next) => {
  try {
    const { studentId } = req.params;

    // Verify linkage
    const link = await db.query(
      'SELECT 1 FROM parent_student_links WHERE parent_id = $1 AND student_id = $2',
      [req.user.sub, studentId]
    );
    if (!link.rows[0]) {
      return res.status(403).json({ error: 'Not linked to this student' });
    }

    const student = await db.query(
      'SELECT id, name, email FROM users WHERE id = $1 AND role = $2',
      [studentId, 'student']
    );
    if (!student.rows[0]) {
      return res.status(404).json({ error: 'Student not found' });
    }

    // Get student's active batch
    const batch = await db.query(
      `SELECT b.id, b.name FROM batches b
       JOIN enrollments e ON e.batch_id = b.id AND b.is_active
       WHERE e.student_id = $1 LIMIT 1`,
      [studentId]
    );

    let attendance = [], marks = [], assignments = [], announcements = [];

    if (batch.rows[0]) {
      const batchId = batch.rows[0].id;

      // Attendance summary
      attendance = await db.query(
        `SELECT s.code, s.name,
                COUNT(a.id) as total_lectures,
                COUNT(CASE WHEN a.present THEN 1 END) as attended,
                ROUND(COUNT(CASE WHEN a.present THEN 1 END) * 100.0 / NULLIF(COUNT(a.id), 0), 1) as percentage
         FROM subjects s
         JOIN batch_subjects bs ON bs.subject_id = s.id AND bs.batch_id = $1
         LEFT JOIN attendance a ON a.subject_id = s.id AND a.student_id = $2
         GROUP BY s.id, s.code, s.name
         ORDER BY percentage ASC`,
        [batchId, studentId]
      );

      // Marks
      marks = await db.query(
        `SELECT s.code, s.name, m.type, m.score, m.max_score, m.created_at,
                ROUND(m.score * 100.0 / m.max_score, 1) as percentage
         FROM marks m
         JOIN subjects s ON s.id = m.subject_id
         WHERE m.student_id = $1 AND m.batch_id = $2
         ORDER BY m.created_at DESC`,
        [studentId, batchId]
      );

      // Assignments summary
      assignments = await db.query(
        `SELECT a.title, a.due_at, a.max_score,
                sub.status, sub.submitted_at, sub.score,
                s.code as subject_code, s.name as subject_name
         FROM assignments a
         JOIN subjects s ON s.id = a.subject_id
         LEFT JOIN submissions sub ON sub.assignment_id = a.id AND sub.student_id = $1
         WHERE a.batch_id = $2
         ORDER BY a.due_at DESC`,
        [studentId, batchId]
      );

      // Recent announcements
      announcements = await db.query(
        `SELECT a.title, a.body, a.type, a.published_at, b.name as batch_name
         FROM announcements a
         LEFT JOIN batches b ON b.id = a.batch_id
         WHERE a.is_active
           AND (a.batch_id IS NULL OR a.batch_id = $1)
         ORDER BY a.published_at DESC
         LIMIT 10`,
        [batchId]
      );
    }

    res.json({
      student: student.rows[0],
      batch: batch.rows[0] || null,
      attendance: attendance.rows,
      marks: marks.rows,
      assignments: assignments.rows,
      announcements: announcements.rows,
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/parent/children/:studentId/attendance — detailed attendance
router.get('/children/:studentId/attendance', authRequired, requireRole('parent'), async (req, res, next) => {
  try {
    const { studentId } = req.params;
    const link = await db.query(
      'SELECT 1 FROM parent_student_links WHERE parent_id = $1 AND student_id = $2',
      [req.user.sub, studentId]
    );
    if (!link.rows[0]) return res.status(403).json({ error: 'Not linked' });

    const batch = await db.query(
      `SELECT b.id FROM batches b
       JOIN enrollments e ON e.batch_id = b.id AND b.is_active
       WHERE e.student_id = $1 LIMIT 1`,
      [studentId]
    );
    if (!batch.rows[0]) return res.json({ attendance: [] });

    const result = await db.query(
      `SELECT a.*, s.code, s.name as subject_name
       FROM attendance a
       JOIN subjects s ON s.id = a.subject_id
       WHERE a.student_id = $1 AND a.batch_id = $2
       ORDER BY a.date DESC, a.start_time DESC`,
      [studentId, batch.rows[0].id]
    );
    res.json({ attendance: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/parent/children/:studentId/marks — detailed marks
router.get('/children/:studentId/marks', authRequired, requireRole('parent'), async (req, res, next) => {
  try {
    const { studentId } = req.params;
    const link = await db.query(
      'SELECT 1 FROM parent_student_links WHERE parent_id = $1 AND student_id = $2',
      [req.user.sub, studentId]
    );
    if (!link.rows[0]) return res.status(403).json({ error: 'Not linked' });

    const batch = await db.query(
      `SELECT b.id FROM batches b
       JOIN enrollments e ON e.batch_id = b.id AND b.is_active
       WHERE e.student_id = $1 LIMIT 1`,
      [studentId]
    );
    if (!batch.rows[0]) return res.json({ marks: [] });

    const result = await db.query(
      `SELECT m.*, s.code, s.name as subject_name
       FROM marks m
       JOIN subjects s ON s.id = m.subject_id
       WHERE m.student_id = $1 AND m.batch_id = $2
       ORDER BY m.created_at DESC`,
      [studentId, batch.rows[0].id]
    );
    res.json({ marks: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/parent/children/:studentId/assignments — assignments with status
router.get('/children/:studentId/assignments', authRequired, requireRole('parent'), async (req, res, next) => {
  try {
    const { studentId } = req.params;
    const link = await db.query(
      'SELECT 1 FROM parent_student_links WHERE parent_id = $1 AND student_id = $2',
      [req.user.sub, studentId]
    );
    if (!link.rows[0]) return res.status(403).json({ error: 'Not linked' });

    const batch = await db.query(
      `SELECT b.id FROM batches b
       JOIN enrollments e ON e.batch_id = b.id AND b.is_active
       WHERE e.student_id = $1 LIMIT 1`,
      [studentId]
    );
    if (!batch.rows[0]) return res.json({ assignments: [] });

    const result = await db.query(
      `SELECT a.*, sub.status, sub.submitted_at, sub.score, sub.graded_at,
              s.code as subject_code, s.name as subject_name
       FROM assignments a
       JOIN subjects s ON s.id = a.subject_id
       LEFT JOIN submissions sub ON sub.assignment_id = a.id AND sub.student_id = $1
       WHERE a.batch_id = $2
       ORDER BY a.due_at DESC`,
      [studentId, batch.rows[0].id]
    );
    res.json({ assignments: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/parent/children/:studentId/announcements — announcements for child's batch
router.get('/children/:studentId/announcements', authRequired, requireRole('parent'), async (req, res, next) => {
  try {
    const { studentId } = req.params;
    const link = await db.query(
      'SELECT 1 FROM parent_student_links WHERE parent_id = $1 AND student_id = $2',
      [req.user.sub, studentId]
    );
    if (!link.rows[0]) return res.status(403).json({ error: 'Not linked' });

    const batch = await db.query(
      `SELECT b.id FROM batches b
       JOIN enrollments e ON e.batch_id = b.id AND b.is_active
       WHERE e.student_id = $1 LIMIT 1`,
      [studentId]
    );
    const batchId = batch.rows[0]?.id;

    const result = await db.query(
      `SELECT a.*, b.name as batch_name
       FROM announcements a
       LEFT JOIN batches b ON b.id = a.batch_id
       WHERE a.is_active
         AND (a.batch_id IS NULL ${batchId ? 'OR a.batch_id = $1' : ''})
       ORDER BY a.published_at DESC
       LIMIT 20`,
      batchId ? [batchId] : []
    );
    res.json({ announcements: result.rows });
  } catch (err) {
    next(err);
  }
});

module.exports = router;