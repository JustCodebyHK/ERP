const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function testGroups(minMembers = null) {
  const client = await pool.connect();
  try {
    let query = 'SELECT g.*, COUNT(m.user_id) AS member_count FROM groups g LEFT JOIN group_members m ON m.group_id = g.id GROUP BY g.id';
    const params = [];
    if (minMembers !== null) {
      query += ' HAVING COUNT(m.user_id) >= ';
      params.push(minMembers);
    }
    query += ' ORDER BY member_count DESC';
    const result = await client.query(query, params);
    console.log(\Found \ groups\);
    result.rows.forEach(row => console.log(\  [\] \ (\ members)\));
  } finally {
    client.release();
  }
}

const minMembers = process.argv[2] ? parseInt(process.argv[2]) : null;
testGroups(minMembers).catch(err => { console.error(err); process.exit(1); });
