const fs = require('fs');
const path = require('path');

const dataDir = path.join(__dirname, 'data');
const splitDir = path.join(dataDir, 'split');
if (!fs.existsSync(splitDir)) {
  fs.mkdirSync(splitDir);
}

function splitFile(filename, schemaName) {
  const filePath = path.join(dataDir, filename);
  if (!fs.existsSync(filePath)) {
    console.log(`File not found: ${filePath}`);
    return;
  }

  const content = fs.readFileSync(filePath, 'utf-8');
  const lines = content.split('\n');

  const tableFiles = {};
  let currentTable = null;
  let currentStatement = [];

  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith(`INSERT INTO ${schemaName}.`)) {
      // Save previous statement
      if (currentTable && currentStatement.length > 0) {
        if (!tableFiles[currentTable]) {
          tableFiles[currentTable] = [];
        }
        tableFiles[currentTable].push(currentStatement.join('\n'));
      }
      
      // Find table name
      const match = line.match(new RegExp(`INSERT INTO ${schemaName}\\.(\\w+)`));
      if (match) {
        currentTable = match[1];
        currentStatement = [line];
      } else {
        currentTable = null;
        currentStatement = [];
      }
    } else {
      if (currentTable) {
        currentStatement.push(line);
      }
    }
  }

  // Save the last statement
  if (currentTable && currentStatement.length > 0) {
    if (!tableFiles[currentTable]) {
      tableFiles[currentTable] = [];
    }
    tableFiles[currentTable].push(currentStatement.join('\n'));
  }

  for (const [table, tableLines] of Object.entries(tableFiles)) {
    const outPath = path.join(splitDir, `${schemaName}_${table}.sql`);
    fs.writeFileSync(outPath, tableLines.join('\n') + '\n');
    console.log(`Created: ${outPath} (${tableLines.length} statements)`);
  }
}

splitFile('official_inserts.sql', 'official');
splitFile('ua_inserts.sql', 'ua');
