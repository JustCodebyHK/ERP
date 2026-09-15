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

async function apiPut(token, path, body) {
  const res = await fetch(`${BASE}${path}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`PUT ${path} failed: ${res.status} ${await res.text()}`);
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

    // Get batch_id and subject_id from seed data
    console.log('--- get classes to find batch_id ---');
    const classes = await apiGet(tToken, '/api/academic/my-classes');
    const batchId = classes.classes[0].batch_id;
    const subjectId = classes.classes[0].subject_id;
    console.log('batch_id:', batchId, 'subject_id:', subjectId);

    // Clean up any existing entries for this batch+subject
    console.log('--- clean up existing entries ---');
    const existing = await apiGet(tToken, `/api/timetable?batch_id=${batchId}&subject_id=${subjectId}`);
    for (const e of existing.entries) {
      await apiDelete(tToken, `/api/timetable/${e.id}`);
    }

    console.log('--- teacher create timetable entries ---');
    // Monday (1) 9:00-10:30
    const mon = await apiPost(tToken, '/api/timetable', {
      batch_id: batchId,
      subject_id: subjectId,
      day_of_week: 1,
      start_time: '09:00',
      end_time: '10:30',
      room: 'Room 101',
    });
    console.log('Monday entry:', JSON.stringify(mon.entry));

    // Wednesday (3) 11:00-12:30
    const wed = await apiPost(tToken, '/api/timetable', {
      batch_id: batchId,
      subject_id: subjectId,
      day_of_week: 3,
      start_time: '11:00',
      end_time: '12:30',
      room: 'Lab 2',
    });
    console.log('Wednesday entry:', JSON.stringify(wed.entry));

    // Friday (5) 14:00-15:30
    const fri = await apiPost(tToken, '/api/timetable', {
      batch_id: batchId,
      subject_id: subjectId,
      day_of_week: 5,
      start_time: '14:00',
      end_time: '15:30',
      room: 'Room 101',
    });
    console.log('Friday entry:', JSON.stringify(fri.entry));

    console.log('--- list timetable for class ---');
    const list = await apiGet(tToken, `/api/timetable?batch_id=${batchId}&subject_id=${subjectId}`);
    console.log('list:', JSON.stringify(list));

    console.log('--- student my full timetable ---');
    const myTt = await apiGet(sToken, '/api/timetable/my');
    console.log('my timetable:', JSON.stringify(myTt, null, 2));

    console.log('--- student today ---');
    const today = await apiGet(sToken, '/api/timetable/today');
    console.log('today:', JSON.stringify(today));

    console.log('--- teacher update entry ---');
    const updated = await apiPut(tToken, `/api/timetable/${mon.entry.id}`, { room: 'Room 202' });
    console.log('updated:', JSON.stringify(updated));

    console.log('--- student cannot create (expect 403) ---');
    try {
      await apiPost(sToken, '/api/timetable', {
        batch_id: batchId,
        subject_id: subjectId,
        day_of_week: 2,
        start_time: '10:00',
        end_time: '11:30',
      });
    } catch (e) {
      console.log('expected error:', e.message);
    }

    console.log('--- teacher delete entry ---');
    await apiDelete(tToken, `/api/timetable/${wed.entry.id}`);
    console.log('deleted');

    console.log('--- verify deleted ---');
    const list2 = await apiGet(tToken, `/api/timetable?batch_id=${batchId}&subject_id=${subjectId}`);
    console.log('list after delete:', JSON.stringify(list2));

  } finally {
    server.kill();
  }
}

run().catch(e => {
  console.error(e);
  process.exit(1);
});