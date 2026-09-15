const express = require('express');
const db = require('../db');

const router = express.Router();

router.get('/', async (req, res) => {
  if (!db.isConfigured()) {
    return res.json({ api: 'ok', db: 'not configured' });
  }
  try {
    const result = await db.query('SELECT 1 AS ok');
    res.json({ api: 'ok', db: result.rows[0].ok === 1 ? 'connected' : 'error' });
  } catch (err) {
    res.status(503).json({ api: 'ok', db: 'error', detail: err.message });
  }
});

module.exports = router;
