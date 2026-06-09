class SummonCreature {
  final String name;
  final String type;
  final String ac;
  final String hp;
  final String speed;
  final String senses;
  final String resistances;
  final Map<String, int> abilities;
  final List<SummonAction> actions;
  final String lore;

  SummonCreature({
    required this.name,
    required this.type,
    required this.ac,
    required this.hp,
    required this.speed,
    required this.senses,
    required this.abilities,
    required this.actions,
    this.resistances = '',
    this.lore = '',
  });
}

class SummonAction {
  final String name;
  final String description;

  SummonAction({required this.name, required this.description});
}

class SummonsHelper {
  static List<SummonCreature> getSummonsForSpell(String spellName, String lang) {
    final nameLower = spellName.toLowerCase();
    
    // Check if Find Familiar (or Evoca Famiglio / Find Familiars / Begyndersæt Danish equivalents)
    if (nameLower.contains('familiar') || nameLower.contains('famiglio')) {
      return _getFamiliars(lang);
    }
    
    // Check Summon spells
    if (nameLower.contains('summon beast') || nameLower.contains('evoca bestia')) {
      return _getSummonBeast(lang);
    }
    if (nameLower.contains('summon fey') || nameLower.contains('evoca folletto')) {
      return _getSummonFey(lang);
    }
    if (nameLower.contains('summon undead') || nameLower.contains('evoca non morto')) {
      return _getSummonUndead(lang);
    }
    if (nameLower.contains('summon aberration') || nameLower.contains('evoca aberrazione')) {
      return _getSummonAberration(lang);
    }
    if (nameLower.contains('summon construct') || nameLower.contains('evoca costrutto')) {
      return _getSummonConstruct(lang);
    }
    if (nameLower.contains('summon elemental') || nameLower.contains('evoca elementale')) {
      return _getSummonElemental(lang);
    }
    if (nameLower.contains('summon celestial') || nameLower.contains('evoca celestiale')) {
      return _getSummonCelestial(lang);
    }
    if (nameLower.contains('summon fiend') || nameLower.contains('evoca immondo')) {
      return _getSummonFiend(lang);
    }
    if (nameLower.contains('summon dragon') || nameLower.contains('evoca drago')) {
      return _getSummonDragon(lang);
    }

    return [];
  }

