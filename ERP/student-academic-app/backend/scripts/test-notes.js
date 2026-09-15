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

async function uploadNote(token, subjectId, title, filePath, originalName) {
  const form = new FormData();
  form.append('subject_id', subjectId);
  form.append('title', title);
  form.append('file', fs.createReadStream(filePath), originalName);

  const res = await fetch(`${BASE}/api/notes`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, ...form.getHeaders() },
    body: form,
  });
  if (!res.ok) throw new Error(`Upload failed: ${res.status} ${await res.text()}`);
  return res.json();
}

async function listNotes(token, subjectId) {
  const res = await fetch(`${BASE}/api/notes?subject_id=${subjectId}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) throw new Error(`List failed: ${res.status}`);
  return res.json();
}

async function downloadNote(token, noteId, destPath) {
  const res = await fetch(`${BASE}/api/notes/${noteId}/download`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) throw new Error(`Download failed: ${res.status}`);
  const buf = await res.buffer();
  fs.writeFileSync(destPath, buf);
  return buf.length;
}

async function run() {
  // Ensure test file exists
  const testFile = path.join(__dirname, '..', 'test_note.txt');
  fs.writeFileSync(testFile, 'Sample note content for Computer Networks\nLine 2\nLine 3');

  // Start server
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

    console.log('--- teacher upload note ---');
    const subjId = '2b96a3d7-3297-4495-897b-cb539fcbfad4'; // CN from seed
    const uploaded = await uploadNote(tToken, subjId, 'CN Lecture 1 - Intro', testFile, 'cn_intro.txt');
    console.log('uploaded:', JSON.stringify(uploaded.note));

    console.log('--- student list notes ---');
    const studentList = await listNotes(sToken, subjId);
    console.log('student list:', JSON.stringify(studentList));

    console.log('--- teacher list notes ---');
    const teacherList = await listNotes(tToken, subjId);
    console.log('teacher list:', JSON.stringify(teacherList));

    console.log('--- student download ---');
    const noteId = uploaded.note.id;
    const dlPath = path.join(__dirname, '..', 'downloaded_cn_intro.txt');
    const bytes = await downloadNote(sToken, noteId, dlPath);
    console.log(`downloaded ${bytes} bytes, content:`, fs.readFileSync(dlPath, 'utf8'));

    console.log('--- student upload attempt (expect 403) ---');
    try {
      await uploadNote(sToken, subjId, 'Should fail', testFile, 'fail.txt');
    } catch (e) {
      console.log('expected error:', e.message);
    }
  } finally {
    server.kill();
    // cleanup
    fs.unlinkSync(path.join(__dirname, '..', 'test_note.txt'));
    fs.unlinkSync(path.join(__dirname, '..', 'downloaded_cn_intro.txt'));
  }
}

run().catch(e => {
  console.error(e);
  process.exit(1);
});