const axios = require('axios');
const cheerio = require('cheerio');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://dnd2024.wikidot.com';
const DELAY_MS = 250; // Delay between requests to avoid overloading the wiki
const CONCURRENCY_LIMIT = 5;

// Set up headers to look like a browser
const headers = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
};

// Sleep helper
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Directory for output data
const outputDir = path.join(__dirname, 'data');
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir);
}

// Fetch helper with retry logic
async function fetchPage(url) {
  let retries = 3;
  while (retries > 0) {
    try {
      await sleep(DELAY_MS);
      const fullUrl = url.startsWith('http') ? url : `${BASE_URL}${url}`;
      console.log(`Fetching: ${fullUrl}`);
      const response = await axios.get(fullUrl, { headers, timeout: 15000 });
      return cheerio.load(response.data);
    } catch (error) {
      retries--;
      console.warn(`Error fetching ${url}. Retries remaining: ${retries}. Message: ${error.message}`);
      if (retries === 0) throw error;
      await sleep(1000);
    }
  }
}

// Concurrency pool helper
async function poolLimit(array, limit, iteratorFn) {
  const ret = [];
  const executing = [];
  for (const item of array) {
    const p = Promise.resolve().then(() => iteratorFn(item));
    ret.push(p);
    if (limit <= array.length) {
      const e = p.then(() => executing.splice(executing.indexOf(e), 1));
      executing.push(e);
      if (executing.length >= limit) {
        await Promise.race(executing);
      }
    }
  }
  return Promise.all(ret);
}

// Clean text helper
function cleanText(text) {
  if (!text) return '';
  return text.trim().replace(/\s+/g, ' ').replace(/\n+/g, '\n');
}

// Scrape Spells
async function scrapeSpells(isUa = false) {
  const url = isUa ? '/ua:all' : '/spell:all';
  console.log(`\n--- SCRAPING ${isUa ? 'UA' : 'OFFICIAL'} SPELLS ---`);
  const $ = await fetchPage(url);
  
  const spellLinks = [];
  
  if (isUa) {
    // For UA, find links under Spells section
    // Spells section header is usually #toc87 (based on ua:all search)
    // We can find any links starting with /ua:spell-
    $('a').each((i, el) => {
      const href = $(el).attr('href');
      if (href && href.startsWith('/ua:spell-') && !href.includes('all')) {
        spellLinks.push({
          name: cleanText($(el).text()),
          url: href
        });
      }
    });
  } else {
    // For Official, parse the tabs and tables
    $('.wiki-content-table tr').each((i, el) => {
      const nameLink = $(el).find('td').first().find('a');
      const href = nameLink.attr('href');
      if (href && href.startsWith('/spell:')) {
        const name = cleanText(nameLink.text());
        const cols = $(el).find('td');
        if (cols.length >= 7) {
          spellLinks.push({
            name,
            url: href,
            school: cleanText($(cols[1]).text()),
            classesStr: cleanText($(cols[2]).text()),
            castingTime: cleanText($(cols[3]).text()),
            range: cleanText($(cols[4]).text()),
            components: cleanText($(cols[5]).text()),
            duration: cleanText($(cols[6]).text())
          });
        }
      }
    });
  }

  // Deduplicate links
  const uniqueSpells = [];
  const seenUrls = new Set();
  for (const s of spellLinks) {
    if (!seenUrls.has(s.url)) {
      seenUrls.add(s.url);
      uniqueSpells.push(s);
    }
  }

  console.log(`Found ${uniqueSpells.length} spells. Scraping details...`);
  
  const spellsData = [];
  
  await poolLimit(uniqueSpells, CONCURRENCY_LIMIT, async (spell) => {
    try {
      const $detail = await fetchPage(spell.url);
      const $ = $detail;
      const contentDiv = $detail('#page-content');
      
      // Parse tags
      const tags = [];
      $detail('.page-tags a').each((i, el) => {
        tags.push(cleanText($(el).text()));
      });

      // Parse metadata from page content
      let source = 'Player\'s Handbook';
      let descriptionHtml = '';
      let upgrades = '';
      
      const paragraphs = contentDiv.find('p');
      let startDesc = false;
      let descParas = [];
      
      let level = 0;
      let school = spell.school || '';
      let castingTime = spell.castingTime || '';
      let range = spell.range || '';
      let components = spell.components || '';
      let duration = spell.duration || '';
      let classes = [];

      paragraphs.each((idx, pEl) => {
        const rawText = $(pEl).text();
        const lines = rawText.split('\n').map(l => l.trim()).filter(l => l.length > 0);
        let isMetadataPara = false;

        for (const line of lines) {
          if (line.startsWith('Source:')) {
            source = line.replace('Source:', '').trim();
            isMetadataPara = true;
            continue;
          }

          const hasLevelInfo = (line.includes('Cantrip') || line.includes('Level') || line.includes('level')) &&
                               ('abjuration conjuration divination enchantment evocation illusion necromancy transmutation'.split(' ').some(s => line.toLowerCase().includes(s)));

          const hasMetadata = line.includes('Casting Time:') || line.includes('Range:') || line.includes('Components:') || line.includes('Duration:');

          if (hasLevelInfo) {
            isMetadataPara = true;
            const lvlMatch = line.match(/(\d+)(?:st|nd|rd|th)-[Ll]evel/) || line.match(/[Ll]evel\s+(\d+)/i);
            if (lvlMatch) {
              level = parseInt(lvlMatch[1]);
            } else if (line.includes('Cantrip') || line.includes('cantrip')) {
              level = 0;
            }
            const schools = ['Abjuration', 'Conjuration', 'Divination', 'Enchantment', 'Evocation', 'Illusion', 'Necromancy', 'Transmutation'];
            const foundSchool = schools.find(s => line.toLowerCase().includes(s.toLowerCase()));
            if (foundSchool) {
              school = foundSchool;
            }
            const classMatch = line.match(/\(([^)]+)\)/);
            if (classMatch) {
              classes = classMatch[1].split(',').map(c => c.trim());
            }
          }

          if (hasMetadata) {
            isMetadataPara = true;
            if (line.includes('Casting Time:')) {
              castingTime = line.replace('Casting Time:', '').trim();
            }
            if (line.includes('Range:')) {
              range = line.replace('Range:', '').trim();
            }
            if (line.includes('Components:')) {
              components = line.replace('Components:', '').trim();
            }
            if (line.includes('Duration:')) {
              duration = line.replace('Duration:', '').trim();
            }
            startDesc = true;
          }
        }

        if (!isMetadataPara && (startDesc || idx >= 2)) {
          const cleanP = cleanText($(pEl).text());
          if (cleanP.startsWith('Cantrip Upgrade.') || cleanP.startsWith('At Higher Levels.')) {
            upgrades = cleanP;
          } else if (cleanP.length > 0) {
            descParas.push(cleanP);
          }
        }
      });

      // Fallback classes from tag list
      if (classes.length === 0) {
        const standardClasses = ['artificer', 'bard', 'cleric', 'druid', 'fighter', 'monk', 'paladin', 'ranger', 'rogue', 'sorcerer', 'warlock', 'wizard'];
        classes = tags.filter(t => standardClasses.includes(t.toLowerCase())).map(c => c.charAt(0).toUpperCase() + c.slice(1));
      }

      const description = descParas.join('\n\n');
      
      spellsData.push({
        name: spell.name,
        level,
        school: school || 'Evocation',
        casting_time: castingTime || 'Action',
        range: range || '60 feet',
        components: components || 'V, S',
        duration: duration || 'Instantaneous',
        source,
        classes,
        description,
        upgrades: upgrades || null,
        legacy: false,
        tags
      });
    } catch (e) {
      console.error(`Failed to scrape spell ${spell.name}: ${e.message}`);
    }
  });

  return spellsData;
}

