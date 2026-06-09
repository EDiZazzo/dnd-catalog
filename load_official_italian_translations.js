const ACCESS_TOKEN = process.env.SUPABASE_ACCESS_TOKEN || '';
const PROJECT_ID = 'xculeusuctxdujcevnwv';
const ENDPOINT = `https://api.supabase.com/v1/projects/${PROJECT_ID}/database/query`;

// Official translation maps
const categories = {
  class: {
    "Barbarian": "Barbaro",
    "Bard": "Bardo",
    "Cleric": "Chierico",
    "Druid": "Druido",
    "Fighter": "Guerriero",
    "Monk": "Monaco",
    "Paladin": "Paladino",
    "Ranger": "Ranger",
    "Rogue": "Ladro",
    "Sorcerer": "Stregone",
    "Warlock": "Warlock",
    "Wizard": "Mago",
    "Artificer": "Artefice"
  },
  subclass: {
    // Barbarian
    "Path of the Berserker": "Sentiero del Berserker",
    "Path of the Wild Heart": "Sentiero del Cuore Selvaggio",
    "Path of the World Tree": "Sentiero dell'Albero del Mondo",
    "Path of the Zealot": "Sentiero del Fanatico",
    // Bard
    "College of Dance": "Collegio della Danza",
    "College of Glamour": "Collegio del Fascino",
    "College of Lore": "Collegio della Sapienza",
    "College of Spirits": "Collegio degli Spiriti",
    "College of Valor": "Collegio del Valore",
    // Cleric
    "Grave Domain": "Dominio della Tomba",
    "Knowledge Domain": "Dominio della Conoscenza",
    "Life Domain": "Dominio della Vita",
    "Light Domain": "Dominio della Luce",
    "Trickery Domain": "Dominio dell'Inganno",
    "War Domain": "Dominio della Guerra",
    // Druid
    "Circle of the Land": "Circolo della Terra",
    "Circle of the Moon": "Circolo della Luna",
    "Circle of the Sea": "Circolo del Mare",
    "Circle of the Stars": "Circolo delle Stelle",
    // Fighter
    "Battle Master": "Maestro di Battaglia",
    "Champion": "Campione",
    "Eldritch Knight": "Cavaliere Mistico",
    "Psi Warrior": "Guerriero Psionico",
    "Banneret": "Cavaliere del Drago Porpora",
    // Monk
    "Warrior of Mercy": "Guerriero della Misericordia",
    "Warrior of Shadow": "Guerriero delle Ombre",
    "Warrior of the Elements": "Guerriero degli Elementi",
    "Warrior of the Open Hand": "Guerriero della Mano Aperta",
    // Paladin
    "Oath of Devotion": "Giuramento di Devozione",
    "Oath of Glory": "Giuramento di Gloria",
    "Oath of the Ancients": "Giuramento degli Antichi",
    "Oath of Vengeance": "Giuramento di Vendetta",
    "Oath of the Noble Genies": "Giuramento dei Nobili Geni",
    // Ranger
    "Beast Master": "Signore delle Bestie",
    "Fey Wanderer": "Viandante di Selva Fatata",
    "Gloom Stalker": "Cacciatore delle Tenebre",
    "Hunter": "Cacciatore",
    // Rogue
    "Arcane Trickster": "Mistificatore Arcano",
    "Assassin": "Assassino",
    "Soulknife": "Lama Psionica",
    "Thief": "Furfante",
    // Sorcerer
    "Aberrant Sorcery": "Stregoneria Aberrante",
    "Clockwork Sorcery": "Stregoneria Meccanica",
    "Draconic Sorcery": "Stregoneria Draconica",
    "Shadow Sorcery": "Stregoneria delle Ombre",
    "Wild Magic Sorcery": "Stregoneria di Magia Selvaggia",
    "Spellfire Sorcery": "Stregoneria del Fuoco Magico",
    // Warlock
    "Archfey Patron": "Patrono dell'Arcifata",
    "Celestial Patron": "Patrono del Celeste",
    "Fiend Patron": "Patrono dell'Immondo",
    "Great Old One Patron": "Patrono del Grande Antico",
    "Undead Patron": "Patrono del Non Morto",
    // Wizard
    "Abjurer": "Abiuratore",
    "Bladesinger": "Cantore della Lama",
    "Diviner": "Divinatore",
    "Evoker": "Invocatore",
    "Illusionist": "Illusionista"
  },
  species: {
    "Dragonborn": "Dragonide",
    "Dwarf": "Nano",
    "Elf": "Elfo",
    "Gnome": "Gnomo",
    "Goliath": "Goliath",
    "Human": "Umano",
    "Halfling": "Halfling",
    "Orc": "Orco",
    "Tiefling": "Tiefling",
    "Aasimar": "Aasimar",
    "Changeling": "Cangiante",
    "Kalashtar": "Kalashtar",
    "Warforged": "Forgiato",
    "Dhampir": "Dampiro",
    "Hexblood": "Stirpe Esangue",
    "Reborn": "Rinato"
  },
  background: {
    "Acolyte": "Accolito",
    "Artisan": "Artigiano",
    "Charlatan": "Ciarlatano",
    "Criminal": "Criminale",
    "Entertainer": "Intrattenitore",
    "Farmer": "Agricoltore",
    "Guard": "Guardia",
    "Guide": "Guida",
    "Hermit": "Eremita",
    "Merchant": "Mercante",
    "Noble": "Nobile",
    "Sage": "Sapiente",
    "Sailor": "Marinaio",
    "Scribe": "Scriba",
    "Soldier": "Soldato",
    "Wayfarer": "Viandante"
  },
  feat: {
    "Alert": "Allerta",
    "Magic Initiate": "Iniziato alla Magia",
    "Lucky": "Fortunato",
    "Healer": "Guaritore",
    "Crafter": "Artigiano",
    "Musician": "Musicista",
    "Savage Attacker": "Attaccante Selvaggio",
    "Skilled": "Abile",
    "Tavern Brawler": "Rissoso da Taverna",
    "Tough": "Robusto",
    "Ability Score Improvement": "Aumento dei Punteggi di Caratteristica",
    "Athlete": "Atleta",
    "Charger": "Carica",
    "Actor": "Attore",
    "Chef": "Chef",
    "Crossbow Expert": "Esperto di Balestre",
    "Crusher": "Frantumatore",
    "Durable": "Costituzione Robusta",
    "Dual Wielder": "Combattere con Due Armi",
    "Defensive Duelist": "Duellante Difensivo",
    "Elemental Adept": "Adepto Elementale",
    "Fey Touched": "Toccato dai Fey",
    "Grappler": "Lottatore",
    "Great Weapon Master": "Maestro delle Grandi Armi",
    "Heavy Armor Master": "Maestro delle Armature Pesanti",
    "Heavily Armored": "Corazzato Pesantemente",
    "Inspiring Leader": "Leader Ispiratore",
    "Keen Mind": "Mente Acuta",
    "Mage Slayer": "Uccisore di Maghi",
    "Lightly Armored": "Corazzato Leggermente",
    "Medium Armor Master": "Maestro delle Armature Medie",
    "Moderately Armored": "Corazzato Moderatamente",
    "Mounted Combatant": "Combattente in Sella",
    "Piercer": "Perforatore",
    "Resilient": "Resiliente",
    "Ritual Caster": "Lanciatore di Rituali",
    "Sentinel": "Sentinella",
    "Shadow Touched": "Toccato dalle Ombre",
    "Sharpshooter": "Tiratore Scelto",
    "Shield Master": "Maestro degli Scudi",
    "Spell Sniper": "Cecchino Magico",
    "Telekinetic": "Telecinetico",
    "Telepathic": "Telepatico",
    "War Caster": "Incantatore da Guerra",
    "Weapon Master": "Maestro delle Armi"
  }
};

