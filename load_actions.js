const ACCESS_TOKEN = process.env.SUPABASE_ACCESS_TOKEN || '';
const PROJECT_ID = 'xculeusuctxdujcevnwv';
const ENDPOINT = `https://api.supabase.com/v1/projects/${PROJECT_ID}/database/query`;

const actions = [
  {
    name: 'Attack',
    description: 'When you take the Attack action, you can make one melee or ranged attack. See the combat rules for details.',
    it_name: 'Attacco',
    it_description: 'Quando effettui l\'azione di Attacco, puoi compiere un attacco in mischia o a distanza. Per i dettagli, consulta le regole del combattimento.'
  },
  {
    name: 'Cast a Spell',
    description: 'Each spell has a casting time, which specifies whether the caster must use an action, a reaction, minutes, or hours to cast the spell. Casting a spell is, therefore, not always an action.',
    it_name: 'Lanciare un Incantesimo',
    it_description: 'Ogni incantesimo ha un tempo di lancio, che specifica se l\'incantatore deve usare un\'azione, una reazione, minuti o ore per lanciare l\'incantesimo. Lanciare un incantesimo, quindi, non è sempre un\'azione.'
  },
  {
    name: 'Dash',
    description: 'When you take the Dash action, you gain extra movement for the current turn. The increase equals your speed, after applying any modifiers.',
    it_name: 'Scatto',
    it_description: 'Quando effettui l\'azione di Scatto, ottieni movimento extra per il turno in corso. L\'aumento è pari alla tua velocità, dopo aver applicato eventuali modificatori.'
  },
  {
    name: 'Disengage',
    description: 'If you take the Disengage action, your movement doesn\'t provoke opportunity attacks for the rest of the turn.',
    it_name: 'Disimpegno',
    it_description: 'Se effettui l''azione di Disimpegno, il tuo movimento non provoca attacchi di opportunità per il resto del turno.'
  },
  {
    name: 'Dodge',
    description: 'When you take the Dodge action, you focus entirely on avoiding attacks. Until the start of your next turn, any attack roll made against you has disadvantage if you can see the attacker, and you make Dexterity saving throws with advantage.',
    it_name: 'Schivata',
    it_description: 'Quando effettui l\'azione di Schivata, ti concentri interamente sull\'evitare gli attacchi. Fino all\'inizio del tuo turno successivo, qualsiasi tiro per colpire effettuato contro di te ha svantaggio se puoi vedere l\'attaccante, e effettui i tiri salvezza su Destrezza con vantaggio.'
  },
  {
    name: 'Help',
    description: 'You can lend your aid to another creature in the completion of a task. When you take the Help action, the creature you aid gains advantage on the next ability check it makes to perform the task you are helping with.',
    it_name: 'Aiuto',
    it_description: 'Puoi prestare il tuo aiuto a un\'altra creatura per il completamento di un compito. Quando effettui l\'azione di Aiuto, la creatura che aiuti ottiene vantaggio alla successiva prova di caratteristica che effettua per compiere il compito in cui la stai aiutando.'
  },
  {
    name: 'Hide',
    description: 'When you take the Hide action, you make a Dexterity (Stealth) check in an attempt to hide, following the rules for hiding.',
    it_name: 'Nascondersi',
    it_description: 'Quando effettui l\'azione di Nascondersi, effettui una prova di Destrezza (Furtività) nel tentativo di nasconderti, seguendo le regole per nascondersi.'
  },
  {
    name: 'Ready',
    description: 'Sometimes you want to get the jump on a foe or wait for a particular circumstance before you act. To do so, you can take the Ready action on your turn, which lets you act using your reaction before the start of your next turn.',
    it_name: 'Prepararsi',
    it_description: 'A volte vuoi cogliere di sorpresa un nemico o aspettare una circostanza particolare prima di agire. Per farlo, puoi effettuare l\'azione di Prepararsi nel tuo turno, che ti consente di agire usando la tua reazione prima dell\'inizio del tuo turno successivo.'
  },
  {
    name: 'Search',
    description: 'When you take the Search action, you devote your attention to finding something. Depending on what you are searching for, the DM might have you make a Wisdom (Perception) check or an Intelligence (Investigation) check.',
    it_name: 'Cercare',
    it_description: 'Quando effettui l\'azione di Cercare, dedichi la tua attenzione alla ricerca di qualcosa. A seconda di ciò che stai cercando, il DM potrebbe farti effettuare una prova di Saggezza (Percezione) o una prova di Intelligenza (Indagare).'
  },
  {
    name: 'Use an Object',
    description: 'You normally interact with an object while doing something else, such as drawing a sword as part of an attack. When an object requires your action for its use, you take the Use an Object action.',
    it_name: 'Usare un Oggetto',
    it_description: 'Normalmente interagisci con un oggetto mentre fai qualcos\'altro, come estrarre una spada come parte di un attacco. Quando un oggetto richiede la tua azione per il suo utilizzo, effettui l\'azione di Usare un Oggetto.'
  }
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

  console.log('Seeding official actions and translations...');
  
  let sql = '';
  
  for (const action of actions) {
    const escName = action.name.replace(/'/g, "''");
    const escDesc = action.description.replace(/'/g, "''");
    const escItName = action.it_name.replace(/'/g, "''");
    const escItDesc = action.it_description.replace(/'/g, "''");
    
    sql += `
      INSERT INTO official.actions (name, description, source, tags)
      VALUES ('${escName}', '${escDesc}', 'PHB 2024', ARRAY['action'])
      ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description;
      
      INSERT INTO public.translations (category, en_name, it_name, it_description)
      VALUES ('action', '${escName}', '${escItName}', '${escItDesc}')
      ON CONFLICT (category, en_name) DO UPDATE SET
        it_name = EXCLUDED.it_name,
        it_description = EXCLUDED.it_description;
    `;
  }
  
  await runQuery(sql);
  console.log('Seeded actions successfully.');
}

main().catch(console.error);