// Scrape Species
async function scrapeSpecies(isUa = false) {
  // UA species: usually listed on ua:all but there are very few UA species in 2024.
  // We will crawl species:all for official species.
  if (isUa) return []; // D&D 2024 UA doesn't have many separate species pages on this wiki, mostly official
  
  console.log(`\n--- SCRAPING OFFICIAL SPECIES ---`);
  const $ = await fetchPage('/species:all');
  
  const speciesLinks = [];
  $('.wiki-content-table tr a').each((i, el) => {
    const href = $(el).attr('href');
    if (href && href.startsWith('/species:') && !href.includes('all')) {
      speciesLinks.push({
        name: cleanText($(el).text()),
        url: href
      });
    }
  });

  console.log(`Found ${speciesLinks.length} species. Scraping details...`);
  
  const speciesData = [];
  
  await poolLimit(speciesLinks, CONCURRENCY_LIMIT, async (spec) => {
    try {
      const $detail = await fetchPage(spec.url);
      const $ = $detail;
      const contentDiv = $detail('#page-content');
      
      const tags = [];
      $detail('.page-tags a').each((i, el) => {
        tags.push(cleanText($(el).text()));
      });

      let source = 'Player\'s Handbook';
      let creatureType = 'Humanoid';
      let size = 'Medium';
      let speed = '30 feet';
      
      // Parse description, source, size, speed, traits
      const paragraphs = contentDiv.find('p');
      let descParas = [];
      const traits = [];
      
      paragraphs.each((idx, pEl) => {
        const text = cleanText($(pEl).text());
        if (text.startsWith('Source:')) {
          source = text.replace('Source:', '').trim();
        } else if (text.startsWith('Creature Type:')) {
          creatureType = text.replace('Creature Type:', '').trim();
        } else if (text.startsWith('Size:')) {
          size = text.replace('Size:', '').trim();
        } else if (text.startsWith('Speed:')) {
          speed = text.replace('Speed:', '').trim();
        } else if ($(pEl).find('strong').length > 0 && idx > 2) {
          // A trait is usually bolded at the beginning, like **Resourceful.** You gain...
          const strongText = cleanText($(pEl).find('strong').first().text());
          if (strongText.length > 2 && strongText.length < 30) {
            const desc = text.replace(strongText, '').trim();
            traits.push({
              name: strongText.replace(/\.$/, '').trim(),
              description: desc
            });
          } else {
            descParas.push(text);
          }
        } else {
          if (text.length > 0 && !text.startsWith('As a') && !text.startsWith('When you choose')) {
            descParas.push(text);
          }
        }
      });

      speciesData.push({
        name: spec.name,
        source,
        description: descParas.slice(0, 2).join('\n\n'),
        creature_type: creatureType,
        size,
        speed,
        traits,
        legacy: false,
        tags
      });
    } catch (e) {
      console.error(`Failed to scrape species ${spec.name}: ${e.message}`);
    }
  });

  return speciesData;
}

