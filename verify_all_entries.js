const fs = require('fs');
const path = require('path');
const axios = require('axios');

const ACCESS_TOKEN = process.env.SUPABASE_ACCESS_TOKEN || '';
const PROJECT_ID = 'xculeusuctxdujcevnwv';
const ENDPOINT = `https://api.supabase.com/v1/projects/${PROJECT_ID}/database/query`;

const DATA_DIR = 'C:/Users/Emanu/.gemini/antigravity/scratch/data';

// Helper to normalize strings for comparison (collapsing whitespaces, quotes, case)
function normalizeText(text) {
  if (text === null || text === undefined) return '';
  return String(text)
    .replace(/[\u2018\u2019']/g, "'") // normalize single quotes
    .replace(/[\u201C\u201D"]/g, '"') // normalize double quotes
    .replace(/\s+/g, ' ')            // collapse multiple spaces/newlines
    .trim()
    .toLowerCase();
}

async function runQuery(sql) {
  try {
    const response = await axios.post(
      ENDPOINT,
      { query: sql },
      {
        headers: {
          'Authorization': `Bearer ${ACCESS_TOKEN}`,
          'Content-Type': 'application/json'
        },
        timeout: 30000
      }
    );
    return response.data;
  } catch (error) {
    console.error(`Error running query: ${sql}`, error.response ? error.response.status : error.message);
    if (error.response && error.response.data) {
      console.error('Details:', error.response.data);
    }
    return null;
  }
}

// Map json keys to db columns, specify table schema, and fields to check
const verifications = [
  {
    jsonFile: 'official_spells.json',
    table: 'official.spells',
    fields: ['level', 'school', 'casting_time', 'range', 'components', 'duration', 'source', 'description']
  },
  {
    jsonFile: 'ua_spells.json',
    table: 'ua.spells',
    fields: ['level', 'school', 'casting_time', 'range', 'components', 'duration', 'source', 'description']
  },
  {
    jsonFile: 'official_species.json',
    table: 'official.species',
    fields: ['source', 'description', 'creature_type', 'size', 'speed']
  },
  {
    jsonFile: 'official_backgrounds.json',
    table: 'official.backgrounds',
    fields: ['source', 'description', 'ability_scores', 'feats']
  },
  {
    jsonFile: 'official_classes.json',
    table: 'official.classes',
    fields: ['source', 'description', 'primary_ability', 'hit_die']
  },
  {
    jsonFile: 'ua_classes.json',
    table: 'ua.classes',
    fields: ['source', 'description', 'primary_ability', 'hit_die']
  },
  {
    jsonFile: 'official_subclasses.json',
    table: 'official.subclasses',
    fields: ['source', 'description', 'class_name']
  },
  {
    jsonFile: 'ua_subclasses.json',
    table: 'ua.subclasses',
    fields: ['source', 'description', 'class_name']
  },
  {
    jsonFile: 'official_feats.json',
    table: 'official.feats',
    fields: ['source', 'description', 'category', 'prerequisite']
  },
  {
    jsonFile: 'ua_feats.json',
    table: 'ua.feats',
    fields: ['source', 'description', 'category', 'prerequisite']
  },
  {
    jsonFile: 'official_equipment.json',
    table: 'official.equipment',
    fields: ['source', 'description', 'category', 'cost', 'weight', 'properties']
  },
  {
    jsonFile: 'official_magic_items.json',
    table: 'official.magic_items',
    fields: ['source', 'description', 'rarity', 'type', 'attunement']
  },
  {
    jsonFile: 'ua_magic_items.json',
    table: 'ua.magic_items',
    fields: ['source', 'description', 'rarity', 'type', 'attunement']
  }
];

async function verifyTable(config) {
  const jsonPath = path.join(DATA_DIR, config.jsonFile);
  if (!fs.existsSync(jsonPath)) {
    console.log(`[SKIPPED] ${config.jsonFile} does not exist.`);
    return;
  }

  const items = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  console.log(`\nVerifying ${config.jsonFile} (${items.length} items) against table ${config.table}...`);

  // Fetch all records from DB to do fast in-memory lookups rather than querying one by one (to avoid API overhead)
  const dbData = await runQuery(`SELECT * FROM ${config.table};`);
  if (!dbData) {
    console.error(`Failed to fetch database data for ${config.table}`);
    return;
  }

  // Index DB data by name
  const dbMap = new Map();
  for (const row of dbData) {
    dbMap.set(row.name.toLowerCase().trim(), row);
  }

  let missingCount = 0;
  let mismatchCount = 0;
  let matchCount = 0;

  for (const item of items) {
    const nameLower = item.name.toLowerCase().trim();
    const dbRow = dbMap.get(nameLower);

    if (!dbRow) {
      console.error(`  [MISSING IN DB] Name: "${item.name}"`);
      missingCount++;
      continue;
    }

    let itemHasMismatch = false;
    const mismatches = [];

    for (const field of config.fields) {
      let jsonVal = item[field];
      let dbVal = dbRow[field];

      // Handle arrays/objects conversion if necessary
      if (typeof jsonVal === 'object' && jsonVal !== null) {
        jsonVal = JSON.stringify(jsonVal);
      }
      if (typeof dbVal === 'object' && dbVal !== null) {
        dbVal = JSON.stringify(dbVal);
      }

      const normJson = normalizeText(jsonVal);
      const normDb = normalizeText(dbVal);

      if (normJson !== normDb) {
        itemHasMismatch = true;
        mismatches.push({
          field,
          json: String(jsonVal).slice(0, 100) + (String(jsonVal).length > 100 ? '...' : ''),
          db: String(dbVal).slice(0, 100) + (String(dbVal).length > 100 ? '...' : '')
        });
      }
    }

    if (itemHasMismatch) {
      mismatchCount++;
      console.warn(`  [MISMATCH] "${item.name}":`);
      for (const m of mismatches) {
        console.warn(`    - Field "${m.field}":`);
        console.warn(`      JSON: ${JSON.stringify(m.json)}`);
        console.warn(`      DB:   ${JSON.stringify(m.db)}`);
      }
    } else {
      matchCount++;
    }
  }

  console.log(`Results for ${config.table}:`);
  console.log(`  - Match: ${matchCount}`);
  console.log(`  - Mismatch: ${mismatchCount}`);
  console.log(`  - Missing: ${missingCount}`);
  console.log(`  - Total processed: ${items.length} vs Total in DB: ${dbData.length}`);
  
  if (missingCount > 0 || mismatchCount > 0) {
    console.error(`[VERIFICATION FAILED] for ${config.table}`);
  } else {
    console.log(`[VERIFICATION PASSED] for ${config.table}`);
  }
}

async function main() {
  for (const ver of verifications) {
    await verifyTable(ver);
  }
  console.log('\n--- VERIFICATION OF ALL TABLES COMPLETED ---');
}

main();