  static List<SummonCreature> _getFamiliars(String lang) {
    if (lang == 'it') {
      return [
        SummonCreature(
          name: 'Gufo',
          type: 'Bestia (Minuscola)',
          ac: '11',
          hp: '1',
          speed: '1.5 m, Volo 18 m',
          senses: 'Scurovisione 36 m, Percezione Passiva 13',
          abilities: {'str': 3, 'dex': 13, 'con': 8, 'int': 2, 'wis': 12, 'cha': 7},
          lore: 'Famoso per la sua capacità di volare senza provocare attacchi di opportunità (Volata) e vista acuta.',
          actions: [
            SummonAction(name: 'Artigli', description: '+3 al colpire, 1 danno tagliente.'),
          ],
        ),
        SummonCreature(
          name: 'Gatto',
          type: 'Bestia (Minuscola)',
          ac: '12',
          hp: '2',
          speed: '12 m, Scalare 9 m',
          senses: 'Percezione Passiva 13, Olfatto Acuto',
          abilities: {'str': 3, 'dex': 15, 'con': 10, 'int': 3, 'wis': 12, 'cha': 7},
          lore: 'Ottimo per l\'esplorazione furtiva a terra.',
          actions: [
            SummonAction(name: 'Artigli', description: '+0 al colpire, 1 danno tagliente.'),
          ],
        ),
        SummonCreature(
          name: 'Pipistrello',
          type: 'Bestia (Minuscola)',
          ac: '12',
          hp: '1',
          speed: '1.5 m, Volo 9 m',
          senses: 'Vista Cieca 18 m, Percezione Passiva 11',
          abilities: {'str': 2, 'dex': 15, 'con': 8, 'int': 2, 'wis': 12, 'cha': 4},
          lore: 'Usa l\'ecolocalizzazione (Vista Cieca) per rilevare oggetti invisibili nel buio.',
          actions: [
            SummonAction(name: 'Morso', description: '+0 al colpire, 1 danno perforante.'),
          ],
        ),
        SummonCreature(
          name: 'Sfingina (Sphinx of Wonder)',
          type: 'Celestiale (Minuscola) - Patto della Catena',
          ac: '13',
          hp: '24',
          speed: '6 m, Volo 12 m',
          senses: 'Scurovisione 18 m, Percezione Passiva 11',
          resistances: 'Necrotico, Psichico, Radioso',
          abilities: {'str': 6, 'dex': 17, 'con': 13, 'int': 15, 'wis': 12, 'cha': 11},
          lore: 'Creatura dorata inviata dai Couatl, si esprime in enigmi ed esegue cure rapide.',
          actions: [
            SummonAction(name: 'Artigliata', description: '+5 al colpire, 1d4+3 taglienti più 2d6 radiosi.'),
            SummonAction(name: 'Burst of Ingenuity (2/Giorno)', description: 'Reazione: Aggiunge +2 alla prova o TS di un alleato entro 30 ft.'),
          ],
        ),
        SummonCreature(
          name: 'Pseudodrago',
          type: 'Drago (Minuscolo) - Patto della Catena',
          ac: '13',
          hp: '10',
          speed: '4.5 m, Volo 18 m',
          senses: 'Vista Cieca 3 m, Scurovisione 18 m, Percezione Passiva 13',
          abilities: {'str': 6, 'dex': 15, 'con': 13, 'int': 10, 'wis': 12, 'cha': 10},
          lore: 'Drago in miniatura dotato di resistenza magica condivisa e pungiglione soporifero.',
          actions: [
            SummonAction(name: 'Morso', description: '+4 al colpire, 1d4+2 perforanti.'),
            SummonAction(name: 'Pungiglione', description: '+4 al colpire, 1d4 veleno. TS Costituzione (CD 11) o condizione Avvelenato per 1 ora (fallimento di 5+ addormenta).'),
          ],
        ),
        SummonCreature(
          name: 'Diavoletto (Imp)',
          type: 'Immondo (Minuscolo) - Patto della Catena',
          ac: '13',
          hp: '10',
          speed: '6 m, Volo 12 m',
          senses: 'Vista del Diavolo 36 m, Percezione Passiva 11',
          resistances: 'Freddo, Fuoco, Veleno, Tagliente/Perforante/Contundente non magici',
          abilities: {'str': 6, 'dex': 17, 'con': 13, 'int': 11, 'wis': 12, 'cha': 14},
          lore: 'Spia invisibile ideale per volare invisibile e curare nell\'ombra.',
          actions: [
            SummonAction(name: 'Invisibilità', description: 'Diventa invisibile con equipaggiamento fino a quando attacca o perde concentrazione.'),
            SummonAction(name: 'Pungiglione', description: '+5 al colpire, 1d4+3 perforanti più 3d6 danni da veleno. TS Costituzione CD 11 dimezza.'),
          ],
        ),
      ];
    } else if (lang == 'da') {
      return [
        SummonCreature(
          name: 'Ugle',
          type: 'Bæst (Lillebitte)',
          ac: '11',
          hp: '1',
          speed: '1.5 m, flyvning 18 m',
          senses: 'Mørkesyn 36 m, Passiv Perception 13',
          abilities: {'str': 3, 'dex': 13, 'con': 8, 'int': 2, 'wis': 12, 'cha': 7},
          lore: 'Kan flyve ud af fjenders rækkevidde uden at fremprovokere angreb (Flyby).',
          actions: [
            SummonAction(name: 'Klør', description: '+3 for at ramme, 1 skærende skade.'),
          ],
        ),
        SummonCreature(
          name: 'Kat',
          type: 'Bæst (Lillebitte)',
          ac: '12',
          hp: '2',
          speed: '12 m, klatring 9 m',
          senses: 'Passiv Perception 13, God lugtesans',
          abilities: {'str': 3, 'dex': 15, 'con': 10, 'int': 3, 'wis': 12, 'cha': 7},
          lore: 'Fremragende til lydløs rekognoscering på land.',
          actions: [
            SummonAction(name: 'Klør', description: '+0 for at ramme, 1 skærende skade.'),
          ],
        ),
        SummonCreature(
          name: 'Flagermus',
          type: 'Bæst (Lillebitte)',
          ac: '12',
          hp: '1',
          speed: '1.5 m, flyvning 9 m',
          senses: 'Blindsyn 18 m, Passiv Perception 11',
          abilities: {'str': 2, 'dex': 15, 'con': 8, 'int': 2, 'wis': 12, 'cha': 4},
          lore: 'Bruger ekkolokalisering (Blindsyn) til at opdage skjulte mål.',
          actions: [
            SummonAction(name: 'Bid', description: '+0 for at ramme, 1 stikkende skade.'),
          ],
        ),
        SummonCreature(
          name: 'Vidunder-Sfinx',
          type: 'Himmelsk (Lillebitte) - Kædens Pagt',
          ac: '13',
          hp: '24',
          speed: '6 m, flyvning 12 m',
          senses: 'Mørkesyn 18 m, Passiv Perception 11',
          resistances: 'Nekrotisk, Psykisk, Strålende (Radiant)',
          abilities: {'str': 6, 'dex': 17, 'con': 13, 'int': 15, 'wis': 12, 'cha': 11},
          lore: 'Gylden sfinx udsendt af Couatl. Taler i gåder og yder hurtig helbredelse.',
          actions: [
            SummonAction(name: 'Rend (Kløer)', description: '+5 for at ramme, 1d4+3 skærende plus 2d6 strålende skade.'),
            SummonAction(name: 'Burst of Ingenuity (2/Dag)', description: 'Reaktion: Tilføjer +2 til en allierets test eller redningskast inden for 30 fod.'),
          ],
        ),
        SummonCreature(
          name: 'Pseudodrage',
          type: 'Drage (Lillebitte) - Kædens Pagt',
          ac: '13',
          hp: '10',
          speed: '4.5 m, flyvning 18 m',
          senses: 'Blindsyn 3 m, Mørkesyn 18 m, Passiv Perception 13',
          abilities: {'str': 6, 'dex': 15, 'con': 13, 'int': 10, 'wis': 12, 'cha': 10},
          lore: 'Lille drage med delte magiske modstande og en giftig sovehale.',
          actions: [
            SummonAction(name: 'Bid', description: '+4 for at ramme, 1d4+2 stikkende skade.'),
            SummonAction(name: 'Pungiglione (Stik)', description: '+4 for at ramme, 1d4 giftskade. Konstitution redningskast (DC 11) eller forgiftes i 1 time.'),
          ],
        ),
        SummonCreature(
          name: 'Djævelsk Væsen (Imp)',
          type: 'Djævel (Lillebitte) - Kædens Pagt',
          ac: '13',
          hp: '10',
          speed: '6 m, flyvning 12 m',
          senses: 'Djævelesyn 36 m, Passiv Perception 11',
          resistances: 'Kulde, Ild, Gift, ikke-magiske fysiske angreb',
          abilities: {'str': 6, 'dex': 17, 'con': 13, 'int': 11, 'wis': 12, 'cha': 14},
          lore: 'Lille djævel egnet til usynlig spionage og angreb fra skyggerne.',
          actions: [
            SummonAction(name: 'Invisibilitet', description: 'Bliver usynlig sammen med sit udstyr, indtil den angriber eller mister koncentration.'),
            SummonAction(name: 'Stik (Sting)', description: '+5 for at ramme, 1d4+3 stikkende plus 3d6 giftskade. DC 11 Konstitution redningskast for halvering.'),
          ],
        ),
      ];
    } else {
      // English / Default
      return [
        SummonCreature(
          name: 'Owl',
          type: 'Beast (Tiny)',
          ac: '11',
          hp: '1',
          speed: '5 ft., fly 60 ft.',
          senses: 'Darkvision 120 ft., Passive Perception 13',
          abilities: {'str': 3, 'dex': 13, 'con': 8, 'int': 2, 'wis': 12, 'cha': 7},
          lore: 'Can fly out of reach without provoking opportunity attacks (Flyby) and has keen hearing/sight.',
          actions: [
            SummonAction(name: 'Talons', description: '+3 to hit, 1 slashing damage.'),
          ],
        ),
        SummonCreature(
          name: 'Cat',
          type: 'Beast (Tiny)',
          ac: '12',
          hp: '2',
          speed: '40 ft., climb 30 ft.',
          senses: 'Passive Perception 13, Keen Smell',
          abilities: {'str': 3, 'dex': 15, 'con': 10, 'int': 3, 'wis': 12, 'cha': 7},
          lore: 'Excellent for stealthy ground-based exploration.',
          actions: [
            SummonAction(name: 'Claws', description: '+0 to hit, 1 slashing damage.'),
          ],
        ),
        SummonCreature(
          name: 'Bat',
          type: 'Beast (Tiny)',
          ac: '12',
          hp: '1',
          speed: '5 ft., fly 30 ft.',
          senses: 'Blindsight 60 ft., Passive Perception 11',
          abilities: {'str': 2, 'dex': 15, 'con': 8, 'int': 2, 'wis': 12, 'cha': 4},
          lore: 'Uses echolocation (Blindsight) to detect targets in total darkness.',
          actions: [
            SummonAction(name: 'Bite', description: '+0 to hit, 1 piercing damage.'),
          ],
        ),
        SummonCreature(
          name: 'Sphinx of Wonder',
          type: 'Celestial (Tiny) - Pact of the Chain',
          ac: '13',
          hp: '24',
          speed: '20 ft., fly 40 ft.',
          senses: 'Darkvision 60 ft., Passive Perception 11',
          resistances: 'Necrotic, Psychic, Radiant',
          abilities: {'str': 6, 'dex': 17, 'con': 13, 'int': 15, 'wis': 12, 'cha': 11},
          lore: 'Golden sphinx sent by a Couatl. Speaks in riddles and provides quick healing.',
          actions: [
            SummonAction(name: 'Rend', description: '+5 to hit, 1d4+3 slashing plus 2d6 radiant damage.'),
            SummonAction(name: 'Burst of Ingenuity (2/Day)', description: 'Reaction: Add +2 to a saving throw or ability check of an ally within 30 ft.'),
          ],
        ),
        SummonCreature(
          name: 'Pseudodragon',
          type: 'Dragon (Tiny) - Pact of the Chain',
          ac: '13',
          hp: '10',
          speed: '15 ft., fly 60 ft.',
          senses: 'Blindsight 10 ft., Darkvision 60 ft., Passive Perception 13',
          abilities: {'str': 6, 'dex': 15, 'con': 13, 'int': 10, 'wis': 12, 'cha': 10},
          lore: 'Miniature dragon that shares Magic Resistance and has a sleep-inducing sting.',
          actions: [
            SummonAction(name: 'Bite', description: '+4 to hit, 1d4+2 piercing damage.'),
            SummonAction(name: 'Sting', description: '+4 to hit, 1d4 poison damage. DC 11 Constitution save or Poisoned for 1 hour (unconscious if failed by 5+).'),
          ],
        ),
        SummonCreature(
          name: 'Imp',
          type: 'Fiend (Tiny) - Pact of the Chain',
          ac: '13',
          hp: '10',
          speed: '20 ft., fly 40 ft.',
          senses: 'Devil\'s Sight 120 ft., Passive Perception 11',
          resistances: 'Cold, Fire, Poison, non-magical physical attacks',
          abilities: {'str': 6, 'dex': 17, 'con': 13, 'int': 11, 'wis': 12, 'cha': 14},
          lore: 'Invisibly flies around for scouting and delivers poisonous stings.',
          actions: [
            SummonAction(name: 'Invisibility', description: 'Turns invisible until it attacks or loses concentration.'),
            SummonAction(name: 'Sting', description: '+5 to hit, 1d4+3 piercing plus 3d6 poison damage. DC 11 Constitution save to halve poison.'),
          ],
        ),
      ];
    }
  }