// Scrape Feats
async function scrapeFeats(isUa = false) {
  const url = isUa ? '/ua:all' : '/feat:all';
  console.log(`\n--- SCRAPING ${isUa ? 'UA' : 'OFFICIAL'} FEATS ---`);
  const $ = await fetchPage(url);
  
  const featLinks = [];
  
  if (isUa) {
    $('a').each((i, el) => {
      const href = $(el).attr('href');
      if (href && href.startsWith('/ua:feat-')) {
        featLinks.push({
          name: cleanText($(el).text()),
          url: href
        });
      }
    });
  } else {
    $('.wiki-content-table tr a').each((i, el) => {
      const href = $(el).attr('href');
      if (href && href.startsWith('/feat:') && !href.includes('all')) {
        featLinks.push({
          name: cleanText($(el).text()),
          url: href
        });
      }
    });
  }

  // Deduplicate
  const uniqueFeats = [];
  const seenUrls = new Set();
  for (const f of featLinks) {
    if (!seenUrls.has(f.url)) {
      seenUrls.add(f.url);
      uniqueFeats.push(f);
    }
  }

  console.log(`Found ${uniqueFeats.length} feats. Scraping details...`);
  
  const featsData = [];
  
  await poolLimit(uniqueFeats, CONCURRENCY_LIMIT, async (feat) => {
    try {
      const $detail = await fetchPage(feat.url);
      const $ = $detail;
      const contentDiv = $detail('#page-content');
      
      const tags = [];
      $detail('.page-tags a').each((i, el) => {
        tags.push(cleanText($(el).text()));
      });

      let source = 'Player\'s Handbook';
      let prerequisite = null;
      let category = isUa ? 'Playtest Feat' : 'General Feat';
      
      // Infer category from tags or headers
      if (tags.includes('originfeat')) category = 'Origin Feat';
      else if (tags.includes('generalfeat')) category = 'General Feat';
      else if (tags.includes('fightingstyle')) category = 'Fighting Style Feat';
      else if (tags.includes('epicboon')) category = 'Epic Boon Feat';

      const paragraphs = contentDiv.find('p');
      let descParas = [];
      const benefits = [];
      
      paragraphs.each((idx, pEl) => {
        const text = cleanText($(pEl).text());
        if (text.startsWith('Source:')) {
          source = text.replace('Source:', '').trim();
        } else if (text.startsWith('Prerequisite:')) {
          prerequisite = text.replace('Prerequisite:', '').trim();
        } else if ($(pEl).find('strong').length > 0 && idx > 1) {
          const strongText = cleanText($(pEl).find('strong').first().text());
          if (strongText.length > 2 && strongText.length < 35 && !strongText.startsWith('Source') && !strongText.startsWith('Prerequisite')) {
            const desc = text.replace(strongText, '').trim();
            benefits.push({
              name: strongText.replace(/\.$/, '').trim(),
              description: desc
            });
          } else {
            descParas.push(text);
          }
        } else {
          if (text.length > 0 && !text.startsWith('You gain the following')) {
            descParas.push(text);
          }
        }
      });

      let description = descParas.join('\n\n');
      if (!description && benefits.length > 0) {
        description = benefits.map(b => `${b.name}: ${b.description}`).join('\n\n');
      }

      featsData.push({
        name: feat.name,
        category,
        prerequisite,
        description,
        benefits,
        legacy: false,
        tags
      });
    } catch (e) {
      console.error(`Failed to scrape feat ${feat.name}: ${e.message}`);
    }
  });

  return featsData;
}

// Scrape Backgrounds
async function scrapeBackgrounds(isUa = false) {
  if (isUa) return []; // D&D 2024 playtest backgrounds are mostly in official now
  
  console.log(`\n--- SCRAPING OFFICIAL BACKGROUNDS ---`);
  const $ = await fetchPage('/background:all');
  
  const bgLinks = [];
  $('.wiki-content-table tr a').each((i, el) => {
    const href = $(el).attr('href');
    if (href && href.startsWith('/background:') && !href.includes('all')) {
      bgLinks.push({
        name: cleanText($(el).text()),
        url: href
      });
    }
  });

  console.log(`Found ${bgLinks.length} backgrounds. Scraping details...`);
  
  const backgroundsData = [];
  
  await poolLimit(bgLinks, CONCURRENCY_LIMIT, async (bg) => {
    try {
      const $detail = await fetchPage(bg.url);
      const $ = $detail;
      const contentDiv = $detail('#page-content');
      
      const tags = [];
      $detail('.page-tags a').each((i, el) => {
        tags.push(cleanText($(el).text()));
      });

      let source = 'Player\'s Handbook';
      let abilityScores = '';
      let feat = '';
      let skillProficiencies = '';
      let toolProficiencies = '';
      let equipment = '';
      
      const paragraphs = contentDiv.find('p');
      let descParas = [];
      
      paragraphs.each((idx, pEl) => {
        const text = cleanText($(pEl).text());
        if (text.startsWith('Source:')) {
          source = text.replace('Source:', '').trim();
        } else if (text.startsWith('Ability Scores:')) {
          abilityScores = text.replace('Ability Scores:', '').trim();
        } else if (text.startsWith('Feat:')) {
          feat = text.replace('Feat:', '').trim();
        } else if (text.startsWith('Skill Proficiencies:')) {
          skillProficiencies = text.replace('Skill Proficiencies:', '').trim();
        } else if (text.startsWith('Tool Proficiencies:')) {
          toolProficiencies = text.replace('Tool Proficiencies:', '').trim();
        } else if (text.startsWith('Equipment:')) {
          equipment = text.replace('Equipment:', '').trim();
        } else {
          if (text.length > 0) descParas.push(text);
        }
      });

      backgroundsData.push({
        name: bg.name,
        source,
        description: descParas.join('\n\n'),
        ability_scores: abilityScores,
        feat,
        skill_proficiencies: skillProficiencies,
        tool_proficiencies: toolProficiencies,
        equipment,
        legacy: false,
        tags
      });
    } catch (e) {
      console.error(`Failed to scrape background ${bg.name}: ${e.message}`);
    }
  });

  return backgroundsData;
}

