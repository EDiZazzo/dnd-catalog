const ACCESS_TOKEN = process.env.SUPABASE_ACCESS_TOKEN || '';
const PROJECT_ID = 'xculeusuctxdujcevnwv';
const ENDPOINT = `https://api.supabase.com/v1/projects/${PROJECT_ID}/database/query`;

const equipments = [
  // Simple Melee
  { name: 'Club', category: 'Weapon', sub_category: 'Simple Melee', cost: '1 sp', weight: '2 lb.', damage: '1d4 Bludgeoning', properties: ['Light'], mastery: 'Slow', description: 'A simple club, easy to wield.', it_name: 'Randello', it_description: 'Un semplice randello, facile da impugnare.', tags: ['weapon', 'melee', 'simple'] },
  { name: 'Dagger', category: 'Weapon', sub_category: 'Simple Melee', cost: '2 gp', weight: '1 lb.', damage: '1d4 Piercing', properties: ['Finesse', 'Light', 'Thrown (range 20/60)'], mastery: 'Nick', description: 'A sharp dagger, useful for stealthy attacks.', it_name: 'Pugnale', it_description: 'Un pugnale affilato, utile per attacchi furtivi.', tags: ['weapon', 'melee', 'simple'] },
  { name: 'Greatclub', category: 'Weapon', sub_category: 'Simple Melee', cost: '2 sp', weight: '10 lb.', damage: '1d8 Bludgeoning', properties: ['Two-Handed'], mastery: 'Push', description: 'A large, heavy club that requires two hands.', it_name: 'Randello Pesante', it_description: 'Un grande randello pesante che richiede due mani.', tags: ['weapon', 'melee', 'simple'] },
  { name: 'Handaxe', category: 'Weapon', sub_category: 'Simple Melee', cost: '5 gp', weight: '2 lb.', damage: '1d6 Slashing', properties: ['Light', 'Thrown (range 20/60)'], mastery: 'Vex', description: 'A small axe designed for close combat or throwing.', it_name: 'Accetta', it_description: 'Una piccola ascia progettata per il combattimento ravvicinato o il lancio.', tags: ['weapon', 'melee', 'simple'] },
  { name: 'Javelin', category: 'Weapon', sub_category: 'Simple Melee', cost: '5 sp', weight: '2 lb.', damage: '1d6 Piercing', properties: ['Thrown (range 30/120)'], mastery: 'Slow', description: 'A light spear designed for throwing.', it_name: 'Giavellotto', it_description: 'Un giavellotto da lancio leggero.', tags: ['weapon', 'melee', 'simple'] },
  { name: 'Light Hammer', category: 'Weapon', sub_category: 'Simple Melee', cost: '2 gp', weight: '2 lb.', damage: '1d4 Bludgeoning', properties: ['Light', 'Thrown (range 20/60)'], mastery: 'Nick', description: 'A small hammer suitable for light combat.', it_name: 'Martello Leggero', it_description: 'Un piccolo martello adatto al combattimento leggero.', tags: ['weapon', 'melee', 'simple'] },
  { name: 'Mace', category: 'Weapon', sub_category: 'Simple Melee', cost: '5 gp', weight: '4 lb.', damage: '1d6 Bludgeoning', properties: [], mastery: 'Sap', description: 'A heavy mace with a bludgeoning head.', it_name: 'Mazza', it_description: 'Una pesante mazza dotata di una testa contundente.', tags: ['weapon', 'melee', 'simple'] },
  { name: 'Quarterstaff', category: 'Weapon', sub_category: 'Simple Melee', cost: '2 sp', weight: '4 lb.', damage: '1d6 Bludgeoning', properties: ['Versatile (1d8)'], mastery: 'Topple', description: 'A simple wooden staff.', it_name: 'Bastone Ferrato', it_description: 'Un semplice bastone di legno ferrato.', tags: ['weapon', 'melee', 'simple'] },
  { name: 'Sickle', category: 'Weapon', sub_category: 'Simple Melee', cost: '1 gp', weight: '2 lb.', damage: '1d4 Slashing', properties: ['Light'], mastery: 'Nick', description: 'A curved blade used for harvesting or light defense.', it_name: 'Falcetto', it_description: 'Una lama curva usata per il raccolto o per la difesa leggera.', tags: ['weapon', 'melee', 'simple'] },
  { name: 'Spear', category: 'Weapon', sub_category: 'Simple Melee', cost: '1 gp', weight: '3 lb.', damage: '1d6 Piercing', properties: ['Thrown (range 20/60)', 'Versatile (1d8)'], mastery: 'Sap', description: 'A simple thrusting spear.', it_name: 'Lancia', it_description: 'Una semplice lancia da spinta.', tags: ['weapon', 'melee', 'simple'] },

  // Simple Ranged
  { name: 'Light Crossbow', category: 'Weapon', sub_category: 'Simple Ranged', cost: '25 gp', weight: '5 lb.', damage: '1d8 Piercing', properties: ['Ammunition (range 80/320)', 'Loading', 'Two-Handed'], mastery: 'Slow', description: 'A simple mechanical crossbow.', it_name: 'Balestra Leggera', it_description: 'Una semplice balestra meccanica.', tags: ['weapon', 'ranged', 'simple'] },
  { name: 'Dart', category: 'Weapon', sub_category: 'Simple Ranged', cost: '5 cp', weight: '0.25 lb.', damage: '1d4 Piercing', properties: ['Finesse', 'Thrown (range 20/60)'], mastery: 'Vex', description: 'A sharp throwing dart.', it_name: 'Dardo', it_description: 'Un dardo da lancio affilato.', tags: ['weapon', 'ranged', 'simple'] },
  { name: 'Shortbow', category: 'Weapon', sub_category: 'Simple Ranged', cost: '25 gp', weight: '2 lb.', damage: '1d6 Piercing', properties: ['Ammunition (range 80/320)', 'Two-Handed'], mastery: 'Vex', description: 'A compact bow for hunting and light combat.', it_name: 'Arco Corto', it_description: 'Un arco compatto per la caccia e il combattimento leggero.', tags: ['weapon', 'ranged', 'simple'] },
  { name: 'Sling', category: 'Weapon', sub_category: 'Simple Ranged', cost: '1 sp', weight: '0 lb.', damage: '1d4 Bludgeoning', properties: ['Ammunition (range 30/120)'], mastery: 'Slow', description: 'A simple leather pouch for slinging stones.', it_name: 'Fionda', it_description: 'Una semplice tasca di cuoio per lanciare pietre.', tags: ['weapon', 'ranged', 'simple'] },

  // Martial Melee
  { name: 'Battleaxe', category: 'Weapon', sub_category: 'Martial Melee', cost: '10 gp', weight: '4 lb.', damage: '1d8 Slashing', properties: ['Versatile (1d10)'], mastery: 'Topple', description: 'A classic battleaxe.', it_name: 'Ascia da Battaglia', it_description: 'Una classica ascia da battaglia.', tags: ['weapon', 'melee', 'martial'] },
  { name: 'Flail', category: 'Weapon', sub_category: 'Martial Melee', cost: '10 gp', weight: '2 lb.', damage: '1d8 Bludgeoning', properties: [], mastery: 'Sap', description: 'A spiked ball on a chain attached to a handle.', it_name: 'Flagello', it_description: 'Una sfera chiodata su una catena attaccata a un manico.', tags: ['weapon', 'melee', 'martial'] },
  { name: 'Glaive', category: 'Weapon', sub_category: 'Martial Melee', cost: '20 gp', weight: '6 lb.', damage: '1d10 Slashing', properties: ['Heavy', 'Reach', 'Two-Handed'], mastery: 'Graze', description: 'A polearm with a single-edged curved blade.', it_name: 'Falcione', it_description: 'Un\'arma in asta con una lama curva a filo singolo.', tags: ['weapon', 'melee', 'martial'] },
  { name: 'Greataxe', category: 'Weapon', sub_category: 'Martial Melee', cost: '30 gp', weight: '7 lb.', damage: '1d12 Slashing', properties: ['Heavy', 'Two-Handed'], mastery: 'Cleave', description: 'A massive two-handed axe.', it_name: 'Ascia Bipenne', it_description: 'Una massiccia ascia a due mani.', tags: ['weapon', 'melee', 'martial'] },
  { name: 'Greatsword', category: 'Weapon', sub_category: 'Martial Melee', cost: '50 gp', weight: '6 lb.', damage: '2d6 Slashing', properties: ['Heavy', 'Two-Handed'], mastery: 'Graze', description: 'A massive two-handed sword.', it_name: 'Spadone', it_description: 'Una massiccia spada a due mani.', tags: ['weapon', 'melee', 'martial'] },
  { name: 'Halberd', category: 'Weapon', sub_category: 'Martial Melee', cost: '20 gp', weight: '6 lb.', damage: '1d10 Slashing', properties: ['Heavy', 'Reach', 'Two-Handed'], mastery: 'Cleave', description: 'A polearm combining an axe and a spear head.', it_name: 'Alabarda', it_description: 'Un\'arma in asta che combina la testa di un\'ascia e quella di una lancia.', tags: ['weapon', 'melee', 'martial'] },
  { name: 'Lance', category: 'Weapon', sub_category: 'Martial Melee', cost: '10 gp', weight: '6 lb.', damage: '1d10 Piercing', properties: ['Heavy', 'Reach'], mastery: 'Topple', description: 'A long spear designed for mounted combat.', it_name: 'Lancia da Cavaliere', it_description: 'Una lunga lancia progettata per il combattimento in sella.', tags: ['weapon', 'melee', 'martial'] },
  { name: 'Longsword', category: 'Weapon', sub_category: 'Martial Melee', cost: '15 gp', weight: '3 lb.', damage: '1d8 Slashing', properties: ['Versatile (1d10)'], mastery: 'Sap', description: 'A versatile martial sword.', it_name: 'Spada Lunga', it_description: 'Una spada marziale versatile.', tags: ['weapon', 'melee', 'martial'] },
  { name: 'Maul', category: 'Weapon', sub_category: 'Martial Melee', cost: '10 gp', weight: '10 lb.', damage: '2d6 Bludgeoning', properties: ['Heavy', 'Two-Handed'], mastery: 'Topple', description: 'A massive hammer requiring two hands.', it_name: 'Maglio', it_description: 'Un massiccio maglio che richiede due mani.', tags: ['weapon', 'melee', 'martial'] },
  { name: 'Morningstar', category: 'Weapon', sub_category: 'Martial Melee', cost: '15 gp', weight: '4 lb.', damage: '1d8 Piercing', properties: [], mastery: 'Vex', description: 'A spiked club.', it_name: 'Stella del Mattino', it_description: 'Una mazza chiodata.', tags: ['weapon', 'melee', 'martial'] },
  { name: 'Pike', category: 'Weapon', sub_category: 'Martial Melee', cost: '5 gp', weight: '18 lb.', damage: '1d10 Piercing', properties: ['Heavy', 'Reach', 'Two-Handed'], mastery: 'Push', description: 'A very long thrusting weapon.', it_name: 'Picca', it_description: 'Un\'arma da punta molto lunga.', tags: ['weapon', 'melee', 'martial'] },
  { name: 'Rapier', category: 'Weapon', sub_category: 'Martial Melee', cost: '25 gp', weight: '2 lb.', damage: '1d8 Piercing', properties: ['Finesse'], mastery: 'Vex', description: 'A light, thrusting sword.', it_name: 'Stocco', it_description: 'Una spada da spinta leggera.', tags: ['weapon', 'melee', 'martial'] },
  { name: 'Scimitar', category: 'Weapon', sub_category: 'Martial Melee', cost: '25 gp', weight: '3 lb.', damage: '1d6 Slashing', properties: ['Finesse', 'Light'], mastery: 'Nick', description: 'A curved slashing sword.', it_name: 'Scimitarra', it_description: 'Una spada da taglio curva.', tags: ['weapon', 'melee', 'martial'] },
  { name: 'Shortsword', category: 'Weapon', sub_category: 'Martial Melee', cost: '10 gp', weight: '2 lb.', damage: '1d6 Piercing', properties: ['Finesse', 'Light'], mastery: 'Vex', description: 'A short, nimble sword.', it_name: 'Spada Corta', it_description: 'Una spada corta e agile.', tags: ['weapon', 'melee', 'martial'] },
  { name: 'Trident', category: 'Weapon', sub_category: 'Martial Melee', cost: '5 gp', weight: '4 lb.', damage: '1d6 Piercing', properties: ['Thrown (range 20/60)', 'Versatile (1d8)'], mastery: 'Topple', description: 'A three-pronged spear.', it_name: 'Tridente', it_description: 'Una lancia a tre punte.', tags: ['weapon', 'melee', 'martial'] },
  { name: 'War Pick', category: 'Weapon', sub_category: 'Martial Melee', cost: '5 gp', weight: '2 lb.', damage: '1d8 Piercing', properties: [], mastery: 'Sap', description: 'A pick designed to pierce armor.', it_name: 'Picco da Guerra', it_description: 'Un picco progettato per perforare l\'armatura.', tags: ['weapon', 'melee', 'martial'] },
  { name: 'Warhammer', category: 'Weapon', sub_category: 'Martial Melee', cost: '15 gp', weight: '2 lb.', damage: '1d8 Bludgeoning', properties: ['Versatile (1d10)'], mastery: 'Push', description: 'A heavy martial hammer.', it_name: 'Martello da Guerra', it_description: 'Un pesante martello marziale.', tags: ['weapon', 'melee', 'martial'] },
  { name: 'Whip', category: 'Weapon', sub_category: 'Martial Melee', cost: '2 gp', weight: '3 lb.', damage: '1d4 Slashing', properties: ['Finesse', 'Reach'], mastery: 'Slow', description: 'A long leather whip.', it_name: 'Frusta', it_description: 'Una lunga frusta di cuoio.', tags: ['weapon', 'melee', 'martial'] },

  // Martial Ranged
  { name: 'Blowgun', category: 'Weapon', sub_category: 'Martial Ranged', cost: '10 gp', weight: '1 lb.', damage: '1 Piercing', properties: ['Ammunition (range 25/100)', 'Loading'], mastery: 'Vex', description: 'A pipe for shooting small darts.', it_name: 'Cerbottana', it_description: 'Un tubo per sparare piccoli dardi.', tags: ['weapon', 'ranged', 'martial'] },
  { name: 'Hand Crossbow', category: 'Weapon', sub_category: 'Martial Ranged', cost: '75 gp', weight: '3 lb.', damage: '1d6 Piercing', properties: ['Ammunition (range 30/120)', 'Light', 'Loading'], mastery: 'Vex', description: 'A small crossbow designed for one-handed use.', it_name: 'Balestra a Mano', it_description: 'Una piccola balestra progettata per l\'uso con una sola mano.', tags: ['weapon', 'ranged', 'martial'] },
  { name: 'Heavy Crossbow', category: 'Weapon', sub_category: 'Martial Ranged', cost: '50 gp', weight: '18 lb.', damage: '1d10 Piercing', properties: ['Ammunition (range 100/400)', 'Heavy', 'Loading', 'Two-Handed'], mastery: 'Push', description: 'A powerful two-handed mechanical crossbow.', it_name: 'Balestra Pesante', it_description: 'Una potente balestra meccanica a due mani.', tags: ['weapon', 'ranged', 'martial'] },
  { name: 'Longbow', category: 'Weapon', sub_category: 'Martial Ranged', cost: '50 gp', weight: '2 lb.', damage: '1d8 Piercing', properties: ['Ammunition (range 150/600)', 'Heavy', 'Two-Handed'], mastery: 'Slow', description: 'A powerful large bow.', it_name: 'Arco Lungo', it_description: 'Un arco grande e potente.', tags: ['weapon', 'ranged', 'martial'] },
  { name: 'Musket', category: 'Weapon', sub_category: 'Martial Ranged', cost: '500 gp', weight: '10 lb.', damage: '1d12 Piercing', properties: ['Ammunition (range 40/120)', 'Loading', 'Two-Handed'], mastery: 'Slow', description: 'An early firearm.', it_name: 'Moschetto', it_description: 'Un\'arma da fuoco antica.', tags: ['weapon', 'ranged', 'martial'] },
  { name: 'Pistol', category: 'Weapon', sub_category: 'Martial Ranged', cost: '250 gp', weight: '3 lb.', damage: '1d10 Piercing', properties: ['Ammunition (range 30/90)', 'Loading'], mastery: 'Vex', description: 'A small one-handed firearm.', it_name: 'Pistola', it_description: 'Una piccola arma da fuoco a una mano.', tags: ['weapon', 'ranged', 'martial'] },

  // Light Armor
  { name: 'Padded Armor', category: 'Armor', sub_category: 'Light Armor', cost: '5 gp', weight: '8 lb.', damage: null, properties: ['Stealth Disadvantage'], mastery: null, description: 'Lightly padded fabric undergarments.', it_name: 'Armatura Imbottita', it_description: 'Indumenti di tessuto leggermente imbottiti.', tags: ['armor', 'light'] },
  { name: 'Leather Armor', category: 'Armor', sub_category: 'Light Armor', cost: '10 gp', weight: '10 lb.', damage: null, properties: [], mastery: null, description: 'Boiled leather breastplate and greaves.', it_name: 'Armatura di Cuoio', it_description: 'Pettorale e schinieri di cuoio bollito.', tags: ['armor', 'light'] },
  { name: 'Studded Leather Armor', category: 'Armor', sub_category: 'Light Armor', cost: '45 gp', weight: '13 lb.', damage: null, properties: [], mastery: null, description: 'Reinforced leather armor with steel studs.', it_name: 'Cuoio Borchiato', it_description: 'Armatura di cuoio rinforzata con borchie d\'acciaio.', tags: ['armor', 'light'] },

  // Medium Armor
  { name: 'Hide Armor', category: 'Armor', sub_category: 'Medium Armor', cost: '10 gp', weight: '12 lb.', damage: null, properties: [], mastery: null, description: 'Thick animal skins worn as armor.', it_name: 'Armatura di Pelle', it_description: 'Spesse pelli di animali indossate come armatura.', tags: ['armor', 'medium'] },
  { name: 'Chain Shirt', category: 'Armor', sub_category: 'Medium Armor', cost: '50 gp', weight: '20 lb.', damage: null, properties: [], mastery: null, description: 'A shirt made of interlocking steel rings.', it_name: 'Camicia di Maglia', it_description: 'Una camicia fatta di anelli di ferro intrecciati.', tags: ['armor', 'medium'] },
  { name: 'Scale Mail', category: 'Armor', sub_category: 'Medium Armor', cost: '50 gp', weight: '45 lb.', damage: null, properties: ['Stealth Disadvantage'], mastery: null, description: 'Overlapping steel scales on a leather backing.', it_name: 'Corazza di Scaglie', it_description: 'Scaglie d\'acciaio sovrapposte su un supporto di cuoio.', tags: ['armor', 'medium'] },
  { name: 'Breastplate', category: 'Armor', sub_category: 'Medium Armor', cost: '400 gp', weight: '20 lb.', damage: null, properties: [], mastery: null, description: 'A solid metal chest piece.', it_name: 'Pettorale', it_description: 'Una piastra di metallo solida per il petto.', tags: ['armor', 'medium'] },
  { name: 'Half Plate', category: 'Armor', sub_category: 'Medium Armor', cost: '750 gp', weight: '40 lb.', damage: null, properties: ['Stealth Disadvantage'], mastery: null, description: 'Plate armor covering the head, torso, and shoulders.', it_name: 'Mezza Armatura', it_description: 'Armatura a piastre che copre la testa, il busto e le spalle.', tags: ['armor', 'medium'] },

  // Heavy Armor
  { name: 'Ring Mail', category: 'Armor', sub_category: 'Heavy Armor', cost: '30 gp', weight: '40 lb.', damage: null, properties: ['Stealth Disadvantage'], mastery: null, description: 'Leather with heavy rings sewed on.', it_name: 'Armatura ad Anelli', it_description: 'Cuoio con pesanti anelli cuciti sopra.', tags: ['armor', 'heavy'] },
  { name: 'Chain Mail', category: 'Armor', sub_category: 'Heavy Armor', cost: '75 gp', weight: '55 lb.', damage: null, properties: ['Stealth Disadvantage', 'Strength Requirement (13)'], mastery: null, description: 'Full suit of interlocking chain loops.', it_name: 'Cotta di Maglia', it_description: 'Tuta completa di anelli di catena intrecciati.', tags: ['armor', 'heavy'] },
  { name: 'Splint', category: 'Armor', sub_category: 'Heavy Armor', cost: '200 gp', weight: '60 lb.', damage: null, properties: ['Stealth Disadvantage', 'Strength Requirement (15)'], mastery: null, description: 'Vertical metal strips over leather backing.', it_name: 'Armatura a Strisce', it_description: 'Strisce di metallo verticali su un supporto di cuoio.', tags: ['armor', 'heavy'] },
  { name: 'Plate', category: 'Armor', sub_category: 'Heavy Armor', cost: '1500 gp', weight: '65 lb.', damage: null, properties: ['Stealth Disadvantage', 'Strength Requirement (15)'], mastery: null, description: 'Full suit of shaped interlocking steel plates.', it_name: 'Armatura a Piastre', it_description: 'Armatura completa di piastre d\'acciaio sagomate e collegate tra loro.', tags: ['armor', 'heavy'] },
  { name: 'Shield', category: 'Armor', sub_category: 'Shield', cost: '10 gp', weight: '6 lb.', damage: null, properties: [], mastery: null, description: 'A wooden or metal shield carried in one hand.', it_name: 'Scudo', it_description: 'Uno scudo di legno o metallo portato in una mano.', tags: ['armor', 'shield'] }
];

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
    console.error(`Error running SQL: ${error.message}`);
    throw error;
  }
}

