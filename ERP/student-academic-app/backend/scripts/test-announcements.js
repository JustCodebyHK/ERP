require('dotenv').config();
const path = require('path');
const fetch = require('node-fetch');

const BASE = 'http://localhost:4000';

async function login(email, password) {
  const res = await fetch(`${BASE}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  if (!res.ok) throw new Error(`Login failed: ${res.status}`);
  return res.json();
}

async function apiGet(token, path) {
  const res = await fetch(`${BASE}${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) throw new Error(`GET ${path} failed: ${res.status} ${await res.text()}`);
  return res.json();
}

async function apiPost(token, path, body) {
  const res = await fetch(`${BASE}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`POST ${path} failed: ${res.status} ${await res.text()}`);
  return res.json();
}

async function apiDelete(token, path) {
  const res = await fetch(`${BASE}${path}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) throw new Error(`DELETE ${path} failed: ${res.status} ${await res.text()}`);
  return res.json();
}

async function run() {
  const { spawn } = require('child_process');
  const server = spawn('node', ['src/index.js'], {
    cwd: path.join(__dirname, '..'),
    stdio: 'pipe',
  });

  server.stdout.on('data', d => console.log('[server]', d.toString().trim()));
  server.stderr.on('data', d => console.error('[server err]', d.toString().trim()));

  await new Promise(r => setTimeout(r, 2000));

  try {
    console.log('--- login teacher ---');
    const { token: tToken } = await login('rao@college.edu', 'password123');
    console.log('--- login student ---');
    const { token: sToken } = await login('asha@college.edu', 'password123');

    // Get batch_id
    console.log('--- get classes to find batch_id ---');
    const classes = await apiGet(tToken, '/api/academic/my-classes');
    const batchId = classes.classes[0].batch_id;
    console.log('batch_id:', batchId);

    console.log('--- teacher create global announcement ---');
    const global = await apiPost(tToken, '/api/announcements', {
      type: 'holiday',
      title: 'College Holiday',
      body: 'College will be closed on Monday for annual day.',
    });
    console.log('global:', JSON.stringify(global.announcement));

    console.log('--- teacher create batch-specific announcement ---');
    const batchAnn = await apiPost(tToken, '/api/announcements', {
      batch_id: batchId,
      type: 'exam',
      title: 'Mid-term Exam Schedule',
      body: 'CN mid-term on 20th Sept, 10 AM in Room 101.',
    });
    console.log('batch-specific:', JSON.stringify(batchAnn.announcement));

    console.log('--- teacher list all announcements ---');
    const teacherList = await apiGet(tToken, '/api/announcements');
    console.log('teacher list:', JSON.stringify(teacherList));

    console.log('--- student list (global + enrolled) ---');
    const studentList = await apiGet(sToken, '/api/announcements');
    console.log('student list:', JSON.stringify(studentList));

    console.log('--- student unread count ---');
    const unread = await apiGet(sToken, '/api/announcements/unread-count');
    console.log('unread:', JSON.stringify(unread));

    console.log('--- student mark global as read ---');
    await apiPost(sToken, `/api/announcements/${global.announcement.id}/read`, {});
    console.log('marked read');

    console.log('--- student unread count after read ---');
    const unread2 = await apiGet(sToken, '/api/announcements/unread-count');
    console.log('unread:', JSON.stringify(unread2));

    console.log('--- student cannot create (expect 403) ---');
    try {
      await apiPost(sToken, '/api/announcements', { type: 'general', title: 'test', body: 'test' });
    } catch (e) {
      console.log('expected error:', e.message);
    }

    console.log('--- teacher delete own ---');
    await apiDelete(tToken, `/api/announcements/${batchAnn.announcement.id}`);
    console.log('deleted');

    console.log('--- teacher list after delete ---');
    const teacherList2 = await apiGet(tToken, '/api/announcements');
    console.log('teacher list:', JSON.stringify(teacherList2));

  } finally {
    server.kill();
  }
}

run().catch(e => {
  console.error(e);
  process.exit(1);
});