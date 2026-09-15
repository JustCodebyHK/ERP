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

async function apiPut(token, path, body) {
  const res = await fetch(`${BASE}${path}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`PUT ${path} failed: ${res.status} ${await res.text()}`);
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

    const today = new Date().toISOString().split('T')[0];

    console.log('--- create free-floating task ---');
    const task1 = await apiPost(sToken, '/api/planner/tasks', {
      title: 'Review CN lecture notes',
      description: 'Go through slides 1-15',
      priority: 2,
      scheduled_for: today,
    });
    console.log('task1:', JSON.stringify(task1.task));

    console.log('--- create lecture-linked task ---');
    const myClasses = await fetch(`${BASE}/api/academic/my-classes`, {
      headers: { Authorization: `Bearer ${sToken}` },
    }).then(r => r.json());
    // We need timetable_entry_id, let's get it from timetable
    console.log('my-classes:', JSON.stringify(myClasses));

    // Get timetable entries
    const timetable = await fetch(`${BASE}/api/timetable/my`, {
      headers: { Authorization: `Bearer ${sToken}` },
    }).then(r => r.json());
    console.log('timetable:', JSON.stringify(timetable));

    if (timetable.entries && timetable.entries.length > 0) {
      const entryId = timetable.entries[0].id;
      const task2 = await apiPost(sToken, '/api/planner/tasks', {
        title: 'Prepare for CN lecture',
        priority: 3,
        scheduled_for: today,
        timetable_entry_id: entryId,
      });
      console.log('task2 (linked):', JSON.stringify(task2.task));
    }

    console.log('--- get today tasks ---');
    const todayTasks = await apiGet(sToken, `/api/planner/tasks?date=${today}`);
    console.log('today tasks:', JSON.stringify(todayTasks));

    console.log('--- get week tasks ---');
    const weekTasks = await apiGet(sToken, `/api/planner/tasks/week?start=${today}`);
    console.log('week tasks:', JSON.stringify(weekTasks));

    console.log('--- complete task ---');
    if (todayTasks.tasks && todayTasks.tasks.length > 0) {
      const taskId = todayTasks.tasks[0].id;
      const completed = await apiPost(sToken, `/api/planner/tasks/${taskId}/complete`, {});
      console.log('completed:', JSON.stringify(completed));
    }

    console.log('--- carry forward task ---');
    const pendingTasks = await apiGet(sToken, `/api/planner/tasks?date=${today}`);
    const pending = pendingTasks.tasks.find(t => t.status === 'pending');
    if (pending) {
      const carried = await apiPost(sToken, `/api/planner/tasks/${pending.id}/carry-forward`, {});
      console.log('carried:', JSON.stringify(carried));
    }

    console.log('--- daily digest ---');
    const digest = await apiGet(sToken, '/api/planner/digest/today');
    console.log('daily digest:', JSON.stringify(digest, null, 2));

    console.log('--- weekly digest ---');
    const weekDigest = await apiGet(sToken, `/api/planner/digest/week?start=${today}`);
    console.log('weekly digest:', JSON.stringify(weekDigest, null, 2));

    console.log('--- delete task ---');
    const allTasks = await apiGet(sToken, `/api/planner/tasks?date=${today}`);
    if (allTasks.tasks && allTasks.tasks.length > 0) {
      const deleteId = allTasks.tasks[allTasks.tasks.length - 1].id;
      await fetch(`${BASE}/api/planner/tasks/${deleteId}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${sToken}` },
      });
      console.log('deleted task:', deleteId);
    }

    console.log('\n=== ALL PLANNER TESTS PASSED ===');

  } catch (e) {
    console.error(e);
    process.exit(1);
  } finally {
    // Need to kill the server process
    // This is a bit hacky but works for testing
    const { execSync } = require('child_process');
    try { execSync('taskkill /F /IM node.exe /FI "WINDOWTITLE eq *node src/index.js*"', { stdio: 'ignore' }); } catch {}
  }
}

run().catch(e => {
  console.error(e);
  process.exit(1);
});