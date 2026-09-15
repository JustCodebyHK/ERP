const express = require('express');
const { v4: uuidv4 } = require('uuid');
const db = require('../db');
const { authRequired, requireRole } = require('../middleware/auth');

const router = express.Router();

// Generate unique invite code
function generateInviteCode() {
  return uuidv4().replace(/-/g, '').slice(0, 8).toUpperCase();
}

// POST /api/groups — teacher create group
router.post(
  '/',
  authRequired,
  requireRole('teacher'),
  async (req, res, next) => {
    try {
      const { name, description, type = 'group', is_public = false } = req.body;
      if (!name || !name.trim()) {
        return res.status(400).json({ error: 'Group name is required' });
      }
      if (!['group', 'channel'].includes(type)) {
        return res.status(400).json({ error: 'Type must be group or channel' });
      }

      const inviteCode = generateInviteCode();
      const result = await db.query(
        `INSERT INTO groups (name, description, type, is_public, invite_code, created_by)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING *`,
        [name.trim(), description || null, type, is_public, inviteCode, req.user.sub]
      );
      const group = result.rows[0];

      // Auto-add creator as owner
      await db.query(
        `INSERT INTO group_members (group_id, user_id, role) VALUES ($1, $2, 'owner')`,
        [group.id, req.user.sub]
      );

      res.status(201).json({ group });
    } catch (err) {
      next(err);
    }
  }
);