// Scrape Classes & Subclasses
async function scrapeClasses(isUa = false) {
  // We'll scrape official classes directly
  const classesList = [
    { name: 'Artificer', url: '/artificer:main' },
    { name: 'Barbarian', url: '/barbarian:main' },
    { name: 'Bard', url: '/bard:main' },
    { name: 'Cleric', url: '/cleric:main' },
    { name: 'Druid', url: '/druid:main' },
    { name: 'Fighter', url: '/fighter:main' },
    { name: 'Monk', url: '/monk:main' },
    { name: 'Paladin', url: '/paladin:main' },
    { name: 'Ranger', url: '/ranger:main' },
    { name: 'Rogue', url: '/rogue:main' },
    { name: 'Sorcerer', url: '/sorcerer:main' },
    { name: 'Warlock', url: '/warlock:main' },
    { name: 'Wizard', url: '/wizard:main' }
  ];

  const uaClassesList = [
    { name: 'Artificer', url: '/ua:class-artificer' },
    { name: 'Artificer (UA3)', url: '/ua:class-artificer2' },
    { name: 'Psion', url: '/ua:class-psion' },
    { name: 'Psion (UA9)', url: '/ua:class-psion2' }
  ];

  const activeClasses = isUa ? uaClassesList : classesList;
  console.log(`\n--- SCRAPING ${isUa ? 'UA' : 'OFFICIAL'} CLASSES & SUBCLASSES ---`);
  
  const classesData = [];
  const subclassesData = [];
  
  for (const classItem of activeClasses) {
    try {
      const $ = await fetchPage(classItem.url);
      const contentDiv = $('#page-content');
      
      const tags = [];
      $('.page-tags a').each((i, el) => {
        tags.push(cleanText($(el).text()));
      });

      let source = isUa ? 'Unearthed Arcana' : 'Player\'s Handbook';
      let primaryAbility = 'Strength';
      let savingThrows = [];
      let hitDice = '1d10';
      let weaponProf = [];
      let armorProf = [];
      let toolProf = [];
      let skillProf = [];
      let classTable = { headers: [], rows: [] };

      // Parse Traits and Features Tables
      const tables = contentDiv.find('table');
      tables.each((tableIdx, tableEl) => {
        const $table = $(tableEl);
        const firstHeader = $table.find('th').first().text().trim();

        if (firstHeader.includes('Core') && firstHeader.includes('Traits')) {
          $table.find('tr').each((rowIdx, trEl) => {
            const cells = $(trEl).find('td');
            if (cells.length >= 2) {
              const label = $(cells[0]).text().trim();
              const value = $(cells[1]).text().trim();

              const cleanList = (val) => {
                return val.split(/,|\band\b/i)
                  .map(x => x.trim())
                  .filter(x => x.length > 0 && x.toLowerCase() !== 'none');
              };

              if (label.includes('Primary Ability')) {
                primaryAbility = value;
              } else if (label.includes('Hit Point Die') || label.includes('Hit Die')) {
                hitDice = value.match(/D\d+/i) ? value.match(/D\d+/i)[0].toLowerCase() : value;
              } else if (label.includes('Saving Throw')) {
                savingThrows = cleanList(value);
              } else if (label.includes('Weapon')) {
                weaponProf = cleanList(value);
              } else if (label.includes('Armor')) {
                armorProf = cleanList(value);
              } else if (label.includes('Tool')) {
                toolProf = cleanList(value);
              } else if (label.includes('Skill')) {
                skillProf = cleanList(value);
              }
            }
          });
        }

        const headers = [];
        $table.find('tr').first().find('th, td').each((colIdx, cellEl) => {
          headers.push($(cellEl).text().trim());
        });

        if (headers.includes('Level') && (headers.includes('Features') || headers.includes('Class Features') || headers.includes('Feature'))) {
          classTable.headers = headers;
          $table.find('tr').slice(1).each((rowIdx, trEl) => {
            const row = [];
            $(trEl).find('td').each((colIdx, cellEl) => {
              row.push($(cellEl).text().trim());
            });
            if (row.length > 0) {
              classTable.rows.push(row);
            }
          });
        }
      });

      // Parse descriptions and features
      let firstHeadingHit = false;
      const descParas = [];
      let features = [];
      let currentFeature = null;

      contentDiv.children().each((idx, el) => {
        const tag = el.name;
        const $el = $(el);

        if (tag === 'h1' || tag === 'h2' || tag === 'h3' || tag === 'h4' || tag === 'h5') {
          firstHeadingHit = true;
          const text = $el.text().trim();
          const lvlMatch = text.match(/Level\s+(\d+)\s*:\s*(.*)/i);
          if (lvlMatch) {
            if (currentFeature) {
              features.push(currentFeature);
            }
            currentFeature = {
              name: lvlMatch[2].trim(),
              level: parseInt(lvlMatch[1]),
              description_paragraphs: []
            };
          } else if (currentFeature) {
            features.push(currentFeature);
            currentFeature = null;
          }
        } else {
          if (!firstHeadingHit) {
            if (tag === 'p') {
              const text = $el.text().trim();
              if (text.startsWith('Source:')) {
                source = text.replace('Source:', '').trim();
              } else if (text.length > 0) {
                descParas.push(text);
              }
            }
          } else if (currentFeature) {
            if (tag === 'p') {
              const text = $el.text().trim();
              if (text.length > 0 && !text.startsWith('Source:')) {
                currentFeature.description_paragraphs.push(text);
              }
            } else if (tag === 'ul' || tag === 'ol') {
              const listItems = [];
              $el.find('li').each((j, liEl) => {
                listItems.push('• ' + $(liEl).text().trim());
              });
              if (listItems.length > 0) {
                currentFeature.description_paragraphs.push(listItems.join('\n'));
              }
            }
          }
        }
      });

      if (currentFeature) {
        features.push(currentFeature);
      }

      const parsedFeatures = features.map(f => ({
        name: f.name,
        level: f.level,
        description: f.description_paragraphs.join('\n\n')
      }));

      const subclassLinks = [];
      contentDiv.find('table.wiki-content-table a').each((i, el) => {
        const href = $(el).attr('href');
        const name = cleanText($(el).text());
        if (href) {
          const lowerHref = href.toLowerCase();
          const cleanClassName = classItem.name.toLowerCase().replace(/[^a-z0-9]/g, '');
          
          // Match if the URL contains class name (e.g., /fighter:champion)
          const isClassRelated = lowerHref.includes(`${cleanClassName}:`) ||
                                 (cleanClassName === 'sorcerer' && lowerHref.includes('sorcerer:')) ||
                                 (cleanClassName === 'warlock' && lowerHref.includes('patron')) ||
                                 (cleanClassName === 'wizard' && (lowerHref.includes('school') || lowerHref.includes('abjurer') || lowerHref.includes('diviner') || lowerHref.includes('evoker') || lowerHref.includes('illusionist')));
                                 
          const isGenericSubclass = lowerHref.includes('subclass') || 
                                    lowerHref.includes('patron') || 
                                    lowerHref.includes('college') || 
                                    lowerHref.includes('domain') || 
                                    lowerHref.includes('circle') || 
                                    lowerHref.includes('path') || 
                                    lowerHref.includes('way') || 
                                    lowerHref.includes('oath');

          if (isClassRelated || isGenericSubclass) {
            subclassLinks.push({ name, url: href });
          }
        }
      });

      // Deduplicate subclass links
      const uniqueSubclassLinks = [];
      const seenSubUrls = new Set();
      for (const s of subclassLinks) {
        if (!seenSubUrls.has(s.url)) {
          seenSubUrls.add(s.url);
          uniqueSubclassLinks.push(s);
        }
      }

      console.log(`Class ${classItem.name}: Found ${uniqueSubclassLinks.length} subclasses. Scraping subclasses...`);

      // Parse each subclass
      for (const subLink of uniqueSubclassLinks) {
        try {
          const $sub = await fetchPage(subLink.url);
          const subContent = $sub('#page-content');
          
          const subTags = [];
          $sub('.page-tags a').each((i, el) => {
            subTags.push(cleanText($sub(el).text()));
          });

          let subSource = source;
          let firstSubHeadingHit = false;
          const subDescParas = [];
          const subFeatures = [];
          let currentSubFeature = null;

          subContent.children().each((i, el) => {
            const tag = el.name;
            const $el = $sub(el);

            if (tag === 'h1' || tag === 'h2' || tag === 'h3' || tag === 'h4' || tag === 'h5') {
              firstSubHeadingHit = true;
              const text = $el.text().trim();
              const lvlMatch = text.match(/Level\s+(\d+)\s*:\s*(.*)/i);
              if (lvlMatch) {
                if (currentSubFeature) {
                  subFeatures.push(currentSubFeature);
                }
                currentSubFeature = {
                  name: lvlMatch[2].trim(),
                  level: parseInt(lvlMatch[1]),
                  description_paragraphs: []
                };
              } else if (currentSubFeature) {
                subFeatures.push(currentSubFeature);
                currentSubFeature = null;
              }
            } else {
              if (!firstSubHeadingHit) {
                if (tag === 'p') {
                  const text = $el.text().trim();
                  if (text.startsWith('Source:')) {
                    subSource = text.replace('Source:', '').trim();
                  } else if (text.length > 0) {
                    subDescParas.push(text);
                  }
                }
              } else if (currentSubFeature) {
                if (tag === 'p') {
                  const text = $el.text().trim();
                  if (text.length > 0 && !text.startsWith('Source:')) {
                    currentSubFeature.description_paragraphs.push(text);
                  }
                } else if (tag === 'ul' || tag === 'ol') {
                  const listItems = [];
                  $el.find('li').each((j, liEl) => {
                    listItems.push('• ' + $sub(liEl).text().trim());
                  });
                  if (listItems.length > 0) {
                    currentSubFeature.description_paragraphs.push(listItems.join('\n'));
                  }
                }
              }
            }
          });

          if (currentSubFeature) {
            subFeatures.push(currentSubFeature);
          }

          const parsedSubFeatures = subFeatures.map(sf => ({
            name: sf.name,
            level: sf.level,
            description: sf.description_paragraphs.join('\n\n')
          }));

          subclassesData.push({
            class_name: classItem.name,
            name: subLink.name,
            source: subSource,
            description: subDescParas.join('\n\n'),
            features: parsedSubFeatures,
            legacy: false,
            tags: subTags
          });
        } catch (subErr) {
          console.error(`Failed to scrape subclass ${subLink.name}: ${subErr.message}`);
        }
      }

      classesData.push({
        name: classItem.name,
        source,
        description: descParas.join('\n\n'),
        primary_ability: primaryAbility || 'Strength',
        saving_throws: savingThrows,
        hit_dice: hitDice || '1d10',
        weapon_proficiencies: weaponProf,
        armor_proficiencies: armorProf,
        tool_proficiencies: toolProf,
        skill_proficiencies: skillProf,
        class_table: classTable,
        features: parsedFeatures,
        legacy: false,
        tags
      });
    } catch (e) {
      console.error(`Failed to scrape class ${classItem.name}: ${e.message}`);
    }
  }

  // Also parse UA subclasses listed in ua:all directly
  if (isUa) {
    const $ua = await fetchPage('/ua:all');
    const uaSubclassLinks = [];
    
    $ua('a').each((i, el) => {
      const href = $ua(el).attr('href');
      if (href && href.startsWith('/ua:subclass-')) {
        uaSubclassLinks.push({
          name: cleanText($ua(el).text()),
          url: href
        });
      }
    });

    console.log(`Found ${uaSubclassLinks.length} standalone UA subclasses. Scraping details...`);
    
    for (const subLink of uaSubclassLinks) {
      if (subclassesData.some(s => s.name === subLink.name)) continue;

      try {
        const $sub = await fetchPage(subLink.url);
        const subContent = $sub('#page-content');
        
        const subTags = [];
        $sub('.page-tags a').each((i, el) => {
          subTags.push(cleanText($sub(el).text()));
        });

        let className = 'Fighter';
        const urlLower = subLink.url.toLowerCase();
        if (urlLower.includes('artificer')) className = 'Artificer';
        else if (urlLower.includes('barbarian')) className = 'Barbarian';
        else if (urlLower.includes('bard')) className = 'Bard';
        else if (urlLower.includes('cleric')) className = 'Cleric';
        else if (urlLower.includes('druid')) className = 'Druid';
        else if (urlLower.includes('monk')) className = 'Monk';
        else if (urlLower.includes('paladin')) className = 'Paladin';
        else if (urlLower.includes('ranger')) className = 'Ranger';
        else if (urlLower.includes('rogue')) className = 'Rogue';
        else if (urlLower.includes('sorcerer')) className = 'Sorcerer';
        else if (urlLower.includes('warlock')) className = 'Warlock';
        else if (urlLower.includes('wizard')) className = 'Wizard';
        else if (urlLower.includes('psion')) className = 'Psion';

        let subSource = 'Unearthed Arcana';
        let firstSubHeadingHit = false;
        const subDescParas = [];
        const subFeatures = [];
        let currentSubFeature = null;

        subContent.children().each((i, el) => {
          const tag = el.name;
          const $el = $sub(el);

          if (tag === 'h1' || tag === 'h2' || tag === 'h3' || tag === 'h4' || tag === 'h5') {
            firstSubHeadingHit = true;
            const text = $el.text().trim();
            const lvlMatch = text.match(/Level\s+(\d+)\s*:\s*(.*)/i);
            if (lvlMatch) {
              if (currentSubFeature) {
                subFeatures.push(currentSubFeature);
              }
              currentSubFeature = {
                name: lvlMatch[2].trim(),
                level: parseInt(lvlMatch[1]),
                description_paragraphs: []
              };
            } else if (currentSubFeature) {
              subFeatures.push(currentSubFeature);
              currentSubFeature = null;
            }
          } else {
            if (!firstSubHeadingHit) {
              if (tag === 'p') {
                const text = $el.text().trim();
                if (text.startsWith('Source:')) {
                  subSource = text.replace('Source:', '').trim();
                } else if (text.length > 0) {
                  subDescParas.push(text);
                }
              }
            } else if (currentSubFeature) {
              if (tag === 'p') {
                const text = $el.text().trim();
                if (text.length > 0 && !text.startsWith('Source:')) {
                  currentSubFeature.description_paragraphs.push(text);
                }
              } else if (tag === 'ul' || tag === 'ol') {
                const listItems = [];
                $el.find('li').each((j, liEl) => {
                  listItems.push('• ' + $sub(liEl).text().trim());
                });
                if (listItems.length > 0) {
                  currentSubFeature.description_paragraphs.push(listItems.join('\n'));
                }
              }
            }
          }
        });

        if (currentSubFeature) {
          subFeatures.push(currentSubFeature);
        }

        const parsedSubFeatures = subFeatures.map(sf => ({
          name: sf.name,
          level: sf.level,
          description: sf.description_paragraphs.join('\n\n')
        }));

        subclassesData.push({
          class_name: className,
          name: subLink.name,
          source: subSource,
          description: subDescParas.join('\n\n'),
          features: parsedSubFeatures,
          legacy: false,
          tags: subTags
        });
      } catch (err) {
        console.error(`Failed to scrape standalone UA subclass ${subLink.name}: ${err.message}`);
      }
    }
  }

  return { classes: classesData, subclasses: subclassesData };
}