  static List<SummonCreature> _getSummonBeast(String lang) {
    final nameKey = lang == 'it' ? 'Spirito Bestiale' : (lang == 'da' ? 'Bestialsk Ånd' : 'Bestial Spirit');
    final landKey = lang == 'it' ? 'Terrestre' : (lang == 'da' ? 'Land' : 'Land');
    final airKey = lang == 'it' ? 'Aereo' : (lang == 'da' ? 'Luft' : 'Air');
    
    return [
      SummonCreature(
        name: '$nameKey ($landKey)',
        type: 'Beast',
        ac: '11 + Spell Level',
        hp: '30 (Land/Water) / 20 (Air) + 5 per level above 2nd',
        speed: '30 ft., climb 30 ft.',
        senses: 'Darkvision 60 ft., Passive Perception 12',
        abilities: {'str': 18, 'dex': 11, 'con': 16, 'int': 4, 'wis': 14, 'cha': 5},
        lore: 'A physical spirit of the wild taking the shape of a land predator.',
        actions: [
          SummonAction(name: 'Maul', description: '+4 + Spell Level to hit, 1d8 + 4 + Spell Level slashing damage.'),
          SummonAction(name: 'Pack Tactics', description: 'Advantage on attack rolls if an ally is within 5 ft. of the target.'),
        ],
      ),
      SummonCreature(
        name: '$nameKey ($airKey)',
        type: 'Beast',
        ac: '11 + Spell Level',
        hp: '20 + 5 per level above 2nd',
        speed: '10 ft., fly 60 ft.',
        senses: 'Darkvision 60 ft., Passive Perception 12',
        abilities: {'str': 18, 'dex': 11, 'con': 16, 'int': 4, 'wis': 14, 'cha': 5},
        actions: [
          SummonAction(name: 'Maul', description: '+4 + Spell Level to hit, 1d8 + 4 + Spell Level slashing damage.'),
          SummonAction(name: 'Flyby', description: 'Does not provoke opportunity attacks when flying out of an enemy\'s reach.'),
        ],
      ),
    ];
  }