// GET /api/groups — list groups (teacher: owned, student: joined)
router.get('/', authRequired, async (req, res, next) => {
  try {
    let query, params;
    if (req.user.role === 'teacher') {
      query = `
        SELECT g.*, 
          (SELECT COUNT(*) FROM group_members gm WHERE gm.group_id = g.id) as member_count
        FROM groups g
        WHERE g.created_by = $1
        ORDER BY g.created_at DESC
      `;
      params = [req.user.sub];
    } else {
      query = `
        SELECT g.*, gm.role, gm.muted_until,
          (SELECT COUNT(*) FROM group_members gm2 WHERE gm2.group_id = g.id) as member_count
        FROM groups g
        JOIN group_members gm ON gm.group_id = g.id
        WHERE gm.user_id = $1
        ORDER BY g.created_at DESC
      `;
      params = [req.user.sub];
    }
    const result = await db.query(query, params);
    res.json({ groups: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/groups/:id — group details
router.get('/:id', authRequired, async (req, res, next) => {
  try {
    const group = await db.query('SELECT * FROM groups WHERE id = $1', [req.params.id]);
    if (!group.rows[0]) return res.status(404).json({ error: 'Group not found' });

    // Check membership
    const member = await db.query(
      'SELECT * FROM group_members WHERE group_id = $1 AND user_id = $2',
      [req.params.id, req.user.sub]
    );
    if (!member.rows[0]) {
      return res.status(403).json({ error: 'Not a member of this group' });
    }

    res.json({ group: group.rows[0], membership: member.rows[0] });
  } catch (err) {
    next(err);
  }
});

// POST /api/groups/join — join group via invite code
router.post('/join', authRequired, async (req, res, next) => {
  try {
    const { invite_code } = req.body;
    if (!invite_code) {
      return res.status(400).json({ error: 'Invite code is required' });
    }

    const group = await db.query('SELECT * FROM groups WHERE invite_code = $1', [invite_code.toUpperCase()]);
    if (!group.rows[0]) {
      return res.status(404).json({ error: 'Invalid invite code' });
    }
    const groupData = group.rows[0];

    // Check if already member
    const existing = await db.query(
      'SELECT * FROM group_members WHERE group_id = $1 AND user_id = $2',
      [groupData.id, req.user.sub]
    );
    if (existing.rows[0]) {
      return res.status(409).json({ error: 'Already a member of this group' });
    }

    // Add as member
    await db.query(
      `INSERT INTO group_members (group_id, user_id, role) VALUES ($1, $2, 'member')`,
      [groupData.id, req.user.sub]
    );

    res.json({ success: true, group: { id: groupData.id, name: groupData.name } });
  } catch (err) {
    next(err);
  }
});

// POST /api/groups/:id/leave — leave group
router.post('/:id/leave', authRequired, async (req, res, next) => {
  try {
    const group = await db.query('SELECT * FROM groups WHERE id = $1', [req.params.id]);
    if (!group.rows[0]) return res.status(404).json({ error: 'Group not found' });

    // Check if owner
    if (group.rows[0].created_by === req.user.sub) {
      return res.status(400).json({ error: 'Owner cannot leave. Transfer ownership or delete group.' });
    }

    await db.query(
      'DELETE FROM group_members WHERE group_id = $1 AND user_id = $2',
      [req.params.id, req.user.sub]
    );
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/groups/:id — delete group (owner only)
router.delete('/:id', authRequired, requireRole('teacher'), async (req, res, next) => {
  try {
    const group = await db.query('SELECT * FROM groups WHERE id = $1', [req.params.id]);
    if (!group.rows[0]) return res.status(404).json({ error: 'Group not found' });
    if (group.rows[0].created_by !== req.user.sub) {
      return res.status(403).json({ error: 'Only owner can delete group' });
    }
    await db.query('DELETE FROM groups WHERE id = $1', [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

// GET /api/groups/:id/members — list members
router.get('/:id/members', authRequired, async (req, res, next) => {
  try {
    const member = await db.query(
      'SELECT * FROM group_members WHERE group_id = $1 AND user_id = $2',
      [req.params.id, req.user.sub]
    );
    if (!member.rows[0]) return res.status(403).json({ error: 'Not a member' });

    const members = await db.query(
      `SELECT gm.*, u.name, u.email, u.role as user_role
       FROM group_members gm
       JOIN users u ON u.id = gm.user_id
       WHERE gm.group_id = $1
       ORDER BY 
         CASE gm.role WHEN 'owner' THEN 0 WHEN 'admin' THEN 1 ELSE 2 END,
         gm.joined_at`,
      [req.params.id]
    );
    res.json({ members: members.rows });
  } catch (err) {
    next(err);
  }
});

// PUT /api/groups/:id/members/:userId — update member role (admin/owner)
router.put('/:id/members/:userId', authRequired, async (req, res, next) => {
  try {
    const { role } = req.body;
    if (!['admin', 'member'].includes(role)) {
      return res.status(400).json({ error: 'Invalid role' });
    }

    const group = await db.query('SELECT * FROM groups WHERE id = $1', [req.params.id]);
    if (!group.rows[0]) return res.status(404).json({ error: 'Group not found' });

    // Check if requester is owner or admin
    const requesterMember = await db.query(
      'SELECT role FROM group_members WHERE group_id = $1 AND user_id = $2',
      [req.params.id, req.user.sub]
    );
    if (!requesterMember.rows[0] || !['owner', 'admin'].includes(requesterMember.rows[0].role)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    // Cannot change owner
    const targetMember = await db.query(
      'SELECT role FROM group_members WHERE group_id = $1 AND user_id = $2',
      [req.params.id, req.params.userId]
    );
    if (!targetMember.rows[0]) return res.status(404).json({ error: 'Member not found' });
    if (targetMember.rows[0].role === 'owner') {
      return res.status(400).json({ error: 'Cannot change owner role' });
    }

    // Owner can only be changed by owner
    if (role === 'admin' && requesterMember.rows[0].role !== 'owner') {
      return res.status(403).json({ error: 'Only owner can promote to admin' });
    }

    await db.query(
      'UPDATE group_members SET role = $1 WHERE group_id = $2 AND user_id = $3',
      [role, req.params.id, req.params.userId]
    );
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/groups/:id/members/:userId — remove member (admin/owner)
router.delete('/:id/members/:userId', authRequired, async (req, res, next) => {
  try {
    const group = await db.query('SELECT * FROM groups WHERE id = $1', [req.params.id]);
    if (!group.rows[0]) return res.status(404).json({ error: 'Group not found' });

    const requesterMember = await db.query(
      'SELECT role FROM group_members WHERE group_id = $1 AND user_id = $2',
      [req.params.id, req.user.sub]
    );
    if (!requesterMember.rows[0] || !['owner', 'admin'].includes(requesterMember.rows[0].role)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }

    const targetMember = await db.query(
      'SELECT role FROM group_members WHERE group_id = $1 AND user_id = $2',
      [req.params.id, req.params.userId]
    );
    if (!targetMember.rows[0]) return res.status(404).json({ error: 'Member not found' });

    // Cannot remove owner
    if (targetMember.rows[0].role === 'owner') {
      return res.status(400).json({ error: 'Cannot remove owner' });
    }

    // Admin can only remove members, not other admins
    if (targetMember.rows[0].role === 'admin' && requesterMember.rows[0].role !== 'owner') {
      return res.status(403).json({ error: 'Only owner can remove admins' });
    }

    await db.query(
      'DELETE FROM group_members WHERE group_id = $1 AND user_id = $2',
      [req.params.id, req.params.userId]
    );
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

module.exports = router;