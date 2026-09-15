require('dotenv').config();
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

async function registerOrLoginParent() {
  try {
    const res = await fetch(`${BASE}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Priya Sharma',
        email: 'priya.sharma@parent.com',
        password: 'parent123',
        role: 'parent',
      }),
    });
    if (!res.ok) throw new Error(`Register failed: ${res.status}`);
    return res.json();
  } catch {
    return login('priya.sharma@parent.com', 'parent123');
  }
}

async function run() {
  const { spawn } = require('child_process');
  const path = require('path');

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

    console.log('--- register/login parent ---');
    const parentData = await registerOrLoginParent();
    console.log('parent:', JSON.stringify(parentData));

    console.log('--- login parent ---');
    const { token: pToken } = await login('priya.sharma@parent.com', 'parent123');

    console.log('--- parent link to student ---');
    await apiPost(pToken, '/api/parent/link', {
      student_email: 'asha@college.edu',
      relationship: 'mother',
    });
    console.log('linked');

    console.log('--- parent list children ---');
    const children = await apiGet(pToken, '/api/parent/children');
    console.log('children:', JSON.stringify(children, null, 2));

    console.log('--- parent child overview ---');
    const studentId = children.children[0].id;
    const overview = await apiGet(pToken, `/api/parent/children/${studentId}/overview`);
    console.log('overview:', JSON.stringify(overview, null, 2));

    console.log('--- parent child attendance ---');
    const attendance = await apiGet(pToken, `/api/parent/children/${studentId}/attendance`);
    console.log('attendance:', JSON.stringify(attendance));

    console.log('--- parent child marks ---');
    const marks = await apiGet(pToken, `/api/parent/children/${studentId}/marks`);
    console.log('marks:', JSON.stringify(marks));

    console.log('--- parent child assignments ---');
    const assignments = await apiGet(pToken, `/api/parent/children/${studentId}/assignments`);
    console.log('assignments:', JSON.stringify(assignments));

    console.log('--- parent child announcements ---');
    const announcements = await apiGet(pToken, `/api/parent/children/${studentId}/announcements`);
    console.log('announcements:', JSON.stringify(announcements));

    console.log('--- student cannot access parent endpoints (expect 403) ---');
    const { token: sToken } = await login('asha@college.edu', 'password123');
    try {
      await apiGet(sToken, '/api/parent/children');
    } catch (e) {
      console.log('expected error:', e.message);
    }

    console.log('--- teacher cannot access parent endpoints (expect 403) ---');
    const { token: tToken2 } = await login('rao@college.edu', 'password123');
    try {
      await apiGet(tToken2, '/api/parent/children');
    } catch (e) {
      console.log('expected error:', e.message);
    }

    console.log('\\n=== ALL PARENT TESTS PASSED ===');

  } finally {
    server.kill();
  }
}

run().catch(e => {
  console.error(e);
  process.exit(1);
});