// Scrape Equipment
async function scrapeEquipment() {
  console.log(`\n--- SCRAPING EQUIPMENT ---`);
  
  const equipmentData = [];
  
  // We'll scrape weapons page directly because it has all weapons in clean tables
  try {
    const $ = await fetchPage('/equipment:weapon');
    
    // Parse Weapons table
    $('.wiki-content-table tr').each((i, el) => {
      const nameLink = $(el).find('td').first().find('a');
      if (nameLink.length > 0) {
        const name = cleanText(nameLink.text());
        const cols = $(el).find('td');
        if (cols.length >= 6) {
          const damage = cleanText($(cols[1]).text());
          const propertiesStr = cleanText($(cols[2]).text());
          const mastery = cleanText($(cols[3]).text());
          const weight = cleanText($(cols[4]).text());
          const cost = cleanText($(cols[5]).text());
          
          const properties = propertiesStr.split(',').map(p => p.trim()).filter(p => p !== '—' && p.length > 0);
          
          equipmentData.push({
            name,
            category: 'Weapon',
            sub_category: i < 20 ? 'Simple Weapon' : 'Martial Weapon',
            cost,
            weight,
            damage,
            properties,
            mastery,
            description: `A weapon dealing ${damage}. Mastery: ${mastery}. Properties: ${propertiesStr}`,
            legacy: false,
            tags: ['weapon', i < 20 ? 'simple' : 'martial']
          });
        }
      }
    });
  } catch (e) {
    console.error(`Failed to scrape weapons: ${e.message}`);
  }

  // Parse Armor page
  try {
    const $ = await fetchPage('/equipment:armor');
    
    $('.wiki-content-table tr').each((i, el) => {
      const nameLink = $(el).find('td').first().find('a');
      if (nameLink.length > 0) {
        const name = cleanText(nameLink.text());
        const cols = $(el).find('td');
        if (cols.length >= 5) {
          const cost = cleanText($(cols[1]).text());
          const ac = cleanText($(cols[2]).text());
          const strength = cleanText($(cols[3]).text());
          const stealth = cleanText($(cols[4]).text());
          const weight = cols.length >= 6 ? cleanText($(cols[5]).text()) : '';
          
          equipmentData.push({
            name,
            category: 'Armor',
            sub_category: 'Armor',
            cost,
            weight,
            damage: null,
            properties: [`AC: ${ac}`, `Stealth: ${stealth}`, `Req Strength: ${strength}`],
            mastery: null,
            description: `Armor giving AC ${ac}. Stealth: ${stealth}. Strength required: ${strength}`,
            legacy: false,
            tags: ['armor']
          });
        }
      }
    });
  } catch (e) {
    console.error(`Failed to scrape armor: ${e.message}`);
  }

  // Parse Tools page
  try {
    const $ = await fetchPage('/equipment:tool');
    $('.wiki-content-table tr').each((i, el) => {
      const nameCol = $(el).find('td').first();
      const cols = $(el).find('td');
      if (cols.length >= 3) {
        const name = cleanText(nameCol.text());
        const cost = cleanText($(cols[1]).text());
        const weight = cleanText($(cols[2]).text());
        
        if (name && name !== 'Item' && name.length < 40) {
          equipmentData.push({
            name,
            category: 'Tool',
            sub_category: 'Tool',
            cost,
            weight,
            damage: null,
            properties: [],
            mastery: null,
            description: `A tool set/kit used for crafting or checks.`,
            legacy: false,
            tags: ['tool']
          });
        }
      }
    });
  } catch (e) {
    console.error(`Failed to scrape tools: ${e.message}`);
  }

  return equipmentData;
}

