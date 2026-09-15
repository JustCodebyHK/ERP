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
    const { token: tToken } = await login('rao@ybit.ac.in', 'password123');
    console.log('--- login student ---');
    const { token: sToken } = await login('asha@ybit.ac.in', 'password123');

    console.log('--- teacher create group ---');
    const group = await apiPost(tToken, '/api/groups', {
      name: 'CN Study Group',
      description: 'Study group for Computer Networks',
      type: 'group',
    });
    console.log('group created:', JSON.stringify(group.group));
    const groupId = group.group.id;

    console.log('--- teacher list groups ---');
    const tGroups = await apiGet(tToken, '/api/groups');
    console.log('teacher groups:', JSON.stringify(tGroups));

    console.log('--- student list groups (before join) ---');
    const sGroupsBefore = await apiGet(sToken, '/api/groups');
    console.log('student groups before join:', JSON.stringify(sGroupsBefore));

    console.log('--- student join group ---');
    const inviteCode = group.group.invite_code;
    const join = await apiPost(sToken, '/api/groups/join', { invite_code: inviteCode });
    console.log('joined:', JSON.stringify(join));

    console.log('--- student list groups (after join) ---');
    const sGroupsAfter = await apiGet(sToken, '/api/groups');
    console.log('student groups after join:', JSON.stringify(sGroupsAfter));

    console.log('--- teacher get group details ---');
    const groupDetails = await apiGet(tToken, `/api/groups/${groupId}`);
    console.log('group details:', JSON.stringify(groupDetails));

    console.log('--- teacher list members ---');
    const members = await apiGet(tToken, `/api/groups/${groupId}/members`);
    console.log('members:', JSON.stringify(members));

    console.log('--- student send message ---');
    const msg = await fetch(`${BASE}/api/groups/${groupId}/messages`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${sToken}` },
      body: JSON.stringify({ content: 'Hello everyone! Ready to study?', type: 'text' }),
    });
    if (!msg.ok) throw new Error(`Send message failed: ${msg.status} ${await msg.text()}`);
    const sentMsg = await msg.json();
    console.log('message sent:', JSON.stringify(sentMsg.message));

    console.log('--- teacher get messages ---');
    const messages = await apiGet(tToken, `/api/groups/${groupId}/messages`);
    console.log('messages:', JSON.stringify(messages));

    console.log('--- teacher create announcement ---');
    const ann = await apiPost(tToken, `/api/groups/${groupId}/announcements`, {
      type: 'info',
      title: 'Welcome!',
      body: 'Welcome to the CN Study Group. Please be respectful.',
      pinned: true,
    });
    console.log('announcement created:', JSON.stringify(ann.announcement));

    console.log('--- student get announcements ---');
    const announcements = await apiGet(sToken, `/api/groups/${groupId}/announcements`);
    console.log('announcements:', JSON.stringify(announcements));

    console.log('\n=== ALL GROUP TESTS PASSED ===');
  } catch (e) {
    console.error('Test failed:', e);
    process.exit(1);
  } finally {
    server.kill();
  }
}

run().catch(e => {
  console.error(e);
  process.exit(1);
});