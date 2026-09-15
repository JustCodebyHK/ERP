const express = require('express');
const db = require('../db');
const { authRequired } = require('../middleware/auth');

const router = express.Router();

// GET /api/groups/:id/messages — get messages with pagination
router.get('/:id/messages', authRequired, async (req, res, next) => {
  try {
    const { limit = 50, before } = req.query;
    const limitNum = Math.min(parseInt(limit) || 50, 100);

    // Check membership
    const member = await db.query(
      'SELECT * FROM group_members WHERE group_id = $1 AND user_id = $2',
      [req.params.id, req.user.sub]
    );
    if (!member.rows[0]) return res.status(403).json({ error: 'Not a member' });

    let query = `
      SELECT gm.*, u.name as sender_name, u.role as sender_role
      FROM group_messages gm
      JOIN users u ON u.id = gm.sender_id
      WHERE gm.group_id = $1 AND gm.deleted_at IS NULL
    `;
    const params = [req.params.id];

    if (before) {
      query += ' AND gm.created_at < $2';
      params.push(before);
    }

    query += ' ORDER BY gm.created_at DESC LIMIT $' + (params.length + 1);
    params.push(limitNum);

    const result = await db.query(query, params);

    // Get read status for each message
    const messageIds = result.rows.map(m => m.id);
    let readsMap = {};
    if (messageIds.length > 0) {
      const reads = await db.query(
        `SELECT message_id, COUNT(*) as read_count
         FROM group_message_reads
         WHERE message_id = ANY($1)
         GROUP BY message_id`,
        [messageIds]
      );
      readsMap = reads.rows.reduce((acc, r) => {
        acc[r.message_id] = parseInt(r.read_count);
        return acc;
      }, {});
    }

    const messages = result.rows.map(m => ({
      ...m,
      read_count: readsMap[m.id] || 0,
      is_own: m.sender_id === req.user.sub
    }));

    res.json({ messages: messages.reverse() }); // oldest first for chat display
  } catch (err) {
    next(err);
  }
});

// POST /api/groups/:id/messages — send message
router.post('/:id/messages', authRequired, async (req, res, next) => {
  try {
    const { content, type = 'text', reply_to } = req.body;
    if (!content || !content.trim()) {
      return res.status(400).json({ error: 'Message content is required' });
    }
    if (!['text', 'image', 'file', 'alert', 'notification'].includes(type)) {
      return res.status(400).json({ error: 'Invalid message type' });
    }

    // Check membership
    const member = await db.query(
      'SELECT * FROM group_members WHERE group_id = $1 AND user_id = $2',
      [req.params.id, req.user.sub]
    );
    if (!member.rows[0]) return res.status(403).json({ error: 'Not a member' });

    // Check if muted
    if (member.rows[0].muted_until && new Date(member.rows[0].muted_until) > new Date()) {
      return res.status(403).json({ error: 'You are muted in this group' });
    }

    // Verify reply_to exists and belongs to same group
    if (reply_to) {
      const replyMsg = await db.query(
        'SELECT id FROM group_messages WHERE id = $1 AND group_id = $2',
        [reply_to, req.params.id]
      );
      if (!replyMsg.rows[0]) {
        return res.status(400).json({ error: 'Reply message not found in this group' });
      }
    }

    const result = await db.query(
      `INSERT INTO group_messages (group_id, sender_id, content, type, reply_to)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [req.params.id, req.user.sub, content.trim(), type, reply_to || null]
    );

    const message = result.rows[0];
    const sender = await db.query('SELECT name, role FROM users WHERE id = $1', [req.user.sub]);

    // Auto-mark as read by sender
    await db.query(
      `INSERT INTO group_message_reads (message_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
      [result.rows[0].id, req.user.sub]
    );

    res.status(201).json({
      message: {
        ...message,
        sender_name: sender.rows[0]?.name,
        sender_role: sender.rows[0]?.role,
        is_own: true,
        read_count: 1
      }
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/groups/:id/messages/:messageId/read — mark as read
router.post('/:id/messages/:messageId/read', authRequired, async (req, res, next) => {
  try {
    const member = await db.query(
      'SELECT 1 FROM group_members WHERE group_id = $1 AND user_id = $2',
      [req.params.id, req.user.sub]
    );
    if (!member.rows[0]) return res.status(403).json({ error: 'Not a member' });

    await db.query(
      `INSERT INTO group_message_reads (message_id, user_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
      [req.params.messageId, req.user.sub]
    );

    // Return read count
    const reads = await db.query(
      'SELECT COUNT(*) FROM group_message_reads WHERE message_id = $1',
      [req.params.messageId]
    );
    res.json({ read_count: parseInt(reads.rows[0].count) });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/groups/:id/messages/:messageId — delete own message
router.delete('/:id/messages/:messageId', authRequired, async (req, res, next) => {
  try {
    const msg = await db.query(
      'SELECT sender_id FROM group_messages WHERE id = $1 AND group_id = $2',
      [req.params.messageId, req.params.id]
    );
    if (!msg.rows[0]) return res.status(404).json({ error: 'Message not found' });
    if (msg.rows[0].sender_id !== req.user.sub) {
      return res.status(403).json({ error: 'Can only delete own messages' });
    }

    await db.query(
      `UPDATE group_messages SET deleted_at = now(), content = 'This message was deleted' WHERE id = $1`,
      [req.params.messageId]
    );
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

// PUT /api/groups/:id/messages/:messageId — edit own message
router.put('/:id/messages/:messageId', async (req, res, next) => {
  try {
    const { content } = req.body;
    if (!content || !content.trim()) {
      return res.status(400).json({ error: 'Content is required' });
    }

    const msg = await db.query(
      'SELECT sender_id FROM group_messages WHERE id = $1 AND group_id = $2',
      [req.params.messageId, req.params.id]
    );
    if (!msg.rows[0]) return res.status(404).json({ error: 'Message not found' });
    if (msg.rows[0].sender_id !== req.user.sub) {
      return res.status(403).json({ error: 'Can only edit own messages' });
    }

    const result = await db.query(
      `UPDATE group_messages SET content = $1, edited_at = now() WHERE id = $2 RETURNING *`,
      [content.trim(), req.params.messageId]
    );
    res.json({ message: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

module.exports = router;