// Scrape Magic Items
async function scrapeMagicItems(isUa = false) {
  const url = isUa ? '/ua:all' : '/magic-item:all';
  console.log(`\n--- SCRAPING ${isUa ? 'UA' : 'OFFICIAL'} MAGIC ITEMS ---`);
  const $ = await fetchPage(url);
  
  const itemLinks = [];
  
  if (isUa) {
    $('a').each((i, el) => {
      const href = $(el).attr('href');
      if (href && href.startsWith('/ua:magic-item-')) {
        itemLinks.push({
          name: cleanText($(el).text()),
          url: href
        });
      }
    });
  } else {
    $('.wiki-content-table tr a').each((i, el) => {
      const href = $(el).attr('href');
      if (href && href.startsWith('/magic-item:') && !href.includes('all') && !href.includes('crafting') && !href.includes('consumable')) {
        itemLinks.push({
          name: cleanText($(el).text()),
          url: href
        });
      }
    });
  }

  // Deduplicate
  const uniqueItems = [];
  const seenUrls = new Set();
  for (const item of itemLinks) {
    if (!seenUrls.has(item.url)) {
      seenUrls.add(item.url);
      uniqueItems.push(item);
    }
  }

  console.log(`Found ${uniqueItems.length} magic items. Scraping details...`);
  
  const itemsData = [];
  
  await poolLimit(uniqueItems, CONCURRENCY_LIMIT, async (item) => {
    try {
      const $detail = await fetchPage(item.url);
      const $ = $detail;
      const contentDiv = $detail('#page-content');
      
      const tags = [];
      $detail('.page-tags a').each((i, el) => {
        tags.push(cleanText($(el).text()));
      });

      let type = 'Wondrous Item';
      let rarity = 'Uncommon';
      let attunement = 'No';
      let price = '';
      
      // Extract properties from content
      // usually looks like "Wondrous Item, Uncommon" or "Weapon (longsword), Rare (requires attunement)"
      const paragraphs = contentDiv.find('p');
      let descParas = [];
      
      paragraphs.each((idx, pEl) => {
        const text = cleanText($(pEl).text());
        if (text.startsWith('Source:')) {
          // Skip
        } else if ($(pEl).find('em').length > 0 && idx < 3 && (text.includes('Item') || text.includes('Armor') || text.includes('Weapon') || text.includes('Ring') || text.includes('Potion') || text.includes('Scroll') || text.includes('Wand') || text.includes('Staff'))) {
          // Parse type line like "Wondrous Item, Uncommon (requires attunement)"
          const parts = text.split(',');
          type = parts[0].trim();
          
          if (parts.length > 1) {
            const secondPart = parts[1].trim();
            if (secondPart.includes('(')) {
              rarity = secondPart.split('(')[0].trim();
              attunement = secondPart.includes('attunement') ? 'Required' : 'No';
            } else {
              rarity = secondPart;
            }
          }
        } else {
          if (text.length > 0) descParas.push(text);
        }
      });

      // Price fallback if not parsed
      if (tags.includes('common')) rarity = 'Common';
      else if (tags.includes('uncommon')) rarity = 'Uncommon';
      else if (tags.includes('rare')) rarity = 'Rare';
      else if (tags.includes('very-rare')) rarity = 'Very Rare';
      else if (tags.includes('legendary')) rarity = 'Legendary';
      else if (tags.includes('artifact')) rarity = 'Artifact';

      itemsData.push({
        name: item.name,
        type,
        rarity,
        attunement,
        price: price || 'Varies',
        description: descParas.join('\n\n'),
        legacy: false,
        tags
      });
    } catch (e) {
      console.error(`Failed to scrape magic item ${item.name}: ${e.message}`);
    }
  });

  return itemsData;
}

