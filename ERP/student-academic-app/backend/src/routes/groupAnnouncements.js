const express = require('express');
const db = require('../db');
const { authRequired, requireRole } = require('../middleware/auth');

const router = express.Router();

// GET /api/groups/:id/announcements — list announcements for group
router.get('/:id/announcements', authRequired, async (req, res, next) => {
  try {
    const member = await db.query(
      'SELECT 1 FROM group_members WHERE group_id = $1 AND user_id = $2',
      [req.params.id, req.user.sub]
    );
    if (!member.rows[0]) return res.status(403).json({ error: 'Not a member' });

    const result = await db.query(
      `SELECT ga.*, u.name as author_name
       FROM group_announcements ga
       JOIN users u ON u.id = ga.created_by
       WHERE ga.group_id = $1
       ORDER BY ga.pinned DESC, ga.created_at DESC`,
      [req.params.id]
    );
    res.json({ announcements: result.rows });
  } catch (err) {
    next(err);
  }
});

// POST /api/groups/:id/announcements — create announcement (teacher/admin)
router.post(
  '/:id/announcements',
  authRequired,
  async (req, res, next) => {
    try {
      const { title, body, type = 'info', pinned = false, expires_at } = req.body;
      if (!title || !title.trim() || !body || !body.trim()) {
        return res.status(400).json({ error: 'Title and body are required' });
      }
      if (!['info', 'warning', 'urgent', 'assignment', 'exam', 'holiday'].includes(type)) {
        return res.status(400).json({ error: 'Invalid announcement type' });
      }

      // Check if user is teacher/admin in group
      const member = await db.query(
        'SELECT role FROM group_members WHERE group_id = $1 AND user_id = $2',
        [req.params.id, req.user.sub]
      );
      if (!member.rows[0] || !['owner', 'admin'].includes(member.rows[0].role)) {
        return res.status(403).json({ error: 'Only admins can create announcements' });
      }

      const result = await db.query(
        `INSERT INTO group_announcements (group_id, title, body, type, pinned, expires_at, created_by)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING *`,
        [req.params.id, title.trim(), body.trim(), type, pinned, expires_at || null, req.user.sub]
      );
      res.status(201).json({ announcement: result.rows[0] });
    } catch (err) {
      next(err);
    }
  }
);

// PUT /api/groups/:id/announcements/:announcementId — update announcement
router.put('/:id/announcements/:announcementId', authRequired, async (req, res, next) => {
  try {
    const { title, body, type, pinned, expires_at } = req.body;

    const announcement = await db.query(
      'SELECT * FROM group_announcements WHERE id = $1 AND group_id = $2',
      [req.params.announcementId, req.params.id]
    );
    if (!announcement.rows[0]) return res.status(404).json({ error: 'Announcement not found' });

    // Check permission
    const member = await db.query(
      'SELECT role FROM group_members WHERE group_id = $1 AND user_id = $2',
      [req.params.id, req.user.sub]
    );
    if (!member.rows[0] || !['owner', 'admin'].includes(member.rows[0].role)) {
      return res.status(403).json({ error: 'Only admins can update announcements' });
    }

    const result = await db.query(
      `UPDATE group_announcements SET
         title = COALESCE($1, title),
         body = COALESCE($2, body),
         type = COALESCE($3, type),
         pinned = COALESCE($4, pinned),
         expires_at = $5
       WHERE id = $1
       RETURNING *`,
      [
        req.body.title || announcement.rows[0].title,
        req.body.body || announcement.rows[0].body,
        req.body.type || announcement.rows[0].type,
        req.body.pinned ?? announcement.rows[0].pinned,
        req.body.expires_at ?? announcement.rows[0].expires_at,
        req.params.announcementId
      ]
    );
    res.json({ announcement: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/groups/:id/announcements/:announcementId
router.delete('/:id/announcements/:announcementId', authRequired, async (req, res, next) => {
  try {
    const announcement = await db.query(
      'SELECT * FROM group_announcements WHERE id = $1 AND group_id = $2',
      [req.params.announcementId, req.params.id]
    );
    if (!announcement.rows[0]) return res.status(404).json({ error: 'Not found' });

    const member = await db.query(
      'SELECT role FROM group_members WHERE group_id = $1 AND user_id = $2',
      [req.params.id, req.user.sub]
    );
    if (!member.rows[0] || !['owner', 'admin'].includes(member.rows[0].role)) {
      return res.status(403).json({ error: 'Only admins can delete announcements' });
    }

    await db.query('DELETE FROM group_announcements WHERE id = $1', [req.params.announcementId]);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

module.exports = router;