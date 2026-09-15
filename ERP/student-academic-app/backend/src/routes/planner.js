const express = require('express');
const db = require('../db');
const { authRequired, requireRole } = require('../middleware/auth');

const router = express.Router();

// Helper: get student's active batch
async function getStudentBatch(studentId) {
  const result = await db.query(
    `SELECT b.id FROM batches b
     JOIN enrollments e ON e.batch_id = b.id AND b.is_active
     WHERE e.student_id = $1 LIMIT 1`,
    [studentId]
  );
  return result.rows[0]?.id;
}

// GET /api/planner/tasks?date=YYYY-MM-DD — student's tasks for a specific date
router.get('/tasks', authRequired, requireRole('student'), async (req, res, next) => {
  try {
    const { date } = req.query; // YYYY-MM-DD
    const scheduledFor = date || new Date().toISOString().split('T')[0];

    const result = await db.query(
      `SELECT pt.*, te.start_time, te.end_time, s.code as subject_code, s.name as subject_name
       FROM planner_tasks pt
       LEFT JOIN timetable_entries te ON te.id = pt.timetable_entry_id
       LEFT JOIN subjects s ON s.id = pt.subject_id
       WHERE pt.student_id = $1 AND pt.scheduled_for = $2
       ORDER BY 
         CASE WHEN pt.timetable_entry_id IS NOT NULL THEN 0 ELSE 1 END,
         te.start_time,
         pt.priority DESC,
         pt.created_at`,
      [req.user.sub, scheduledFor]
    );
    res.json({ tasks: result.rows, date: scheduledFor });
  } catch (err) {
    next(err);
  }
});