// Generate SQL statements
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
        // Handle array of strings or json array
        if (col === 'classes' || col === 'saving_throws' || col === 'weapon_proficiencies' || col === 'armor_proficiencies' || col === 'tool_proficiencies' || col === 'skill_proficiencies' || col === 'properties' || col === 'tags') {
          // Format as PostgreSQL array literal, escaping single quotes
          const escapedArr = val.map(v => `"${v.replace(/"/g, '\\"').replace(/'/g, "''")}"`);
          values.push(`ARRAY[${val.map(v => `'${v.replace(/'/g, "''")}'`).join(', ')}]::TEXT[]`);
        } else {
          // Format as JSONB
          const jsonStr = JSON.stringify(val).replace(/'/g, "''");
          values.push(`'${jsonStr}'::jsonb`);
        }
      } else if (typeof val === 'object') {
        const jsonStr = JSON.stringify(val).replace(/'/g, "''");
        values.push(`'${jsonStr}'::jsonb`);
      } else {
        // String escaping
        const escapedStr = val.replace(/'/g, "''");
        values.push(`'${escapedStr}'`);
      }
    }
    
    // We use INSERT INTO ON CONFLICT DO UPDATE to make this script idempotent
    const conflictCol = 'name';
    const updateSets = columns
      .filter(c => c !== 'id' && c !== 'name')
      .map(c => `${c} = EXCLUDED.${c}`)
      .join(', ');
      
    sql += `INSERT INTO ${schema}.${table} (${columns.join(', ')}) VALUES (${values.join(', ')}) ON CONFLICT (${conflictCol}) DO UPDATE SET ${updateSets};\n`;
  }
  
  return sql;
}

