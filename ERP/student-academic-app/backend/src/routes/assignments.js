const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const db = require('../db');
const { authRequired, requireRole } = require('../middleware/auth');

const router = express.Router();

const UPLOAD_DIR = process.env.UPLOAD_DIR || path.join(__dirname, '..', '..', 'uploads');
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOAD_DIR),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `${uuidv4()}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 25 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-powerpoint',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'text/plain',
      'image/jpeg',
      'image/png',
    ];
    cb(null, allowed.includes(file.mimetype));
  },
});

// Helper: determine assignment status for a student
function computeStatus(dueAt, submittedAt) {
  if (!submittedAt) return 'pending';
  if (new Date(submittedAt) > new Date(dueAt)) return 'late';
  return 'submitted';
}

// POST /api/assignments — teacher create assignment for their class
router.post(
  '/',
  authRequired,
  requireRole('teacher'),
  async (req, res, next) => {
    try {
      const { batch_id, subject_id, title, description, due_at, max_score } = req.body;
      if (!batch_id || !subject_id || !title || !due_at) {
        return res.status(400).json({ error: 'batch_id, subject_id, title, due_at required' });
      }

      // Teacher must teach this subject in this batch
      const access = await db.query(
        `SELECT 1 FROM batch_subjects
         WHERE batch_id = $1 AND subject_id = $2 AND teacher_id = $3`,
        [batch_id, subject_id, req.user.sub]
      );
      if (!access.rows[0]) {
        return res.status(403).json({ error: 'Not assigned to this batch+subject' });
      }

      const result = await db.query(
        `INSERT INTO assignments (batch_id, subject_id, title, description, due_at, max_score, created_by)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING *`,
        [batch_id, subject_id, title, description || null, due_at, max_score || 100, req.user.sub]
      );

      // Auto-create pending submissions for all enrolled students
      await db.query(
        `INSERT INTO submissions (assignment_id, student_id, status)
         SELECT $1, e.student_id, 'pending'
         FROM enrollments e
         JOIN batches b ON b.id = e.batch_id AND b.is_active
         WHERE e.batch_id = $1
         ON CONFLICT DO NOTHING`,
        [result.rows[0].id]
      );

      res.status(201).json({ assignment: result.rows[0] });
    } catch (err) {
      next(err);
    }
  }
);

// GET /api/assignments?batch_id=&subject_id= — teacher list assignments for a class
router.get(
  '/',
  authRequired,
  async (req, res, next) => {
    try {
      const { batch_id, subject_id } = req.query;
      if (!batch_id || !subject_id) {
        return res.status(400).json({ error: 'batch_id and subject_id required' });
      }

      let authorized = false;
      if (req.user.role === 'teacher') {
        const r = await db.query(
          `SELECT 1 FROM batch_subjects WHERE batch_id = $1 AND subject_id = $2 AND teacher_id = $3`,
          [batch_id, subject_id, req.user.sub]
        );
        authorized = !!r.rows[0];
      } else if (req.user.role === 'student') {
        const r = await db.query(
          `SELECT 1 FROM enrollments e
           JOIN batches b ON b.id = e.batch_id AND b.is_active
           JOIN batch_subjects bs ON bs.batch_id = b.id
           WHERE e.student_id = $1 AND e.batch_id = $2 AND bs.subject_id = $3`,
          [req.user.sub, batch_id, subject_id]
        );
        authorized = !!r.rows[0];
      }

      if (!authorized) {
        return res.status(403).json({ error: 'Not enrolled/assigned to this class' });
      }

      const result = await db.query(
        `SELECT a.*, 
          (SELECT COUNT(*) FROM submissions s WHERE s.assignment_id = a.id) as total_submissions,
          (SELECT COUNT(*) FROM submissions s WHERE s.assignment_id = a.id AND s.status IN ('submitted','late','graded')) as received
         FROM assignments a
         WHERE a.batch_id = $1 AND a.subject_id = $2
         ORDER BY a.due_at DESC`,
        [batch_id, subject_id]
      );
      res.json({ assignments: result.rows });
    } catch (err) {
      next(err);
    }
  }
);

// GET /api/assignments/my — student: all assignments across their batches, categorized
router.get('/my', authRequired, requireRole('student'), async (req, res, next) => {
  try {
    const now = new Date().toISOString();
    const result = await db.query(
      `SELECT a.*, b.name as batch_name, s.code as subject_code, s.name as subject_name,
              sub.id as submission_id, sub.status, sub.submitted_at, sub.score, sub.file_path
       FROM assignments a
       JOIN batches b ON b.id = a.batch_id AND b.is_active
       JOIN subjects s ON s.id = a.subject_id
       JOIN enrollments e ON e.batch_id = b.id AND e.student_id = $1
       JOIN batch_subjects bs ON bs.batch_id = b.id AND bs.subject_id = s.id
       LEFT JOIN submissions sub ON sub.assignment_id = a.id AND sub.student_id = $1
       WHERE a.due_at >= (now() - interval '30 days')
       ORDER BY a.due_at ASC`,
      [req.user.sub]
    );

    const nowDate = new Date();
    const upcoming = [];
    const dueToday = [];
    const overdue = [];
    const completed = [];

    for (const a of result.rows) {
      const status = a.submission_id ? computeStatus(a.due_at, a.submitted_at) : 'pending';
      const item = { ...a, status };
      if (status === 'pending') {
        if (new Date(a.due_at) <= nowDate) overdue.push(item);
        else if (new Date(a.due_at).toDateString() === nowDate.toDateString()) dueToday.push(item);
        else upcoming.push(item);
      } else {
        completed.push(item);
      }
    }

    res.json({ upcoming, dueToday, overdue, completed });
  } catch (err) {
    next(err);
  }
});

// GET /api/assignments/:id — assignment detail (teacher or enrolled student)
router.get('/:id', authRequired, async (req, res, next) => {
  try {
    const assignment = await db.query('SELECT * FROM assignments WHERE id = $1', [req.params.id]);
    if (!assignment.rows[0]) return res.status(404).json({ error: 'Not found' });
    const a = assignment.rows[0];

    let authorized = false;
    if (req.user.role === 'teacher') {
      const r = await db.query(
        `SELECT 1 FROM batch_subjects WHERE batch_id = $1 AND subject_id = $2 AND teacher_id = $3`,
        [a.batch_id, a.subject_id, req.user.sub]
      );
      authorized = !!r.rows[0];
    } else {
      const r = await db.query(
        `SELECT 1 FROM enrollments e
         JOIN batches b ON b.id = e.batch_id AND b.is_active
         JOIN batch_subjects bs ON bs.batch_id = b.id
         WHERE e.student_id = $1 AND e.batch_id = $2 AND bs.subject_id = $3`,
        [req.user.sub, a.batch_id, a.subject_id]
      );
      authorized = !!r.rows[0];
    }
    if (!authorized) return res.status(403).json({ error: 'Not authorized' });

    let submission = null;
    if (req.user.role === 'student') {
      const s = await db.query(
        'SELECT * FROM submissions WHERE assignment_id = $1 AND student_id = $2',
        [a.id, req.user.sub]
      );
      submission = s.rows[0] || { status: 'pending', submitted_at: null };
    }

    res.json({ assignment: a, submission });
  } catch (err) {
    next(err);
  }
});

// POST /api/assignments/:id/submit — student submit file
router.post(
  '/:id/submit',
  authRequired,
  requireRole('student'),
  upload.single('file'),
  async (req, res, next) => {
    try {
      const assignment = await db.query('SELECT * FROM assignments WHERE id = $1', [req.params.id]);
      if (!assignment.rows[0]) return res.status(404).json({ error: 'Assignment not found' });
      const a = assignment.rows[0];

      // Verify enrollment
      const enrolled = await db.query(
        `SELECT 1 FROM enrollments e
         JOIN batches b ON b.id = e.batch_id AND b.is_active
         WHERE e.student_id = $1 AND e.batch_id = $2`,
        [req.user.sub, a.batch_id]
      );
      if (!enrolled.rows[0]) return res.status(403).json({ error: 'Not enrolled in this batch' });

      const file = req.file;
      if (!file) return res.status(400).json({ error: 'File required' });

      const now = new Date();
      const status = now > new Date(a.due_at) ? 'late' : 'submitted';

      await db.query(
        `INSERT INTO submissions (assignment_id, student_id, status, file_path, original_name, mime_type, size_bytes, submitted_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT (assignment_id, student_id) DO UPDATE SET
           status = EXCLUDED.status,
           file_path = EXCLUDED.file_path,
           original_name = EXCLUDED.original_name,
           mime_type = EXCLUDED.mime_type,
           size_bytes = EXCLUDED.size_bytes,
           submitted_at = EXCLUDED.submitted_at`,
        [a.id, req.user.sub, status, file.path, file.originalname, file.mimetype, file.size, now]
      );

      res.json({ status, submitted_at: now.toISOString() });
    } catch (err) {
      if (req.file) fs.unlink(req.file.path, () => {});
      next(err);
    }
  }
);

// GET /api/assignments/:id/submissions — teacher view all submissions
router.get(
  '/:id/submissions',
  authRequired,
  requireRole('teacher'),
  async (req, res, next) => {
    try {
      const assignment = await db.query('SELECT * FROM assignments WHERE id = $1', [req.params.id]);
      if (!assignment.rows[0]) return res.status(404).json({ error: 'Not found' });
      const a = assignment.rows[0];

      // Verify teacher teaches this
      const access = await db.query(
        `SELECT 1 FROM batch_subjects WHERE batch_id = $1 AND subject_id = $2 AND teacher_id = $3`,
        [a.batch_id, a.subject_id, req.user.sub]
      );
      if (!access.rows[0]) return res.status(403).json({ error: 'Not your class' });

      const subs = await db.query(
        `SELECT s.*, u.name as student_name, u.email as student_email
         FROM submissions s
         JOIN users u ON u.id = s.student_id
         WHERE s.assignment_id = $1
         ORDER BY s.status, s.submitted_at`,
        [a.id]
      );
      res.json({ submissions: subs.rows });
    } catch (err) {
      next(err);
    }
  }
);

// POST /api/assignments/:id/grade — teacher grade a submission
router.post(
  '/:id/grade',
  authRequired,
  requireRole('teacher'),
  async (req, res, next) => {
    try {
      const { student_id, score } = req.body;
      if (!student_id || score === undefined || score < 0) {
        return res.status(400).json({ error: 'student_id and score required' });
      }

      const assignment = await db.query('SELECT * FROM assignments WHERE id = $1', [req.params.id]);
      if (!assignment.rows[0]) return res.status(404).json({ error: 'Not found' });
      const a = assignment.rows[0];

      if (score > a.max_score) {
        return res.status(400).json({ error: `Score cannot exceed max (${a.max_score})` });
      }

      // Verify teacher teaches this
      const access = await db.query(
        `SELECT 1 FROM batch_subjects WHERE batch_id = $1 AND subject_id = $2 AND teacher_id = $3`,
        [a.batch_id, a.subject_id, req.user.sub]
      );
      if (!access.rows[0]) return res.status(403).json({ error: 'Not your class' });

      const result = await db.query(
        `UPDATE submissions SET score = $1, status = 'graded', graded_by = $2, graded_at = now()
         WHERE assignment_id = $3 AND student_id = $4
         RETURNING *`,
        [score, req.user.sub, a.id, student_id]
      );
      if (!result.rows[0]) return res.status(404).json({ error: 'Submission not found' });
      res.json({ submission: result.rows[0] });
    } catch (err) {
      next(err);
    }
  }
);

module.exports = router;