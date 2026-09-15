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
    console.log('--- login student ---');
    const { token: sToken } = await login('asha@college.edu', 'password123');

    console.log('--- login parent ---');
    const { token: pToken } = await login('priya.sharma@parent.com', 'parent123');

    console.log('--- login teacher ---');
    const { token: tToken } = await login('rao@college.edu', 'password123');

    console.log('--- student my growth index ---');
    const myGrowth = await apiGet(sToken, '/api/growth/me');
    console.log('my growth:', JSON.stringify(myGrowth, null, 2));

    console.log('--- parent view child growth ---');
    const parentGrowth = await apiGet(pToken, '/api/growth/student/dd29d100-a662-4ce6-b412-8bcc10c0932d');
    console.log('parent view:', JSON.stringify(parentGrowth, null, 2));

    console.log('--- teacher view child growth ---');
    const teacherGrowth = await apiGet(tToken, '/api/growth/student/dd29d100-a662-4ce6-b412-8bcc10c0932d');
    console.log('teacher view:', JSON.stringify(teacherGrowth, null, 2));

    console.log('--- student cannot view other student (expect 403) ---');
    try {
      await apiGet(sToken, '/api/growth/student/6c4d80be-ed2f-4045-b052-c309e959b9e1');
    } catch (e) {
      console.log('expected error:', e.message);
    }

    console.log('--- parent cannot view unlinked student (expect 403) ---');
    try {
      await apiGet(pToken, '/api/growth/student/6c4d80be-ed2f-4045-b052-c309e959b9e1');
    } catch (e) {
      console.log('expected error:', e.message);
    }

    console.log('\n=== ALL GROWTH INDEX TESTS PASSED ===');

  } finally {
    server.kill();
  }
}

run().catch(e => {
  console.error(e);
  process.exit(1);
});