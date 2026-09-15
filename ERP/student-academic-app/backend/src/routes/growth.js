const express = require('express');
const db = require('../db');
const { authRequired, requireRole } = require('../middleware/auth');

const router = express.Router();

// Weights for growth index (configurable, sum to 1.0)
const WEIGHTS = {
  attendance: 0.35,
  marks: 0.45,
  assignments: 0.20,
};

// Helper: compute attendance percentage for a student in their active batch
async function getAttendanceScore(studentId) {
  const batch = await db.query(
    `SELECT b.id FROM batches b
     JOIN enrollments e ON e.batch_id = b.id AND b.is_active
     WHERE e.student_id = $1 LIMIT 1`,
    [studentId]
  );
  if (!batch.rows[0]) return { score: null, details: [] };

  const batchId = batch.rows[0].id;

  const result = await db.query(
    `SELECT s.code, s.name,
            COUNT(a.id) as total_lectures,
            COUNT(CASE WHEN a.present THEN 1 END) as attended,
            ROUND(COUNT(CASE WHEN a.present THEN 1 END) * 100.0 / NULLIF(COUNT(a.id), 0), 1) as percentage
     FROM subjects s
     JOIN batch_subjects bs ON bs.subject_id = s.id AND bs.batch_id = $1
     LEFT JOIN attendance a ON a.subject_id = s.id AND a.student_id = $2 AND a.batch_id = $1
     GROUP BY s.id, s.code, s.name
     ORDER BY percentage ASC`,
    [batchId, studentId]
  );

  if (result.rows.length === 0) return { score: null, details: [] };

  const overallPercentage = result.rows.reduce((sum, r) => sum + parseFloat(r.percentage), 0) / result.rows.length;
  return {
    score: Math.round(overallPercentage),
    details: result.rows.map(r => ({
      subject: r.code,
      name: r.name,
      attended: parseInt(r.attended),
      total: parseInt(r.total_lectures),
      percentage: parseFloat(r.percentage),
    })),
  };
}

// Helper: compute marks average for a student in their active batch
async function getMarksScore(studentId) {
  const batch = await db.query(
    `SELECT b.id FROM batches b
     JOIN enrollments e ON e.batch_id = b.id AND b.is_active
     WHERE e.student_id = $1 LIMIT 1`,
    [studentId]
  );
  if (!batch.rows[0]) return { score: null, details: [] };

  const batchId = batch.rows[0].id;

  const result = await db.query(
    `SELECT s.code, s.name, m.type, m.title, m.score, m.max_score,
            ROUND(m.score * 100.0 / m.max_score, 1) as percentage
     FROM marks m
     JOIN subjects s ON s.id = m.subject_id
     WHERE m.student_id = $1 AND m.batch_id = $2
     ORDER BY m.created_at DESC`,
    [studentId, batchId]
  );

  if (result.rows.length === 0) return { score: null, details: [] };

  const overallPercentage = result.rows.reduce((sum, r) => sum + parseFloat(r.percentage), 0) / result.rows.length;
  return {
    score: Math.round(overallPercentage),
    details: result.rows.map(r => ({
      subject: r.code,
      name: r.name,
      type: r.type,
      title: r.title,
      score: r.score,
      maxScore: r.max_score,
      percentage: parseFloat(r.percentage),
    })),
  };
}

// Helper: compute assignment discipline score (on-time submission rate)
async function getAssignmentScore(studentId) {
  const batch = await db.query(
    `SELECT b.id FROM batches b
     JOIN enrollments e ON e.batch_id = b.id AND b.is_active
     WHERE e.student_id = $1 LIMIT 1`,
    [studentId]
  );
  if (!batch.rows[0]) return { score: null, details: [] };

  const batchId = batch.rows[0].id;

  const result = await db.query(
    `SELECT a.id, a.title, a.due_at, a.max_score,
            sub.status, sub.submitted_at, sub.score
     FROM assignments a
     LEFT JOIN submissions sub ON sub.assignment_id = a.id AND sub.student_id = $1
     WHERE a.batch_id = $2
     ORDER BY a.due_at DESC`,
    [studentId, batchId]
  );

  if (result.rows.length === 0) return { score: null, details: [] };

  const now = new Date();
  let onTime = 0;
  let total = 0;

  result.rows.forEach(a => {
    total++;
    if (a.submitted_at) {
      if (new Date(a.submitted_at) <= new Date(a.due_at)) onTime++;
    }
  });

  const disciplineScore = total > 0 ? Math.round((onTime / total) * 100) : null;

  return {
    score: disciplineScore,
    details: {
      totalAssignments: total,
      submittedOnTime: onTime,
      submittedLate: total - onTime,
    },
  };
}

