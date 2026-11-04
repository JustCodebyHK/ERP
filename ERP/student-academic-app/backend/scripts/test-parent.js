const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function testParent(includeChildren = false) {
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT * FROM parents');
    console.log(\Found \ parents\);
    if (includeChildren) {
      for (const parent of result.rows) {
        const kids = await client.query('SELECT * FROM children WHERE parent_id = ', [parent.id]);
        console.log(\  Parent \: \ children\);
      }
    }
  } finally {
    client.release();
  }
}

const includeChildren = process.argv.includes('--children');
testParent(includeChildren).catch(err => { console.error(err); process.exit(1); });
