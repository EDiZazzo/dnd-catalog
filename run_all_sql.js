const fs = require('fs');
const path = require('path');
const axios = require('axios');

const ACCESS_TOKEN = process.env.SUPABASE_ACCESS_TOKEN || '';
const PROJECT_ID = 'xculeusuctxdujcevnwv';
const ENDPOINT = `https://api.supabase.com/v1/projects/${PROJECT_ID}/database/query`;

const filesToRun = [
  // Official spells chunked (since the main official_spells.sql is 600KB and might hit timeouts/limits)
  'official_spells_chunk_1.sql',
  'official_spells_chunk_2.sql',
  'official_spells_chunk_3.sql',
  'official_spells_chunk_4.sql',
  'official_spells_chunk_5.sql',
  
  // Official other tables
  'official_classes.sql',
  'official_subclasses.sql',
  'official_species.sql',
  'official_feats.sql',
  'official_backgrounds.sql',
  'official_equipment.sql',
  'official_magic_items.sql',
  
  // UA tables
  'ua_spells.sql',
  'ua_classes.sql',
  'ua_subclasses.sql',
  'ua_feats.sql',
  'ua_magic_items.sql'
];

async function runSQL(fileName) {
  const splitDir = 'C:/Users/Emanu/.gemini/antigravity/scratch/data/split';
  const filePath = path.join(splitDir, fileName);
  
  if (!fs.existsSync(filePath)) {
    console.log(`[SKIPPED] ${fileName} - File does not exist.`);
    return;
  }
  
  console.log(`[RUNNING] ${fileName}...`);
  const sqlContent = fs.readFileSync(filePath, 'utf8');
  
  try {
    const response = await axios.post(
      ENDPOINT,
      { query: sqlContent },
      {
        headers: {
          'Authorization': `Bearer ${ACCESS_TOKEN}`,
          'Content-Type': 'application/json'
        },
        timeout: 60000 // 60 seconds timeout for large inserts
      }
    );
    console.log(`[SUCCESS] ${fileName} (Rows/Result: ${response.data.length || 'OK'})`);
  } catch (error) {
    console.error(`[ERROR] ${fileName}:`, error.response ? error.response.status : error.message);
    if (error.response && error.response.data) {
      console.error('Details:', JSON.stringify(error.response.data).slice(0, 500));
    }
  }
}

async function main() {
  for (const file of filesToRun) {
    await runSQL(file);
  }
  console.log('\n--- ALL SQL EXECUTIONS FINISHED ---');
}

main();
