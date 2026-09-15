const express = require('express');
const db = require('../db');
const { authRequired, requireRole } = require('../middleware/auth');

const router = express.Router();

const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

// POST /api/timetable — teacher create entry for their class
router.post(
  '/',
  authRequired,
  requireRole('teacher'),
  async (req, res, next) => {
    try {
      const { batch_id, subject_id, day_of_week, start_time, end_time, room } = req.body;
      if (batch_id === undefined || subject_id === undefined || day_of_week === undefined ||
          !start_time || !end_time) {
        return res.status(400).json({ error: 'batch_id, subject_id, day_of_week, start_time, end_time required' });
      }

      // Teacher must teach this subject in this batch
      const access = await db.query(
        `SELECT 1 FROM batch_subjects WHERE batch_id = $1 AND subject_id = $2 AND teacher_id = $3`,
        [batch_id, subject_id, req.user.sub]
      );
      if (!access.rows[0]) {
        return res.status(403).json({ error: 'Not assigned to this batch+subject' });
      }

      const result = await db.query(
        `INSERT INTO timetable_entries (batch_id, subject_id, day_of_week, start_time, end_time, room, teacher_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING *`,
        [batch_id, subject_id, day_of_week, start_time, end_time, room || null, req.user.sub]
      );
      res.status(201).json({ entry: result.rows[0] });
    } catch (err) {
      if (err.code === '23505') {
        return res.status(409).json({ error: 'Time slot already occupied for this batch' });
      }
      next(err);
    }
  }
);

// GET /api/timetable?batch_id=&subject_id= — list entries for a class (teacher or student)
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
      } else {
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
        `SELECT te.*, s.code as subject_code, s.name as subject_name
         FROM timetable_entries te
         JOIN subjects s ON s.id = te.subject_id
         WHERE te.batch_id = $1 AND te.subject_id = $2
         ORDER BY te.day_of_week, te.start_time`,
        [batch_id, subject_id]
      );
      res.json({ entries: result.rows });
    } catch (err) {
      next(err);
    }
  }
);

// GET /api/timetable/my — student: full weekly timetable across their batches
router.get('/my', authRequired, requireRole('student'), async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT te.*, b.name as batch_name, s.code as subject_code, s.name as subject_name
       FROM timetable_entries te
       JOIN batches b ON b.id = te.batch_id AND b.is_active
       JOIN subjects s ON s.id = te.subject_id
       JOIN enrollments e ON e.batch_id = b.id AND e.student_id = $1
       ORDER BY te.day_of_week, te.start_time`,
      [req.user.sub]
    );

    // Group by day
    const byDay = {};
    for (let i = 0; i < 7; i++) byDay[i] = [];
    for (const e of result.rows) {
      byDay[e.day_of_week].push(e);
    }
    // Sort each day by start_time
    for (const day of Object.values(byDay)) {
      day.sort((a, b) => a.start_time.localeCompare(b.start_time));
    }

    res.json({ timetable: byDay, days: DAYS });
  } catch (err) {
    next(err);
  }
});

// GET /api/timetable/today — student: today's lectures
router.get('/today', authRequired, requireRole('student'), async (req, res, next) => {
  try {
    const today = new Date().getDay(); // 0=Sun
    const result = await db.query(
      `SELECT te.*, b.name as batch_name, s.code as subject_code, s.name as subject_name
       FROM timetable_entries te
       JOIN batches b ON b.id = te.batch_id AND b.is_active
       JOIN subjects s ON s.id = te.subject_id
       JOIN enrollments e ON e.batch_id = b.id AND e.student_id = $1
       WHERE te.day_of_week = $2
       ORDER BY te.start_time`,
      [req.user.sub, today]
    );
    res.json({ entries: result.rows, day: DAYS[today] });
  } catch (err) {
    next(err);
  }
});

// PUT /api/timetable/:id — teacher update entry
router.put(
  '/:id',
  authRequired,
  requireRole('teacher'),
  async (req, res, next) => {
    try {
      const { day_of_week, start_time, end_time, room } = req.body;
      const existing = await db.query(
        `SELECT te.*, bs.teacher_id FROM timetable_entries te
         JOIN batch_subjects bs ON bs.batch_id = te.batch_id AND bs.subject_id = te.subject_id
         WHERE te.id = $1`,
        [req.params.id]
      );
      if (!existing.rows[0]) return res.status(404).json({ error: 'Not found' });
      if (existing.rows[0].teacher_id !== req.user.sub) {
        return res.status(403).json({ error: 'Not your class' });
      }

      const result = await db.query(
        `UPDATE timetable_entries
         SET day_of_week = COALESCE($1, day_of_week),
             start_time = COALESCE($2, start_time),
             end_time = COALESCE($3, end_time),
             room = COALESCE($4, room)
         WHERE id = $5
         RETURNING *`,
        [day_of_week ?? null, start_time ?? null, end_time ?? null, room ?? null, req.params.id]
      );
      res.json({ entry: result.rows[0] });
    } catch (err) {
      if (err.code === '23505') {
        return res.status(409).json({ error: 'Time slot already occupied' });
      }
      next(err);
    }
  }
);

// DELETE /api/timetable/:id — teacher delete entry
router.delete(
  '/:id',
  authRequired,
  requireRole('teacher'),
  async (req, res, next) => {
    try {
      const existing = await db.query(
        `SELECT te.*, bs.teacher_id FROM timetable_entries te
         JOIN batch_subjects bs ON bs.batch_id = te.batch_id AND bs.subject_id = te.subject_id
         WHERE te.id = $1`,
        [req.params.id]
      );
      if (!existing.rows[0]) return res.status(404).json({ error: 'Not found' });
      if (existing.rows[0].teacher_id !== req.user.sub) {
        return res.status(403).json({ error: 'Not your class' });
      }

      await db.query('DELETE FROM timetable_entries WHERE id = $1', [req.params.id]);
      res.json({ success: true });
    } catch (err) {
      next(err);
    }
  }
);

module.exports = router;