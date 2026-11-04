const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function testAnnouncements(limit = 10) {
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT * FROM announcements ORDER BY created_at DESC LIMIT ', [limit]);
    console.log(\Found \ announcements:\);
    result.rows.forEach(row => console.log(\  [\] \\));
  } finally {
    client.release();
  }
}

const limit = parseInt(process.argv.find(a => a.startsWith('--limit='))?.split('=')[1]) || 10;
testAnnouncements(limit).catch(err => { console.error(err); process.exit(1); });
