const express = require('express');
const db = require('../db');
const os = require('os');
const pkg = require('../../package.json');

const router = express.Router();
const startTime = Date.now();

router.get('/', async (req, res) => {
  if (!db.isConfigured()) {
    return res.json({ api: 'ok', db: 'not configured' });
  }
  try {
    const start = Date.now();
    const result = await db.query('SELECT 1 AS ok');
    const latency = Date.now() - start;
    res.json({
      api: 'ok',
      db: result.rows[0].ok === 1 ? 'connected' : 'error',
      db_latency_ms: latency
    });
  } catch (err) {
    res.status(503).json({ api: 'ok', db: 'error', detail: err.message });
  }
});

router.get('/uptime', (req, res) => {
  const uptimeSeconds = Math.floor((Date.now() - startTime) / 1000);
  res.json({ uptime_seconds: uptimeSeconds, started_at: new Date(startTime).toISOString() });
});

router.get('/memory', (req, res) => {
  const mem = process.memoryUsage();
  res.json({
    rss: Math.round(mem.rss / 1024 / 1024),
    heapTotal: Math.round(mem.heapTotal / 1024 / 1024),
    heapUsed: Math.round(mem.heapUsed / 1024 / 1024),
    external: Math.round(mem.external / 1024 / 1024)
  });
});

router.get('/cpu', (req, res) => {
  const cpus = os.cpus();
  let totalIdle = 0;
  let totalTick = 0;
  cpus.forEach(cpu => {
    const { idle, times } = cpu;
    const typeTimes = Object.values(times);
    totalIdle += idle;
    totalTick += typeTimes.reduce((a, b) => a + b, 0);
  });
  res.json({
    cpu_count: cpus.length,
    load_average: os.loadavg(),
    total_tick: totalTick,
    idle_tick: totalIdle
  });
});

router.get('/summary', async (req, res) => {
  if (!db.isConfigured()) {
    return res.json({ api: 'ok', db: 'not configured' });
  }
  try {
    const start = Date.now();
    await db.query('SELECT 1 AS ok');
    const dbLatency = Date.now() - start;
    const uptimeSeconds = Math.floor((Date.now() - startTime) / 1000);
    const mem = process.memoryUsage();
    const cpus = os.cpus();
    res.json({
      status: 'ok',
      api: 'ok',
      db: 'connected',
      db_latency_ms: dbLatency,
      uptime_seconds: uptimeSeconds,
      memory: {
        rss_mb: Math.round(mem.rss / 1024 / 1024),
        heap_used_mb: Math.round(mem.heapUsed / 1024 / 1024)
      },
      cpu: { count: cpus.length, load_average: os.loadavg() },
      environment: process.env.NODE_ENV || 'development',
      version: pkg.version,
      node_version: process.version,
      platform: process.platform,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(503).json({ status: 'error', db: 'error', detail: err.message });
  }
});

router.get('/ready', async (req, res) => {
  if (!db.isConfigured()) {
    return res.status(503).json({ ready: false, reason: 'database not configured' });
  }
  try {
    await db.query('SELECT 1 AS ok');
    res.json({ ready: true });
  } catch {
    res.status(503).json({ ready: false, reason: 'database query failed' });
  }
});

router.get('/live', (req, res) => {
  res.json({ live: true, uptime_seconds: Math.floor((Date.now() - startTime) / 1000) });
});

module.exports = router;