async function runQuery(sql) {
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
      throw new Error(`HTTP error! status: ${response.status}, details: ${errText}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error(`Error running SQL: ${sql.slice(0, 100)}...`);
    console.error(error.message);
    throw error;
  }
}

async function main() {
  console.log('Starting official Italian translations loader using native fetch...');
  
  // Make sure table exists
  const createTableSql = `
    CREATE TABLE IF NOT EXISTS public.translations (
      id SERIAL PRIMARY KEY,
      category TEXT NOT NULL,
      en_name TEXT NOT NULL,
      it_name TEXT NOT NULL,
      it_description TEXT,
      da_name TEXT,
      da_description TEXT,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
      UNIQUE(category, en_name)
    );
  `;
  await runQuery(createTableSql);
  console.log('Table public.translations verified.');

  // Construct batch statements
  let sqlStatements = '';
  let count = 0;

  for (const [category, mappings] of Object.entries(categories)) {
    for (const [enName, itName] of Object.entries(mappings)) {
      const escapedEn = enName.replace(/'/g, "''");
      const escapedIt = itName.replace(/'/g, "''");
      
      sqlStatements += `
        INSERT INTO public.translations (category, en_name, it_name)
        VALUES ('${category}', '${escapedEn}', '${escapedIt}')
        ON CONFLICT (category, en_name) DO UPDATE 
        SET it_name = EXCLUDED.it_name;
      `;
      count++;
    }
  }

  if (sqlStatements.length > 0) {
    console.log(`Executing batch insert of ${count} official translations...`);
    await runQuery(sqlStatements);
    console.log(`Successfully loaded ${count} translations!`);
  } else {
    console.log('No translations to load.');
  }

  console.log('--- ALL OFFICIAL ITALIAN TRANSLATIONS LOADED ---');
}

main().catch(err => {
  console.error('Fatal execution error:', err.message);
  process.exit(1);
});
