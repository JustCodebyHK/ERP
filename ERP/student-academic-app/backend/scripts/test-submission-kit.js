require('dotenv').config();
const path = require('path');
const fs = require('fs');
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
  const testFile = path.join(__dirname, '..', 'test_front.pdf');
  fs.writeFileSync(testFile, '%PDF-1.4\ntest front page content');

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

    console.log('--- teacher upload front_page v1 ---');
    const v1 = await uploadFile(tToken, '/api/submission-kit', testFile, 'file', 'front_v1.pdf', {
      type: 'front_page',
      title: 'Standard Front Page v1',
    });
    console.log('v1:', JSON.stringify(v1.template));

    console.log('--- teacher upload index_page v1 ---');
    await uploadFile(tToken, '/api/submission-kit', testFile, 'file', 'index_v1.pdf', {
      type: 'index_page',
      title: 'Standard Index Page v1',
    });

    console.log('--- teacher upload certificate v1 ---');
    await uploadFile(tToken, '/api/submission-kit', testFile, 'file', 'cert_v1.pdf', {
      type: 'certificate',
      title: 'Standard Certificate v1',
    });

    console.log('--- teacher list all versions ---');
    const list = await apiGet(tToken, '/api/submission-kit');
    console.log('list:', JSON.stringify(list, null, 2));

    console.log('--- student list (current only) ---');
    const studentList = await apiGet(sToken, '/api/submission-kit');
    console.log('student list:', JSON.stringify(studentList, null, 2));

    console.log('--- student get current front_page ---');
    const current = await apiGet(sToken, '/api/submission-kit/front_page/current');
    console.log('current:', JSON.stringify(current.template));

    console.log('--- student download front_page ---');
    const dlRes = await fetch(`${BASE}/api/submission-kit/${current.template.id}/download`, {
      headers: { Authorization: `Bearer ${sToken}` },
    });
    console.log('downloaded bytes:', dlRes.headers.get('content-length'));

    console.log('--- teacher upload front_page v2 ---');
    const v2 = await uploadFile(tToken, '/api/submission-kit', testFile, 'file', 'front_v2.pdf', {
      type: 'front_page',
      title: 'Standard Front Page v2',
    });
    console.log('v2:', JSON.stringify(v2.template));

    console.log('--- student get current front_page (should be v2) ---');
    const current2 = await apiGet(sToken, '/api/submission-kit/front_page/current');
    console.log('current:', JSON.stringify(current2.template));

    console.log('--- teacher set v1 as current ---');
    const v1Id = list.templates.find(t => t.type === 'front_page' && t.version === 1).id;
    await apiPost(tToken, `/api/submission-kit/${v1Id}/set-current`, {});
    console.log('v1 set as current');

    console.log('--- student get current front_page (should be v1 again) ---');
    const current3 = await apiGet(sToken, '/api/submission-kit/front_page/current');
    console.log('current:', JSON.stringify(current3.template));

    console.log('--- student cannot upload (expect 403) ---');
    try {
      await uploadFile(sToken, '/api/submission-kit', testFile, 'file', 'bad.pdf', {
        type: 'front_page',
        title: 'Should fail',
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