  static List<SummonCreature> _getSummonFey(String lang) {
    final feyName = lang == 'it' ? 'Spirito Folletto' : (lang == 'da' ? 'Alfeånd' : 'Fey Spirit');
    return [
      SummonCreature(
        name: feyName,
        type: 'Fey',
        ac: '12 + Spell Level',
        hp: '30 + 10 per level above 3rd',
        speed: '40 ft.',
        senses: 'Darkvision 60 ft., Passive Perception 12',
        abilities: {'str': 13, 'dex': 16, 'con': 14, 'int': 14, 'wis': 11, 'cha': 16},
        lore: 'Fey spirits representing fuming, mirthful, or tricksy aspects.',
        actions: [
          SummonAction(name: 'Shortsword', description: '+3 + Spell Level to hit, 1d6 + 3 + Spell Level force damage.'),
          SummonAction(name: 'Mirthful Step / Teleport', description: 'Teleports up to 30 ft. to an unoccupied space. If Mirthful, can charm a creature within 10 ft.'),
        ],
      ),
    ];
  }

  static List<SummonCreature> _getSummonUndead(String lang) {
    final undName = lang == 'it' ? 'Spirito Non Morto' : (lang == 'da' ? 'Genfærd' : 'Undead Spirit');
    return [
      SummonCreature(
        name: '$undName (Skeletal / Ghostly / Putrid)',
        type: 'Undead',
        ac: '11 + Spell Level',
        hp: '30 + 10 per level above 3rd',
        speed: '30 ft. (Fly 40 ft. for Ghostly)',
        senses: 'Darkvision 60 ft., Passive Perception 10',
        abilities: {'str': 12, 'dex': 16, 'con': 15, 'int': 4, 'wis': 10, 'cha': 9},
        lore: 'A ghostly presence, skeletal archer, or putrid zombie.',
        actions: [
          SummonAction(name: 'Grave Bolt / Rotting Claw', description: '+3 + Spell Level to hit, 1d8 + 3 + Spell Level necrotic damage. Skeletal attacks at range.'),
          SummonAction(name: 'Festering Aura (Putrid)', description: 'Poisonous gas surrounds the putrid summon, poisoning adjacent creatures on fail.'),
        ],
      ),
    ];
  }

