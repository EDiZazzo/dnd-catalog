const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const connectionString = process.env.SUPABASE_DB_CONNECTION_STRING || 'postgresql://catalog_loader:YOUR_PASSWORD@db.xculeusuctxdujcevnwv.supabase.co:5432/postgres';

const files = [
  'official_classes.sql',
  'official_subclasses.sql',
  'official_spells.sql',
  'official_species.sql',
  'official_feats.sql',
  'official_backgrounds.sql',
  'official_equipment.sql',
  'official_magic_items.sql',
  'ua_classes.sql',
  'ua_subclasses.sql',
  'ua_spells.sql',
  'ua_feats.sql',
  'ua_magic_items.sql'
];

async function load() {
  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false } // Required for Supabase SSL connections
  });

  try {
    await client.connect();
    console.log('Connected to Supabase database.');

    const splitDir = path.join(__dirname, 'data', 'split');

    for (const file of files) {
      const filePath = path.join(splitDir, file);
      if (!fs.existsSync(filePath)) {
        console.warn(`File not found: ${filePath}`);
        continue;
      }

      console.log(`Executing ${file}...`);
      const sql = fs.readFileSync(filePath, 'utf-8');
      
      // Execute the entire SQL block
      await client.query(sql);
      console.log(`Successfully executed ${file}.`);
    }

    console.log('\nAll SQL files executed successfully!');

  } catch (error) {
    console.error('Database loading error:', error.message);
    if (error.detail) console.error('Detail:', error.detail);
    if (error.hint) console.error('Hint:', error.hint);
  } finally {
    await client.end();
  }
}

load();