async function main() {
  if (!ACCESS_TOKEN) {
    console.error('SUPABASE_ACCESS_TOKEN is required.');
    process.exit(1);
  }

  console.log('Seeding 2024 weapons, armors and translations...');
  
  let sql = '';
  
  for (const item of equipments) {
    const escName = item.name.replace(/'/g, "''");
    const escCat = item.category.replace(/'/g, "''");
    const escSub = item.sub_category.replace(/'/g, "''");
    const escCost = item.cost.replace(/'/g, "''");
    const escWeight = item.weight.replace(/'/g, "''");
    const escDmg = item.damage ? `'${item.damage.replace(/'/g, "''")}'` : 'NULL';
    const escProp = item.properties.map(p => `'${p.replace(/'/g, "''")}'`).join(', ');
    const escMast = item.mastery ? `'${item.mastery.replace(/'/g, "''")}'` : 'NULL';
    const escDesc = item.description.replace(/'/g, "''");
    const escItName = item.it_name.replace(/'/g, "''");
    const escItDesc = item.it_description.replace(/'/g, "''");
    const escTags = item.tags.map(t => `'${t.replace(/'/g, "''")}'`).join(', ');
    
    sql += `
      INSERT INTO official.equipment (name, category, sub_category, cost, weight, damage, properties, mastery, description, legacy, tags)
      VALUES ('${escName}', '${escCat}', '${escSub}', '${escCost}', '${escWeight}', ${escDmg}, ARRAY[${escProp}]::TEXT[], ${escMast}, '${escDesc}', false, ARRAY[${escTags}]::TEXT[])
      ON CONFLICT (name) DO UPDATE SET
        category = EXCLUDED.category,
        sub_category = EXCLUDED.sub_category,
        cost = EXCLUDED.cost,
        weight = EXCLUDED.weight,
        damage = EXCLUDED.damage,
        properties = EXCLUDED.properties,
        mastery = EXCLUDED.mastery,
        description = EXCLUDED.description;
      
      INSERT INTO public.translations (category, en_name, it_name, it_description)
      VALUES ('equipment', '${escName}', '${escItName}', '${escItDesc}')
      ON CONFLICT (category, en_name) DO UPDATE SET
        it_name = EXCLUDED.it_name,
        it_description = EXCLUDED.it_description;
    `;
  }
  
  await runQuery(sql);
  console.log('Seeded equipment successfully.');
}

main().catch(console.error);