  static List<SummonCreature> _getSummonAberration(String lang) {
    final abName = lang == 'it' ? 'Spirito Aberrante' : (lang == 'da' ? 'Aberrant Ånd' : 'Aberrant Spirit');
    return [
      SummonCreature(
        name: abName,
        type: 'Aberration',
        ac: '11 + Spell Level',
        hp: '40 + 10 per level above 4th',
        speed: '30 ft., fly 30 ft. (hover)',
        senses: 'Darkvision 60 ft., Passive Perception 10',
        abilities: {'str': 16, 'dex': 10, 'con': 15, 'int': 16, 'wis': 10, 'cha': 6},
        lore: 'A horrific aberration (Beholderkin, Slaad, or Star Spawn).',
        actions: [
          SummonAction(name: 'Claws / Eye Ray', description: '+3 + Spell Level to hit, 1d10 + 3 + Spell Level psychic or force damage.'),
          SummonAction(name: 'Regeneration (Slaad)', description: 'Regenerates 5 HP at the start of its turn if it has at least 1 HP.'),
        ],
      ),
    ];
  }

  static List<SummonCreature> _getSummonConstruct(String lang) {
    final conName = lang == 'it' ? 'Spirito Costrutto' : (lang == 'da' ? 'Konstrueret Ånd' : 'Construct Spirit');
    return [
      SummonCreature(
        name: conName,
        type: 'Construct',
        ac: '13 + Spell Level',
        hp: '40 + 15 per level above 4th',
        speed: '30 ft.',
        senses: 'Darkvision 60 ft., Passive Perception 10',
        abilities: {'str': 18, 'dex': 10, 'con': 16, 'int': 4, 'wis': 10, 'cha': 1},
        lore: 'A clay, metal, or stone animated protector.',
        actions: [
          SummonAction(name: 'Slam', description: '+4 + Spell Level to hit, 1d8 + 4 + Spell Level bludgeoning damage.'),
          SummonAction(name: 'Heated Body (Metal)', description: 'Deals 1d10 fire damage to anyone touching it or hitting it with melee attacks.'),
        ],
      ),
    ];
  }