// GET /api/planner/tasks/week?start=YYYY-MM-DD — student's tasks for a week
router.get('/tasks/week', authRequired, requireRole('student'), async (req, res, next) => {
  try {
    const start = req.query.start || new Date().toISOString().split('T')[0];
    const end = new Date(new Date(start).getTime() + 6 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

    const result = await db.query(
      `SELECT pt.*, te.start_time, te.end_time, s.code as subject_code, s.name as subject_name
       FROM planner_tasks pt
       LEFT JOIN timetable_entries te ON te.id = pt.timetable_entry_id
       LEFT JOIN subjects s ON s.id = pt.subject_id
       WHERE pt.student_id = $1 AND pt.scheduled_for BETWEEN $2 AND $3
       ORDER BY pt.scheduled_for,
         CASE WHEN pt.timetable_entry_id IS NOT NULL THEN 0 ELSE 1 END,
         te.start_time,
         pt.priority DESC`,
      [req.user.sub, start, end]
    );
    res.json({ tasks: result.rows, weekStart: start, weekEnd: end });
  } catch (err) {
    next(err);
  }
});

// POST /api/planner/tasks — create a new task
router.post('/tasks', authRequired, requireRole('student'), async (req, res, next) => {
  try {
    const { title, description, priority, due_at, scheduled_for, timetable_entry_id, subject_id } = req.body;
    if (!title || !scheduled_for) {
      return res.status(400).json({ error: 'title and scheduled_for required' });
    }

    // If timetable_entry_id provided, verify it belongs to student's batch
    if (timetable_entry_id) {
      const batchId = await getStudentBatch(req.user.sub);
      const check = await db.query(
        `SELECT 1 FROM timetable_entries te
         JOIN batch_subjects bs ON bs.batch_id = $1 AND bs.subject_id = te.subject_id
         WHERE te.id = $2`,
        [batchId, timetable_entry_id]
      );
      if (!check.rows[0]) {
        return res.status(403).json({ error: 'Invalid timetable entry for your batch' });
      }
    }

    const result = await db.query(
      `INSERT INTO planner_tasks (student_id, title, description, priority, due_at, scheduled_for, timetable_entry_id, subject_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [req.user.sub, title, description || null, priority || 1, due_at || null, scheduled_for, timetable_entry_id || null, subject_id || null]
    );
    res.status(201).json({ task: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// PUT /api/planner/tasks/:id — update task
router.put('/tasks/:id', authRequired, requireRole('student'), async (req, res, next) => {
  try {
    const { title, description, status, priority, due_at, scheduled_for, timetable_entry_id, subject_id } = req.body;

    const existing = await db.query(
      'SELECT * FROM planner_tasks WHERE id = $1 AND student_id = $2',
      [req.params.id, req.user.sub]
    );
    if (!existing.rows[0]) return res.status(404).json({ error: 'Task not found' });

    const completedAt = status === 'completed' && existing.rows[0].status !== 'completed'
      ? new Date()
      : (status === 'completed' ? existing.rows[0].completed_at : null);

    const result = await db.query(
      `UPDATE planner_tasks SET
         title = COALESCE($1, title),
         description = COALESCE($2, description),
         status = COALESCE($3, status),
         priority = COALESCE($4, priority),
         due_at = COALESCE($5, due_at),
         scheduled_for = COALESCE($6, scheduled_for),
         timetable_entry_id = COALESCE($7, timetable_entry_id),
         subject_id = COALESCE($8, subject_id),
         completed_at = $9,
         updated_at = now()
       WHERE id = $10 AND student_id = $11
       RETURNING *`,
      [title, description, status, priority, due_at, scheduled_for, timetable_entry_id, subject_id, completedAt, req.params.id, req.user.sub]
    );
    res.json({ task: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// POST /api/planner/tasks/:id/complete — mark task complete
router.post('/tasks/:id/complete', authRequired, requireRole('student'), async (req, res, next) => {
  try {
    const result = await db.query(
      `UPDATE planner_tasks SET status = 'completed', completed_at = now(), updated_at = now()
       WHERE id = $1 AND student_id = $2
       RETURNING *`,
      [req.params.id, req.user.sub]
    );
    if (!result.rows[0]) return res.status(404).json({ error: 'Task not found' });
    res.json({ task: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// POST /api/planner/tasks/:id/carry-forward — carry forward to next day
router.post('/tasks/:id/carry-forward', authRequired, requireRole('student'), async (req, res, next) => {
  try {
    const existing = await db.query(
      'SELECT * FROM planner_tasks WHERE id = $1 AND student_id = $2',
      [req.params.id, req.user.sub]
    );
    if (!existing.rows[0]) return res.status(404).json({ error: 'Task not found' });

    const task = existing.rows[0];
    const nextDay = new Date(new Date(task.scheduled_for).getTime() + 24 * 60 * 60 * 1000).toISOString().split('T')[0];

    const result = await db.query(
      `INSERT INTO planner_tasks (student_id, title, description, priority, due_at, scheduled_for, timetable_entry_id, subject_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [task.student_id, task.title, task.description, task.priority, task.due_at, nextDay, task.timetable_entry_id, task.subject_id]
    );

    // Mark original as deferred
    await db.query(
      `UPDATE planner_tasks SET status = 'deferred', updated_at = now() WHERE id = $1`,
      [req.params.id]
    );

    res.status(201).json({ task: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/planner/tasks/:id
router.delete('/tasks/:id', authRequired, requireRole('student'), async (req, res, next) => {
  try {
    const result = await db.query(
      'DELETE FROM planner_tasks WHERE id = $1 AND student_id = $2 RETURNING id',
      [req.params.id, req.user.sub]
    );
    if (!result.rows[0]) return res.status(404).json({ error: 'Task not found' });
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

// GET /api/planner/digest/today — daily digest for student
router.get('/digest/today', authRequired, requireRole('student'), async (req, res, next) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const batchId = await getStudentBatch(req.user.sub);

    // Tasks for today
    const tasks = await db.query(
      `SELECT pt.*, te.start_time, te.end_time, s.code as subject_code, s.name as subject_name
       FROM planner_tasks pt
       LEFT JOIN timetable_entries te ON te.id = pt.timetable_entry_id
       LEFT JOIN subjects s ON s.id = pt.subject_id
       WHERE pt.student_id = $1 AND pt.scheduled_for = $2
       ORDER BY CASE WHEN pt.timetable_entry_id IS NOT NULL THEN 0 ELSE 1 END, te.start_time`,
      [req.user.sub, today]
    );

    const todayDay = new Date().getDay();
    const classes = batchId ? await db.query(
      `SELECT te.*, s.code as subject_code, s.name as subject_name
       FROM timetable_entries te
       JOIN subjects s ON s.id = te.subject_id
       WHERE te.batch_id = $1 AND te.day_of_week = $2
       ORDER BY te.start_time`,
      [batchId, todayDay]
    ) : { rows: [] };

    let overdue = { rows: [] };
    let pending = { rows: [] };

    if (batchId) {
      const overdueResult = await db.query(
        `SELECT a.*, sub.status, s.code as subject_code, s.name as subject_name
         FROM assignments a
         JOIN subjects s ON s.id = a.subject_id
         LEFT JOIN submissions sub ON sub.assignment_id = a.id AND sub.student_id = $1
         WHERE a.batch_id = $2 AND a.due_at < now() AND (sub.status IS NULL OR sub.status = 'pending')
         ORDER BY a.due_at`,
        [req.user.sub, batchId]
      );
      overdue = overdueResult;

      const pendingResult = await db.query(
        `SELECT a.title, a.due_at, s.code as subject_code
         FROM assignments a
         JOIN subjects s ON s.id = a.subject_id
         LEFT JOIN submissions sub ON sub.assignment_id = a.id AND sub.student_id = $1
         WHERE a.batch_id = $2 AND a.due_at >= now() AND (sub.status IS NULL OR sub.status = 'pending')
         ORDER BY a.due_at
         LIMIT 5`,
        [req.user.sub, batchId]
      );
      pending = pendingResult;
    }

    res.json({
      date: today,
      tasks: tasks.rows,
      classes: classes.rows,
      overdueAssignments: overdue.rows,
      upcomingAssignments: pending.rows,
      stats: {
        totalTasks: tasks.rows.length,
        completedTasks: tasks.rows.filter(t => t.status === 'completed').length,
        pendingTasks: tasks.rows.filter(t => t.status === 'pending').length,
        overdueAssignments: overdue.rows.length,
      },
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/planner/digest/week — weekly digest
router.get('/digest/week', authRequired, requireRole('student'), async (req, res, next) => {
  try {
    const start = req.query.start || new Date().toISOString().split('T')[0];
    const end = new Date(new Date(start).getTime() + 6 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const batchId = await getStudentBatch(req.user.sub);

    // Tasks for the week
    const tasks = await db.query(
      `SELECT pt.*, te.start_time, te.end_time, s.code as subject_code, s.name as subject_name
       FROM planner_tasks pt
       LEFT JOIN timetable_entries te ON te.id = pt.timetable_entry_id
       LEFT JOIN subjects s ON s.id = pt.subject_id
       WHERE pt.student_id = $1 AND pt.scheduled_for BETWEEN $2 AND $3
       ORDER BY pt.scheduled_for, pt.priority DESC`,
      [req.user.sub, start, end]
    );

    // Classes for the week
    const classes = batchId ? await db.query(
      `SELECT te.*, s.code as subject_code, s.name as subject_name
       FROM timetable_entries te
       JOIN subjects s ON s.id = te.subject_id
       WHERE te.batch_id = $1
       ORDER BY te.day_of_week, te.start_time`,
      [batchId]
    ) : { rows: [] };

    // Assignments due this week
    const assignments = batchId ? await db.query(
      `SELECT a.*, sub.status, sub.submitted_at, sub.score, s.code as subject_code, s.name as subject_name
       FROM assignments a
       JOIN subjects s ON s.id = a.subject_id
       LEFT JOIN submissions sub ON sub.assignment_id = a.id AND sub.student_id = $1
       WHERE a.batch_id = $2 AND a.due_at BETWEEN $3 AND $4
       ORDER BY a.due_at`,
      [req.user.sub, batchId, start, end]
    ) : { rows: [] };

    // Aggregate stats
    const taskStats = tasks.rows.reduce((acc, t) => {
      acc.total++;
      if (t.status === 'completed') acc.completed++;
      else if (t.status === 'pending') acc.pending++;
      else if (t.status === 'deferred') acc.deferred++;
      return acc;
    }, { total: 0, completed: 0, pending: 0, deferred: 0 });

    const assignmentStats = assignments.rows.reduce((acc, a) => {
      acc.total++;
      if (a.submitted_at && new Date(a.submitted_at) <= new Date(a.due_at)) acc.onTime++;
      else if (a.submitted_at && new Date(a.submitted_at) > new Date(a.due_at)) acc.late++;
      else if (a.submitted_at && a.status === 'graded') acc.graded++;
      else acc.pending++;
      return acc;
    }, { total: 0, onTime: 0, late: 0, graded: 0, pending: 0 });

    res.json({
      weekStart: start,
      weekEnd: end,
      tasks: tasks.rows,
      classes: classes.rows,
      assignments: assignments.rows,
      stats: {
        tasks: taskStats,
        assignments: assignmentStats,
      },
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;