// Main runner
async function main() {
  console.log('--- STARTING D&D 2024 CRAWLER & SCRAPER ---');
  
  try {
    // 1. Scrape Official Content
    const officialSpells = await scrapeSpells(false);
    const officialSpecies = JSON.parse(fs.readFileSync(path.join(outputDir, 'official_species.json'), 'utf8'));
    const officialFeats = JSON.parse(fs.readFileSync(path.join(outputDir, 'official_feats.json'), 'utf8'));
    const officialBackgrounds = JSON.parse(fs.readFileSync(path.join(outputDir, 'official_backgrounds.json'), 'utf8'));
    console.log('\nScraping Official Classes & Subclasses...');
    const { classes: officialClasses, subclasses: officialSubclasses } = await scrapeClasses(false);
    const officialEquipment = JSON.parse(fs.readFileSync(path.join(outputDir, 'official_equipment.json'), 'utf8'));
    const officialMagicItems = JSON.parse(fs.readFileSync(path.join(outputDir, 'official_magic_items.json'), 'utf8'));
    
    // Write JSON files for backup
    fs.writeFileSync(path.join(outputDir, 'official_spells.json'), JSON.stringify(officialSpells, null, 2));
    fs.writeFileSync(path.join(outputDir, 'official_species.json'), JSON.stringify(officialSpecies, null, 2));
    fs.writeFileSync(path.join(outputDir, 'official_feats.json'), JSON.stringify(officialFeats, null, 2));
    fs.writeFileSync(path.join(outputDir, 'official_backgrounds.json'), JSON.stringify(officialBackgrounds, null, 2));
    fs.writeFileSync(path.join(outputDir, 'official_classes.json'), JSON.stringify(officialClasses, null, 2));
    fs.writeFileSync(path.join(outputDir, 'official_subclasses.json'), JSON.stringify(officialSubclasses, null, 2));
    fs.writeFileSync(path.join(outputDir, 'official_equipment.json'), JSON.stringify(officialEquipment, null, 2));
    fs.writeFileSync(path.join(outputDir, 'official_magic_items.json'), JSON.stringify(officialMagicItems, null, 2));
    
    // 2. Scrape UA Content
    const uaSpells = await scrapeSpells(true);
    const uaFeats = JSON.parse(fs.readFileSync(path.join(outputDir, 'ua_feats.json'), 'utf8'));
    console.log('\nScraping UA Classes & Subclasses...');
    const { classes: uaClasses, subclasses: uaSubclasses } = await scrapeClasses(true);
    const uaMagicItems = JSON.parse(fs.readFileSync(path.join(outputDir, 'ua_magic_items.json'), 'utf8'));
    
    // 3. Resolve Legacies (if UA version is also in Official, or if it is superseded by a newer UA version)
    // Create lookup sets of official names
    const officialSpellNames = new Set(officialSpells.map(s => s.name.toLowerCase()));
    const officialFeatNames = new Set(officialFeats.map(f => f.name.toLowerCase()));
    const officialClassNames = new Set(officialClasses.map(c => c.name.toLowerCase()));
    const officialSubclassNames = new Set(officialSubclasses.map(s => s.name.toLowerCase()));
    const officialMagicItemNames = new Set(officialMagicItems.map(i => i.name.toLowerCase()));

    function getBaseName(name) {
      return name
        .replace(/\s*\([^)]*\)/g, '')
        .replace(/\s*UA\d*/i, '')
        .replace(/\s*Playtest\d*/i, '')
        .replace(/\s*\(2024\)/i, '')
        .trim()
        .toLowerCase();
    }

    // Flag UA spells
    for (const spell of uaSpells) {
      const baseName = getBaseName(spell.name);
      if (officialSpellNames.has(baseName) || officialSpellNames.has(spell.name.toLowerCase())) {
        spell.legacy = true;
      }
      // Compare duplicates in UA e.g. Tasha's Mind Whip UA5 vs Tasha's Mind Whip UA9 (the older becomes legacy)
      // Check if there is another spell in UA with same name but higher version
      const newerUaExists = uaSpells.some(s => s.name.toLowerCase() === spell.name.toLowerCase() && s.tags.includes('ua9') && spell.tags.includes('ua5'));
      if (newerUaExists) spell.legacy = true;
    }
    
    // Flag UA feats
    for (const feat of uaFeats) {
      const baseName = getBaseName(feat.name);
      if (officialFeatNames.has(baseName) || officialFeatNames.has(feat.name.toLowerCase())) {
        feat.legacy = true;
      }
      const newerUaExists = uaFeats.some(f => f.name.toLowerCase() === feat.name.toLowerCase() && f.tags.includes('ua9') && feat.tags.includes('ua5'));
      if (newerUaExists) feat.legacy = true;
    }

    // Flag UA classes
    for (const cls of uaClasses) {
      const baseName = getBaseName(cls.name);
      if (officialClassNames.has(baseName) || officialClassNames.has(cls.name.toLowerCase())) {
        cls.legacy = true;
      }
      // Older UA version legacy
      const newerUaExists = uaClasses.some(c => c.name.toLowerCase() === cls.name.toLowerCase() && c.name.includes('UA9') && cls.name.includes('UA3'));
      if (newerUaExists) cls.legacy = true;
    }

    // Flag UA subclasses
    for (const sub of uaSubclasses) {
      const baseName = getBaseName(sub.name);
      if (officialSubclassNames.has(baseName) || officialSubclassNames.has(sub.name.toLowerCase())) {
        sub.legacy = true;
      }
      const newerUaExists = uaSubclasses.some(s => s.name.toLowerCase() === sub.name.toLowerCase() && s.name.includes('2') && sub.name.includes('1'));
      if (newerUaExists) sub.legacy = true;
    }

    // Flag UA magic items
    for (const item of uaMagicItems) {
      const baseName = getBaseName(item.name);
      if (officialMagicItemNames.has(baseName) || officialMagicItemNames.has(item.name.toLowerCase())) {
        item.legacy = true;
      }
    }

    // Write UA JSON files for backup
    fs.writeFileSync(path.join(outputDir, 'ua_spells.json'), JSON.stringify(uaSpells, null, 2));
    fs.writeFileSync(path.join(outputDir, 'ua_feats.json'), JSON.stringify(uaFeats, null, 2));
    fs.writeFileSync(path.join(outputDir, 'ua_classes.json'), JSON.stringify(uaClasses, null, 2));
    fs.writeFileSync(path.join(outputDir, 'ua_subclasses.json'), JSON.stringify(uaSubclasses, null, 2));
    fs.writeFileSync(path.join(outputDir, 'ua_magic_items.json'), JSON.stringify(uaMagicItems, null, 2));

    // 4. Generate SQL Scripts
    console.log('\nGenerating SQL scripts...');
    
    // Official SQL
    let officialSql = '';
    officialSql += generateSQL(officialSpells, 'official', 'spells');
    officialSql += generateSQL(officialSpecies, 'official', 'species');
    officialSql += generateSQL(officialFeats, 'official', 'feats');
    officialSql += generateSQL(officialBackgrounds, 'official', 'backgrounds');
    officialSql += generateSQL(officialClasses, 'official', 'classes');
    officialSql += generateSQL(officialSubclasses, 'official', 'subclasses');
    officialSql += generateSQL(officialEquipment, 'official', 'equipment');
    officialSql += generateSQL(officialMagicItems, 'official', 'magic_items');
    fs.writeFileSync(path.join(outputDir, 'official_inserts.sql'), officialSql);
    
    // UA SQL
    let uaSql = '';
    uaSql += generateSQL(uaSpells, 'ua', 'spells');
    uaSql += generateSQL(uaFeats, 'ua', 'feats');
    uaSql += generateSQL(uaClasses, 'ua', 'classes');
    uaSql += generateSQL(uaSubclasses, 'ua', 'subclasses');
    uaSql += generateSQL(uaMagicItems, 'ua', 'magic_items');
    fs.writeFileSync(path.join(outputDir, 'ua_inserts.sql'), uaSql);
    
    console.log(`\n--- SCRAPING COMPLETED SUCCESSFULLY ---`);
    console.log(`JSON and SQL outputs saved to: ${outputDir}`);
    
  } catch (err) {
    console.error('Fatal error during scraping main execution:', err);
  }
}

main();