  static List<SummonCreature> _getSummonElemental(String lang) {
    final elName = lang == 'it' ? 'Spirito Elementale' : (lang == 'da' ? 'Elementar Ånd' : 'Elemental Spirit');
    return [
      SummonCreature(
        name: elName,
        type: 'Elemental',
        ac: '11 + Spell Level',
        hp: '50 + 15 per level above 4th',
        speed: '40 ft. (Burrow/Fly/Swim depending on element)',
        senses: 'Darkvision 60 ft., Passive Perception 10',
        abilities: {'str': 18, 'dex': 15, 'con': 16, 'int': 4, 'wis': 10, 'cha': 16},
        lore: 'An elemental force of Air, Earth, Fire, or Water.',
        actions: [
          SummonAction(name: 'Slam', description: '+4 + Spell Level to hit, 1d10 + 4 + Spell Level element-typed damage.'),
          SummonAction(name: 'Amorphous Form', description: 'Can move through spaces as narrow as 1 inch without squeezing.'),
        ],
      ),
    ];
  }

  static List<SummonCreature> _getSummonCelestial(String lang) {
    final celName = lang == 'it' ? 'Spirito Celestiale' : (lang == 'da' ? 'Himmelsk Ånd' : 'Celestial Spirit');
    return [
      SummonCreature(
        name: celName,
        type: 'Celestial',
        ac: '11 + Spell Level (13 + Spell Level for Defender)',
        hp: '40 + 10 per level above 5th',
        speed: '30 ft., fly 40 ft.',
        senses: 'Darkvision 60 ft., Passive Perception 12',
        abilities: {'str': 16, 'dex': 14, 'con': 16, 'int': 10, 'wis': 14, 'cha': 16},
        lore: 'A radiant avenger or defender sent from upper planes.',
        actions: [
          SummonAction(name: 'Radiant Bow / Mace', description: '+3 + Spell Level to hit, 2d6 + 3 + Spell Level radiant/force damage.'),
          SummonAction(name: 'Healing Touch (1/Day)', description: 'Heals a creature for 2d8 + Spell Level HP.'),
        ],
      ),
    ];
  }