// GET /api/growth/me — student's own growth index
router.get('/me', authRequired, requireRole('student'), async (req, res, next) => {
  try {
    const [attendance, marks, assignments] = await Promise.all([
      getAttendanceScore(req.user.sub),
      getMarksScore(req.user.sub),
      getAssignmentScore(req.user.sub),
    ]);

    const scores = {
      attendance: attendance.score,
      marks: marks.score,
      assignments: assignments.score,
    };

    // Calculate weighted growth index
    let growthIndex = null;
    const validScores = Object.entries(scores).filter(([_, v]) => v !== null);
    if (validScores.length > 0) {
      const totalWeight = validScores.reduce((sum, [k]) => sum + WEIGHTS[k], 0);
      const weightedSum = validScores.reduce((sum, [k, v]) => sum + v * WEIGHTS[k], 0);
      growthIndex = totalWeight > 0 ? Math.round(weightedSum / totalWeight) : null;
    }

    res.json({
      growthIndex,
      weights: WEIGHTS,
      components: {
        attendance: { score: attendance.score, weight: WEIGHTS.attendance, details: attendance.details },
        marks: { score: marks.score, weight: WEIGHTS.marks, details: marks.details },
        assignments: { score: assignments.score, weight: WEIGHTS.assignments, details: assignments.details },
      },
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/growth/student/:studentId — parent/teacher view of student's growth index
router.get('/student/:studentId', authRequired, async (req, res, next) => {
  try {
    const { studentId } = req.params;

    // Verify authorization
    let authorized = false;
    if (req.user.role === 'parent') {
      const link = await db.query(
        'SELECT 1 FROM parent_student_links WHERE parent_id = $1 AND student_id = $2',
        [req.user.sub, studentId]
      );
      authorized = !!link.rows[0];
    } else if (req.user.role === 'teacher') {
      // Teacher can see if they teach this student in any active batch
      const link = await db.query(
        `SELECT 1 FROM batch_subjects bs
         JOIN enrollments e ON e.batch_id = bs.batch_id
         WHERE bs.teacher_id = $1 AND e.student_id = $2 AND e.batch_id IN (
           SELECT id FROM batches WHERE is_active = true
         )`,
        [req.user.sub, studentId]
      );
      authorized = !!link.rows[0];
    } else if (req.user.role === 'student' && req.user.sub === studentId) {
      authorized = true;
    }

    if (!authorized) {
      return res.status(403).json({ error: 'Not authorized to view this growth index' });
    }

    const [attendance, marks, assignments] = await Promise.all([
      getAttendanceScore(studentId),
      getMarksScore(studentId),
      getAssignmentScore(studentId),
    ]);

    const scores = {
      attendance: attendance.score,
      marks: marks.score,
      assignments: assignments.score,
    };

    let growthIndex = null;
    const validScores = Object.entries(scores).filter(([_, v]) => v !== null);
    if (validScores.length > 0) {
      const totalWeight = validScores.reduce((sum, [k]) => sum + WEIGHTS[k], 0);
      const weightedSum = validScores.reduce((sum, [k, v]) => sum + v * WEIGHTS[k], 0);
      growthIndex = totalWeight > 0 ? Math.round(weightedSum / totalWeight) : null;
    }

    res.json({
      growthIndex,
      weights: WEIGHTS,
      components: {
        attendance: { score: attendance.score, weight: WEIGHTS.attendance, details: attendance.details },
        marks: { score: marks.score, weight: WEIGHTS.marks, details: marks.details },
        assignments: { score: assignments.score, weight: WEIGHTS.assignments, details: assignments.details },
      },
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;