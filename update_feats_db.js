const fs = require('fs');
const path = require('path');

const ACCESS_TOKEN = process.env.SUPABASE_ACCESS_TOKEN || '';
const PROJECT_ID = 'xculeusuctxdujcevnwv';
const ENDPOINT = `https://api.supabase.com/v1/projects/${PROJECT_ID}/database/query`;

const featsJsonPath = 'C:/Users/Emanu/.gemini/antigravity/scratch/data/official_feats.json';
const outSplitPath1 = 'C:/Users/Emanu/.gemini/antigravity/scratch/data/split/official_feats.sql';
const outSplitPath2 = 'g:/Il mio Drive/DnD/Catalogo/data/split/official_feats.sql';

function generateSQL(data, schema, table) {
  let sql = ``;
  for (const row of data) {
    const columns = [];
    const values = [];
    
    for (const [col, val] of Object.entries(row)) {
      columns.push(col);
      
      if (val === null || val === undefined) {
        values.push(`NULL`);
      } else if (typeof val === 'boolean') {
        values.push(val ? 'TRUE' : 'FALSE');
      } else if (typeof val === 'number') {
        values.push(val);
      } else if (Array.isArray(val)) {
        if (col === 'classes' || col === 'saving_throws' || col === 'weapon_proficiencies' || col === 'armor_proficiencies' || col === 'tool_proficiencies' || col === 'skill_proficiencies' || col === 'properties' || col === 'tags') {
          values.push(`ARRAY[${val.map(v => `'${v.replace(/'/g, "''")}'`).join(', ')}]::TEXT[]`);
        } else {
          const jsonStr = JSON.stringify(val).replace(/'/g, "''");
          values.push(`'${jsonStr}'::jsonb`);
        }
      } else if (typeof val === 'object') {
        const jsonStr = JSON.stringify(val).replace(/'/g, "''");
        values.push(`'${jsonStr}'::jsonb`);
      } else {
        const escapedStr = val.replace(/'/g, "''");
        values.push(`'${escapedStr}'`);
      }
    }
    
    const conflictCol = 'name';
    const updateSets = columns
      .filter(c => c !== 'id' && c !== 'name')
      .map(c => `${c} = EXCLUDED.${c}`)
      .join(', ');
      
    sql += `INSERT INTO ${schema}.${table} (${columns.join(', ')}) VALUES (${values.join(', ')}) ON CONFLICT (${conflictCol}) DO UPDATE SET ${updateSets};\n`;
  }
  return sql;
}

async function run() {
  if (!fs.existsSync(featsJsonPath)) {
    console.error('feats.json not found');
    return;
  }

  const data = JSON.parse(fs.readFileSync(featsJsonPath, 'utf8'));
  console.log(`Generating SQL for ${data.length} feats...`);
  const sql = generateSQL(data, 'official', 'feats');

  // Make sure directories exist
  const dir1 = path.dirname(outSplitPath1);
  if (!fs.existsSync(dir1)) fs.mkdirSync(dir1, { recursive: true });
  
  const dir2 = path.dirname(outSplitPath2);
  if (!fs.existsSync(dir2)) fs.mkdirSync(dir2, { recursive: true });

  fs.writeFileSync(outSplitPath1, sql);
  fs.writeFileSync(outSplitPath2, sql);
  console.log(`Wrote SQL to ${outSplitPath1} and ${outSplitPath2}`);

  console.log('Uploading to Supabase database via native fetch...');
  try {
    const response = await fetch(ENDPOINT, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${ACCESS_TOKEN}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ query: sql })
    });
    
    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`HTTP ${response.status}: ${errText}`);
    }

    const resData = await response.json();
    console.log(`[SUCCESS] database updated (Rows/Result: ${resData.length || 'OK'})`);
  } catch (error) {
    console.error('[ERROR] failed to upload to DB:', error.message);
  }
}

run();
