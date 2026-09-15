const express = require('express');
const db = require('../db');
const { authRequired, requireRole } = require('../middleware/auth');

const router = express.Router();

// POST /api/announcements — teacher create (global or batch-specific)
router.post(
  '/',
  authRequired,
  requireRole('teacher'),
  async (req, res, next) => {
    try {
      const { batch_id, type, title, body } = req.body;
      if (!type || !title || !body) {
        return res.status(400).json({ error: 'type, title, body required' });
      }
      if (!['holiday', 'exam', 'deadline', 'general', 'alert'].includes(type)) {
        return res.status(400).json({ error: 'Invalid type' });
      }

      // If batch_id provided, verify teacher teaches in that batch
      if (batch_id) {
        const access = await db.query(
          `SELECT 1 FROM batch_subjects WHERE batch_id = $1 AND teacher_id = $2`,
          [batch_id, req.user.sub]
        );
        if (!access.rows[0]) {
          return res.status(403).json({ error: 'Not assigned to this batch' });
        }
      }

      const result = await db.query(
        `INSERT INTO announcements (batch_id, type, title, body, published_by)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [batch_id || null, type, title, body, req.user.sub]
      );
      res.status(201).json({ announcement: result.rows[0] });
    } catch (err) {
      next(err);
    }
  }
);

// GET /api/announcements — teacher list (all they published, or filter by batch)
router.get(
  '/',
  authRequired,
  async (req, res, next) => {
    try {
      const { batch_id } = req.query;
      let query, params;

      if (req.user.role === 'teacher') {
        if (batch_id) {
          query = `SELECT a.*, b.name as batch_name
                   FROM announcements a
                   LEFT JOIN batches b ON b.id = a.batch_id
                   WHERE a.published_by = $1 AND a.batch_id = $2
                   ORDER BY a.published_at DESC`;
          params = [req.user.sub, batch_id];
        } else {
          query = `SELECT a.*, b.name as batch_name
                   FROM announcements a
                   LEFT JOIN batches b ON b.id = a.batch_id
                   WHERE a.published_by = $1
                   ORDER BY a.published_at DESC`;
          params = [req.user.sub];
        }
      } else {
        // Student: global + their enrolled batches
        query = `SELECT a.*, b.name as batch_name
                 FROM announcements a
                 LEFT JOIN batches b ON b.id = a.batch_id
                 WHERE a.is_active
                   AND (a.batch_id IS NULL
                        OR a.batch_id IN (
                          SELECT e.batch_id FROM enrollments e
                          JOIN batches b2 ON b2.id = e.batch_id AND b2.is_active
                          WHERE e.student_id = $1
                        ))
                 ORDER BY a.published_at DESC`;
        params = [req.user.sub];
      }

      const result = await db.query(query, params);
      res.json({ announcements: result.rows });
    } catch (err) {
      next(err);
    }
  }
);

// GET /api/announcements/unread-count — student unread count
router.get('/unread-count', authRequired, requireRole('student'), async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT COUNT(*) FROM announcements a
       WHERE a.is_active
         AND (a.batch_id IS NULL
              OR a.batch_id IN (
                SELECT e.batch_id FROM enrollments e
                JOIN batches b ON b.id = e.batch_id AND b.is_active
                WHERE e.student_id = $1
              ))
         AND NOT EXISTS (
           SELECT 1 FROM announcement_reads ar
           WHERE ar.announcement_id = a.id AND ar.student_id = $1
         )`,
      [req.user.sub]
    );
    res.json({ count: parseInt(result.rows[0].count, 10) });
  } catch (err) {
    next(err);
  }
});

// POST /api/announcements/:id/read — student mark as read
router.post('/:id/read', authRequired, requireRole('student'), async (req, res, next) => {
  try {
    await db.query(
      `INSERT INTO announcement_reads (announcement_id, student_id)
       VALUES ($1, $2) ON CONFLICT DO NOTHING`,
      [req.params.id, req.user.sub]
    );
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/announcements/:id — teacher delete own
router.delete(
  '/:id',
  authRequired,
  requireRole('teacher'),
  async (req, res, next) => {
    try {
      const result = await db.query(
        'SELECT published_by FROM announcements WHERE id = $1',
        [req.params.id]
      );
      if (!result.rows[0]) return res.status(404).json({ error: 'Not found' });
      if (result.rows[0].published_by !== req.user.sub) {
        return res.status(403).json({ error: 'Not your announcement' });
      }
      await db.query('DELETE FROM announcements WHERE id = $1', [req.params.id]);
      res.json({ success: true });
    } catch (err) {
      next(err);
    }
  }
);

// Read tracking table (created lazily on first mark-read)
router.post('/ensure-reads-table', authRequired, requireRole('teacher'), async (req, res, next) => {
  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS announcement_reads (
        announcement_id UUID NOT NULL REFERENCES announcements (id) ON DELETE CASCADE,
        student_id UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
        read_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        PRIMARY KEY (announcement_id, student_id)
      )
    `);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

module.exports = router;