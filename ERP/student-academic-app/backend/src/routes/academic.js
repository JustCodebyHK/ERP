const express = require('express');
const db = require('../db');
const { authRequired, requireRole } = require('../middleware/auth');

const router = express.Router();

// Student: subjects of their active batch (with teacher names).
router.get('/my-subjects', authRequired, requireRole('student'), async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT s.id, s.code, s.name, u.name AS teacher_name
       FROM enrollments e
       JOIN batches b ON b.id = e.batch_id AND b.is_active
       JOIN batch_subjects bs ON bs.batch_id = b.id
       JOIN subjects s ON s.id = bs.subject_id
       JOIN users u ON u.id = bs.teacher_id
       WHERE e.student_id = $1
       ORDER BY s.code`,
      [req.user.sub]
    );
    res.json({ subjects: result.rows });
  } catch (err) {
    next(err);
  }
});

// Teacher: classes they teach (batch + subject pairs).
router.get('/my-classes', authRequired, requireRole('teacher'), async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT b.id AS batch_id, b.name AS batch_name,
              s.id AS subject_id, s.code AS subject_code, s.name AS subject_name
       FROM batch_subjects bs
       JOIN batches b ON b.id = bs.batch_id AND b.is_active
       JOIN subjects s ON s.id = bs.subject_id
       WHERE bs.teacher_id = $1
       ORDER BY b.name, s.code`,
      [req.user.sub]
    );
    res.json({ classes: result.rows });
  } catch (err) {
    next(err);
  }
});

// POST /api/academic/batches — teacher create new batch with subjects
router.post(
  '/batches',
  authRequired,
  requireRole('teacher'),
  async (req, res, next) => {
    try {
      const { name, subject_ids, subjects } = req.body;
      if (!name || !name.trim()) {
        return res.status(400).json({ error: 'Batch name is required' });
      }
      if ((!subject_ids || !Array.isArray(subject_ids) || subject_ids.length === 0) &&
          (!subjects || !Array.isArray(subjects) || subjects.length === 0)) {
        return res.status(400).json({ error: 'At least one subject is required' });
      }

      // Create batch
      const batchResult = await db.query(
        `INSERT INTO batches (name, is_active) VALUES ($1, true) RETURNING id, name`,
        [name.trim()]
      );
      const batch = batchResult.rows[0];

      // Link existing subjects to batch with this teacher
      if (subject_ids && Array.isArray(subject_ids) && subject_ids.length > 0) {
        for (const subjectId of subject_ids) {
          await db.query(
            `INSERT INTO batch_subjects (batch_id, subject_id, teacher_id)
             VALUES ($1, $2, $3)
             ON CONFLICT (batch_id, subject_id) DO UPDATE SET teacher_id = EXCLUDED.teacher_id`,
            [batch.id, subjectId, req.user.sub]
          );
        }
      }

      // Create new subjects on the fly and link to batch
      if (subjects && Array.isArray(subjects) && subjects.length > 0) {
        for (const subj of subjects) {
          if (!subj.code || !subj.name) {
            return res.status(400).json({ error: 'Each new subject must have code and name' });
          }
          
          // Create or find subject
          const subjResult = await db.query(
            `INSERT INTO subjects (code, name) VALUES ($1, $2)
             ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name
             RETURNING id`,
            [subj.code.trim().toUpperCase(), subj.name.trim()]
          );
          const subjectId = subjResult.rows[0].id;

          // Link to batch
          await db.query(
            `INSERT INTO batch_subjects (batch_id, subject_id, teacher_id)
             VALUES ($1, $2, $3)
             ON CONFLICT (batch_id, subject_id) DO UPDATE SET teacher_id = EXCLUDED.teacher_id`,
            [batch.id, subjectId, req.user.sub]
          );
        }
      }

      res.status(201).json({ batch });
    } catch (err) {
      next(err);
    }
  }
);

// DELETE /api/academic/batches/:id — teacher delete batch
router.delete(
  '/batches/:id',
  authRequired,
  requireRole('teacher'),
  async (req, res, next) => {
    try {
      const { id } = req.params;
      
      // Verify teacher owns this batch
      const batchResult = await db.query(
        `SELECT b.id FROM batches b
         JOIN batch_subjects bs ON bs.batch_id = b.id
         WHERE b.id = $1 AND bs.teacher_id = $2`,
        [id, req.user.sub]
      );
      
      if (batchResult.rows.length === 0) {
        return res.status(404).json({ error: 'Batch not found or not authorized' });
      }
      
      // Delete batch (cascades to batch_subjects, enrollments, etc.)
      await db.query(`DELETE FROM batches WHERE id = $1`, [id]);
      
      res.json({ success: true });
    } catch (err) {
      next(err);
    }
  }
);

module.exports = router;
