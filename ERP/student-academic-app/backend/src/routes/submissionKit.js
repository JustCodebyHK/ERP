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

// POST /api/submission-kit — teacher upload new template version
router.post(
  '/',
  authRequired,
  requireRole('teacher'),
  upload.single('file'),
  async (req, res, next) => {
    try {
      const { type, title } = req.body;
      const file = req.file;
      if (!type || !title || !file) {
        return res.status(400).json({ error: 'type, title, and file required' });
      }
      if (!['front_page', 'index_page', 'certificate'].includes(type)) {
        return res.status(400).json({ error: 'Invalid type' });
      }

      // Get next version number
      const versionResult = await db.query(
        `SELECT COALESCE(MAX(version), 0) + 1 as next_version FROM submission_templates WHERE type = $1`,
        [type]
      );
      const nextVersion = versionResult.rows[0].next_version;

      // If there's a current one, unset it
      await db.query(
        `UPDATE submission_templates SET is_current = false WHERE type = $1 AND is_current = true`,
        [type]
      );

      const result = await db.query(
        `INSERT INTO submission_templates (type, title, file_path, original_name, mime_type, size_bytes, version, is_current, uploaded_by)
         VALUES ($1, $2, $3, $4, $5, $6, $7, true, $8)
         RETURNING *`,
        [type, title, file.path, file.originalname, file.mimetype, file.size, nextVersion, req.user.sub]
      );
      res.status(201).json({ template: result.rows[0] });
    } catch (err) {
      if (req.file) fs.unlink(req.file.path, () => {});
      next(err);
    }
  }
);

// GET /api/submission-kit — list all templates (teacher sees all versions, student sees current)
router.get('/', authRequired, async (req, res, next) => {
  try {
    let query, params;
    if (req.user.role === 'teacher') {
      query = `SELECT * FROM submission_templates ORDER BY type, version DESC`;
      params = [];
    } else {
      query = `SELECT * FROM submission_templates WHERE is_current = true ORDER BY type`;
      params = [];
    }
    const result = await db.query(query, params);
    res.json({ templates: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/submission-kit/:type/current — student gets current template for type
router.get('/:type/current', authRequired, requireRole('student'), async (req, res, next) => {
  try {
    const { type } = req.params;
    if (!['front_page', 'index_page', 'certificate'].includes(type)) {
      return res.status(400).json({ error: 'Invalid type' });
    }
    const result = await db.query(
      `SELECT * FROM submission_templates WHERE type = $1 AND is_current = true`,
      [type]
    );
    if (!result.rows[0]) {
      return res.status(404).json({ error: 'No current template for this type' });
    }
    res.json({ template: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// GET /api/submission-kit/:id/download — download template file
router.get('/:id/download', authRequired, async (req, res, next) => {
  try {
    const result = await db.query('SELECT * FROM submission_templates WHERE id = $1', [req.params.id]);
    if (!result.rows[0]) return res.status(404).json({ error: 'Template not found' });
    const t = result.rows[0];

    // Students can only download current versions
    if (req.user.role === 'student' && !t.is_current) {
      return res.status(403).json({ error: 'Only current version available' });
    }

    if (!fs.existsSync(t.file_path)) {
      return res.status(404).json({ error: 'File missing on server' });
    }
    res.setHeader('Content-Type', t.mime_type || 'application/octet-stream');
    res.setHeader('Content-Disposition', `attachment; filename="${t.original_name}"`);
    fs.createReadStream(t.file_path).pipe(res);
  } catch (err) {
    next(err);
  }
});

// PUT /api/submission-kit/:id/set-current — teacher set a version as current
router.put(
  '/:id/set-current',
  authRequired,
  requireRole('teacher'),
  async (req, res, next) => {
    try {
      const target = await db.query('SELECT * FROM submission_templates WHERE id = $1', [req.params.id]);
      if (!target.rows[0]) return res.status(404).json({ error: 'Template not found' });
      const type = target.rows[0].type;

      await db.query(
        `UPDATE submission_templates SET is_current = false WHERE type = $1`,
        [type]
      );
      const result = await db.query(
        `UPDATE submission_templates SET is_current = true WHERE id = $1 RETURNING *`,
        [req.params.id]
      );
      res.json({ template: result.rows[0] });
    } catch (err) {
      next(err);
    }
  }
);

module.exports = router;