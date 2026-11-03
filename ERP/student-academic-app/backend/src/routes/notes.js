const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const db = require('../db');
const { authRequired, requireRole } = require('../middleware/auth');
const { validateUploadedFile } = require('../middleware/fileValidation');

const router = express.Router();

// Local file storage (dev). For prod/scalable: swap to S3/Supabase storage
// by changing this adapter — the route handlers stay identical.
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
  limits: { fileSize: 25 * 1024 * 1024 }, // 25 MB
});

// POST /api/notes — teacher upload
router.post(
  '/',
  authRequired,
  requireRole('teacher'),
  upload.single('file'),
  async (req, res, next) => {
    try {
      const file = req.file;
      if (!file) {
        return res.status(400).json({ error: 'File is required' });
      }
      // Validate magic bytes + extension (F-009)
      await new Promise((resolve, reject) => {
        validateUploadedFile(req, file, (err) => {
          if (err) return reject(err);
          resolve();
        });
      });

      const { subject_id, title } = req.body;
      if (!subject_id || !title) {
        fs.unlink(file.path, () => {});
        return res.status(400).json({ error: 'subject_id and title are required' });
      }

      // Teacher must be assigned to this subject in at least one active batch
      const access = await db.query(
        `SELECT 1 FROM batch_subjects bs
         JOIN batches b ON b.id = bs.batch_id AND b.is_active
         WHERE bs.subject_id = $1 AND bs.teacher_id = $2`,
        [subject_id, req.user.sub]
      );
      if (!access.rows[0]) {
        // Clean up uploaded file
        fs.unlink(file.path, () => {});
        return res.status(403).json({ error: 'You are not assigned to this subject' });
      }

      const result = await db.query(
        `INSERT INTO notes (subject_id, title, file_path, original_name, mime_type, size_bytes, uploaded_by)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         RETURNING id, subject_id, title, original_name, mime_type, size_bytes, created_at`,
        [subject_id, title, file.path, file.originalname, file.mimetype, file.size, req.user.sub]
      );
      res.status(201).json({ note: result.rows[0] });
    } catch (err) {
      // If DB insert fails or validation fails, remove the file
      if (req.file) fs.unlink(req.file.path, () => {});
      next(err);
    }
  }
);

// GET /api/notes?subject_id=... — list for subject (student or teacher)
router.get('/', authRequired, async (req, res, next) => {
  try {
    const { subject_id } = req.query;
    if (!subject_id) {
      return res.status(400).json({ error: 'subject_id query param required' });
    }

    // Students: must be enrolled in a batch that has this subject
    // Teachers: must be assigned to this subject in an active batch
    let authorized = false;
    if (req.user.role === 'student') {
      const r = await db.query(
        `SELECT 1 FROM enrollments e
         JOIN batches b ON b.id = e.batch_id AND b.is_active
         JOIN batch_subjects bs ON bs.batch_id = b.id
         WHERE e.student_id = $1 AND bs.subject_id = $2`,
        [req.user.sub, subject_id]
      );
      authorized = !!r.rows[0];
    } else if (req.user.role === 'teacher') {
      const r = await db.query(
        `SELECT 1 FROM batch_subjects bs
         JOIN batches b ON b.id = bs.batch_id AND b.is_active
         WHERE bs.subject_id = $1 AND bs.teacher_id = $2`,
        [subject_id, req.user.sub]
      );
      authorized = !!r.rows[0];
    }

    if (!authorized) {
      return res.status(403).json({ error: 'Not enrolled/assigned to this subject' });
    }

    const result = await db.query(
      `SELECT id, title, original_name, mime_type, size_bytes, created_at
       FROM notes WHERE subject_id = $1 ORDER BY created_at DESC`,
      [subject_id]
    );
    res.json({ notes: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/notes/:id/download — stream file
router.get('/:id/download', authRequired, async (req, res, next) => {
  try {
    const result = await db.query(
      'SELECT file_path, original_name, mime_type FROM notes WHERE id = $1',
      [req.params.id]
    );
    if (!result.rows[0]) {
      return res.status(404).json({ error: 'Note not found' });
    }
    const note = result.rows[0];

    // Re-check access (same logic as list)
    const subjectCheck = await db.query(
      'SELECT subject_id FROM notes WHERE id = $1',
      [req.params.id]
    );
    const subjectId = subjectCheck.rows[0]?.subject_id;
    if (!subjectId) return res.status(404).json({ error: 'Note not found' });

    let authorized = false;
    if (req.user.role === 'student') {
      const r = await db.query(
        `SELECT 1 FROM enrollments e
         JOIN batches b ON b.id = e.batch_id AND b.is_active
         JOIN batch_subjects bs ON bs.batch_id = b.id
         WHERE e.student_id = $1 AND bs.subject_id = $2`,
        [req.user.sub, subjectId]
      );
      authorized = !!r.rows[0];
    } else if (req.user.role === 'teacher') {
      const r = await db.query(
        `SELECT 1 FROM batch_subjects bs
         JOIN batches b ON b.id = bs.batch_id AND b.is_active
         WHERE bs.subject_id = $1 AND bs.teacher_id = $2`,
        [subjectId, req.user.sub]
      );
      authorized = !!r.rows[0];
    }
    if (!authorized) {
      return res.status(403).json({ error: 'Not enrolled/assigned to this subject' });
    }

    let targetPath = note.file_path;
    if (!fs.existsSync(targetPath)) {
      const fallback = path.join(UPLOAD_DIR, path.basename(note.file_path));
      if (fs.existsSync(fallback)) {
        targetPath = fallback;
      }
    }

    if (!fs.existsSync(targetPath)) {
      console.error('File not found:', note.file_path, 'fallback:', path.join(UPLOAD_DIR, path.basename(note.file_path)), 'UPLOAD_DIR:', UPLOAD_DIR);
      return res.status(404).json({ error: 'File missing on server. Re-upload the note.' });
    }
    res.setHeader('Content-Type', note.mime_type || 'application/octet-stream');
    res.setHeader('Content-Disposition', `attachment; filename="${note.original_name}"`);
    fs.createReadStream(targetPath).pipe(res);
  } catch (err) {
    next(err);
  }
});

module.exports = router;