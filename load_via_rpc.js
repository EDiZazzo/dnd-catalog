const axios = require('axios');
const fs = require('fs');
const path = require('path');

const PROJECT_URL = 'https://xculeusuctxdujcevnwv.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhjdWxldXN1Y3R4ZHVqY2V2bnd2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA3NTU3MTIsImV4cCI6MjA5NjMzMTcxMn0.Lga4Hoy7aJ-mjAOYH7dxWiQV4Yreu2_HpYFs6cFrDNY';

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
  const splitDir = path.join(__dirname, 'data', 'split');

  for (const file of files) {
    const filePath = path.join(splitDir, file);
    if (!fs.existsSync(filePath)) {
      console.warn(`File not found: ${filePath}`);
      continue;
    }

    console.log(`Sending ${file} to RPC...`);
    const sql = fs.readFileSync(filePath, 'utf-8');

    try {
      const response = await axios.post(
        `${PROJECT_URL}/rest/v1/rpc/execute_arbitrary_sql`,
        { sql_query: sql },
        {
          headers: {
            'apikey': ANON_KEY,
            'Authorization': `Bearer ${ANON_KEY}`,
            'Content-Type': 'application/json'
          }
        }
      );
      console.log(`Successfully loaded ${file} (Status: ${response.status})`);
    } catch (error) {
      console.error(`Error loading ${file}:`, error.response ? error.response.status : error.message);
      if (error.response && error.response.data) {
        console.error('Error details:', error.response.data);
      }
    }
  }
}

load();