  static List<SummonCreature> _getSummonFiend(String lang) {
    final fiendName = lang == 'it' ? 'Spirito Immondo' : (lang == 'da' ? 'Djævleånd' : 'Fiendish Spirit');
    return [
      SummonCreature(
        name: fiendName,
        type: 'Fiend',
        ac: '12 + Spell Level',
        hp: '50 + 15 per level above 6th',
        speed: '40 ft. (Fly 60 ft. for Devil)',
        senses: 'Darkvision 60 ft., Passive Perception 10',
        abilities: {'str': 13, 'dex': 18, 'con': 16, 'int': 10, 'wis': 10, 'cha': 16},
        lore: 'A summoned demon, devil, or yugoloth representing lower planes.',
        actions: [
          SummonAction(name: 'Bite / Claws / Hurl Flame', description: '+4 + Spell Level to hit, 1d8 + 4 + Spell Level fire/slashing damage.'),
          SummonAction(name: 'Death Throes (Demon)', description: 'Explodes upon death dealing 2d10 fire damage to all adjacent targets.'),
        ],
      ),
    ];
  }

  static List<SummonCreature> _getSummonDragon(String lang) {
    final dragName = lang == 'it' ? 'Spirito Draconico' : (lang == 'da' ? 'Drageånd' : 'Draconic Spirit');
    return [
      SummonCreature(
        name: dragName,
        type: 'Dragon',
        ac: '14 + Spell Level',
        hp: '50 + 15 per level above 5th',
        speed: '30 ft., fly 60 ft.',
        senses: 'Blindsight 30 ft., Darkvision 60 ft., Passive Perception 12',
        abilities: {'str': 19, 'dex': 10, 'con': 17, 'int': 10, 'wis': 12, 'cha': 14},
        lore: 'A draconic force reflecting Chromatic, Gem, or Metallic lineage.',
        actions: [
          SummonAction(name: 'Rend / Breath Weapon', description: '+4 + Spell Level to hit, 1d6 + 4 + Spell Level physical/elemental damage.'),
          SummonAction(name: 'Draconic Resistance', description: 'Shares damage resistance with the summoner based on its elemental type.'),
        ],
      ),
    ];
  }
}
