const fs = require('fs');
const path = require('path');

const metamagicFilePath = 'C:/Users/Emanu/.gemini/antigravity/brain/9021feba-e2d8-4f6a-9292-97cbc29bb9f4/.system_generated/steps/1993/content.md';
const featsJsonPath = 'C:/Users/Emanu/.gemini/antigravity/scratch/data/official_feats.json';

function run() {
  if (!fs.existsSync(metamagicFilePath)) {
    console.error('Metamagic source file not found at:', metamagicFilePath);
    return;
  }
  if (!fs.existsSync(featsJsonPath)) {
    console.error('feats.json not found at:', featsJsonPath);
    return;
  }

  const content = fs.readFileSync(metamagicFilePath, 'utf8');

  // We find the page-content section
  const startIdx = content.indexOf('<div id="page-content">');
  const endIdx = content.lastIndexOf('<div id="wad-tier3-below-content">');
  if (startIdx === -1) {
    console.error('Could not find page-content container');
    return;
  }
  
  const pageContentHtml = content.substring(startIdx, endIdx !== -1 ? endIdx : content.length);

  // Parse h3 blocks
  // An h3 block starts with <h3 id="toc\d+"><span>Name</span></h3>
  // Followed by <p>Source: ...<br /> Cost: ...</p>
  // Followed by description paragraphs <p>...</p>
  const h3Regex = /<h3[^>]*><span>([^<]+)<\/span><\/h3>([\s\S]*?)(?=<h3|$)/g;
  const metamagicFeats = [];
  let match;

  while ((match = h3Regex.exec(pageContentHtml)) !== null) {
    const name = match[1].trim();
    const sectionHtml = match[2];

    // Extract cost
    let costText = '1 Sorcery Point';
    const costMatch = sectionHtml.match(/Cost:\s*([^<]+)/i);
    if (costMatch) {
      costText = costMatch[1].replace(/<\/p>/i, '').trim();
    }

    // Extract description paragraphs
    const pRegex = /<p[^>]*>([\s\S]*?)<\/p>/gi;
    let pMatch;
    const descriptionParas = [];

    while ((pMatch = pRegex.exec(sectionHtml)) !== null) {
      const pText = pMatch[1]
        .replace(/<br\s*\/?>/gi, '\n')
        .replace(/<[^>]+>/g, '') // remove remaining HTML tags
        .trim();
      
      if (pText.startsWith('Source:') || pText.toLowerCase().startsWith('cost:')) {
        continue;
      }
      if (pText.length > 0) {
        descriptionParas.push(pText);
      }
    }

    const description = `Cost: ${costText}\n\n` + descriptionParas.join('\n\n');

    metamagicFeats.push({
      name: name,
      category: 'Metamagic Option',
      prerequisite: 'Sorcerer Level 2',
      description: description,
      benefits: [
        {
          name: 'Cost',
          description: costText
        }
      ],
      legacy: false,
      tags: ['metamagic', 'sorcerer']
    });
  }

  console.log(`Parsed ${metamagicFeats.length} Metamagic options.`);
  if (metamagicFeats.length === 0) {
    console.warn('Warning: parsed 0 items. Check pageContentHtml or regex.');
  } else {
    for (const f of metamagicFeats) {
      console.log(`  - ${f.name} (${f.benefits[0].description})`);
    }
  }

  // Load official_feats.json
  const feats = JSON.parse(fs.readFileSync(featsJsonPath, 'utf8'));
  console.log(`Loaded ${feats.length} existing feats.`);

  // Filter out any existing metamagic options to prevent duplicates
  const filteredFeats = feats.filter(f => f.category !== 'Metamagic Option' && !f.tags.includes('metamagic'));

  // Append new ones
  const updatedFeats = [...filteredFeats, ...metamagicFeats];
  console.log(`Saving ${updatedFeats.length} feats (added ${metamagicFeats.length} Metamagic options)...`);

  fs.writeFileSync(featsJsonPath, JSON.stringify(updatedFeats, null, 2));
  console.log('Successfully updated official_feats.json!');
}

run();
