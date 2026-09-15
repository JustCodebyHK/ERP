require('dotenv').config();
const fs = require('fs');
const path = require('path');
const FormData = require('form-data');
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

async function uploadFile(token, path, filePath, fieldName, fileName, fields) {
  const form = new FormData();
  Object.entries(fields).forEach(([k, v]) => form.append(k, v));
  form.append(fieldName, fs.createReadStream(filePath), fileName);

  const res = await fetch(`${BASE}${path}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, ...form.getHeaders() },
    body: form,
  });
  if (!res.ok) throw new Error(`Upload ${path} failed: ${res.status} ${await res.text()}`);
  return res.json();
}

async function run() {
  const testFile = path.join(__dirname, '..', 'test_assignment.txt');
  fs.writeFileSync(testFile, 'My assignment submission content');

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

    console.log('--- teacher create assignment ---');
    const dueAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(); // tomorrow
    const created = await apiPost(tToken, '/api/assignments', {
      batch_id: batchId,
      subject_id: subjectId,
      title: 'CN Assignment 1 - Network Layers',
      description: 'Explain OSI vs TCP/IP models',
      due_at: dueAt,
      max_score: 50,
    });
    console.log('created:', JSON.stringify(created.assignment));
    const assignmentId = created.assignment.id;

    console.log('--- teacher list assignments ---');
    const list = await apiGet(tToken, `/api/assignments?batch_id=${batchId}&subject_id=${subjectId}`);
    console.log('list:', JSON.stringify(list));

    console.log('--- student my assignments ---');
    const myAssign = await apiGet(sToken, '/api/assignments/my');
    console.log('my assignments:', JSON.stringify(myAssign, null, 2));

    console.log('--- student submit assignment ---');
    await uploadFile(sToken, `/api/assignments/${assignmentId}/submit`, testFile, 'file', 'submission.txt', {});
    console.log('submitted successfully');

    console.log('--- student my assignments after submit ---');
    const myAssign2 = await apiGet(sToken, '/api/assignments/my');
    console.log('my assignments:', JSON.stringify(myAssign2, null, 2));

    console.log('--- teacher view submissions ---');
    const subs = await apiGet(tToken, `/api/assignments/${assignmentId}/submissions`);
    console.log('submissions:', JSON.stringify(subs));

    console.log('--- teacher grade submission ---');
    const studentId = subs.submissions[0].student_id;
    const graded = await apiPost(tToken, `/api/assignments/${assignmentId}/grade`, {
      student_id: studentId,
      score: 45,
    });
    console.log('graded:', JSON.stringify(graded));

    console.log('--- student my assignments after grade ---');
    const myAssign3 = await apiGet(sToken, '/api/assignments/my');
    console.log('my assignments:', JSON.stringify(myAssign3, null, 2));

    // Test student cannot create assignment
    console.log('--- student create assignment (expect 403) ---');
    try {
      await apiPost(sToken, '/api/assignments', {
        batch_id: batchId,
        subject_id: subjectId,
        title: 'Should fail',
        due_at: dueAt,
      });
    } catch (e) {
      console.log('expected error:', e.message);
    }
  } finally {
    server.kill();
    fs.unlinkSync(testFile);
  }
}

run().catch(e => {
  console.error(e);
  process.exit(1);
});