const express = require('express');
const db = require('../db');

const router = express.Router();
const startTime = Date.now();

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

router.get('/uptime', (req, res) => {
  const uptimeSeconds = Math.floor((Date.now() - startTime) / 1000);
  res.json({ uptime_seconds: uptimeSeconds, started_at: new Date(startTime).toISOString() });
});

module.exports = router;
