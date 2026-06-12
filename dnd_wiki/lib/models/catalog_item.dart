// Base class for all catalog items to share common fields
abstract class CatalogItem {
  final int id;
  final String name;
  final String source;
  final String description;
  final bool legacy;
  final List<String> tags;

  CatalogItem({
    required this.id,
    required this.name,
    required this.source,
    required this.description,
    required this.legacy,
    required this.tags,
  });
}

// 1. Spell Model
class Spell extends CatalogItem {
  final int level;
  final String school;
  final String castingTime;
  final String range;
  final String components;
  final String duration;
  final List<String> classes;
  final String? upgrades;

  Spell({
    required super.id,
    required super.name,
    required super.source,
    required super.description,
    required super.legacy,
    required super.tags,
    required this.level,
    required this.school,
    required this.castingTime,
    required this.range,
    required this.components,
    required this.duration,
    required this.classes,
    this.upgrades,
  });

  factory Spell.fromJson(Map<String, dynamic> json) {
    return Spell(
      id: json['id'] as int,
      name: json['name'] as String,
      source: json['source'] as String? ?? 'Unknown Source',
      description: json['description'] as String? ?? '',
      legacy: json['legacy'] as bool? ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      level: json['level'] as int? ?? 0,
      school: json['school'] as String? ?? 'Evocation',
      castingTime: json['casting_time'] as String? ?? 'Action',
      range: json['range'] as String? ?? 'Self',
      components: json['components'] as String? ?? 'V, S',
      duration: json['duration'] as String? ?? 'Instantaneous',
      classes: List<String>.from(json['classes'] ?? []),
      upgrades: json['upgrades'] as String?,
    );
  }
}

// 2. Trait helper model
class Trait {
  final String name;
  final String description;

  Trait({required this.name, required this.description});

  factory Trait.fromJson(Map<String, dynamic> json) {
    return Trait(
      name: json['name'] as String? ?? 'Trait',
      description: json['description'] as String? ?? '',
    );
  }
}

// Species Model
class Species extends CatalogItem {
  final String creatureType;
  final String size;
  final String speed;
  final List<Trait> traits;

  Species({
    required super.id,
    required super.name,
    required super.source,
    required super.description,
    required super.legacy,
    required super.tags,
    required this.creatureType,
    required this.size,
    required this.speed,
    required this.traits,
  });

  factory Species.fromJson(Map<String, dynamic> json) {
    var traitsList = json['traits'] as List? ?? [];
    List<Trait> parsedTraits = traitsList.map((t) => Trait.fromJson(t as Map<String, dynamic>)).toList();

    return Species(
      id: json['id'] as int,
      name: json['name'] as String,
      source: json['source'] as String? ?? 'Unknown Source',
      description: json['description'] as String? ?? '',
      legacy: json['legacy'] as bool? ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      creatureType: json['creature_type'] as String? ?? 'Humanoid',
      size: json['size'] as String? ?? 'Medium',
      speed: json['speed'] as String? ?? '30 feet',
      traits: parsedTraits,
    );
  }
}

// 3. Benefit helper model
class Benefit {
  final String name;
  final String description;

  Benefit({required this.name, required this.description});

  factory Benefit.fromJson(Map<String, dynamic> json) {
    return Benefit(
      name: json['name'] as String? ?? 'Benefit',
      description: json['description'] as String? ?? '',
    );
  }
}

// Feat Model
class Feat extends CatalogItem {
  final String category;
  final String? prerequisite;
  final List<Benefit> benefits;

  Feat({
    required super.id,
    required super.name,
    required super.source,
    required super.description,
    required super.legacy,
    required super.tags,
    required this.category,
    this.prerequisite,
    required this.benefits,
  });

  factory Feat.fromJson(Map<String, dynamic> json) {
    var benefitsList = json['benefits'] as List? ?? [];
    List<Benefit> parsedBenefits = benefitsList.map((b) => Benefit.fromJson(b as Map<String, dynamic>)).toList();

    return Feat(
      id: json['id'] as int,
      name: json['name'] as String,
      source: json['source'] as String? ?? 'Unknown Source',
      description: json['description'] as String? ?? '',
      legacy: json['legacy'] as bool? ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'] as String? ?? 'General Feat',
      prerequisite: json['prerequisite'] as String?,
      benefits: parsedBenefits,
    );
  }
}

// 4. Background Model
class Background extends CatalogItem {
  final String abilityScores;
  final String feat;
  final String skillProficiencies;
  final String toolProficiencies;
  final String equipment;

  Background({
    required super.id,
    required super.name,
    required super.source,
    required super.description,
    required super.legacy,
    required super.tags,
    required this.abilityScores,
    required this.feat,
    required this.skillProficiencies,
    required this.toolProficiencies,
    required this.equipment,
  });

  factory Background.fromJson(Map<String, dynamic> json) {
    return Background(
      id: json['id'] as int,
      name: json['name'] as String,
      source: json['source'] as String? ?? 'Unknown Source',
      description: json['description'] as String? ?? '',
      legacy: json['legacy'] as bool? ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      abilityScores: json['ability_scores'] as String? ?? '',
      feat: json['feat'] as String? ?? '',
      skillProficiencies: json['skill_proficiencies'] as String? ?? '',
      toolProficiencies: json['tool_proficiencies'] as String? ?? '',
      equipment: json['equipment'] as String? ?? '',
    );
  }
}

class ClassTable {
  final List<String> headers;
  final List<List<String>> rows;

  ClassTable({required this.headers, required this.rows});

  factory ClassTable.fromJson(Map<String, dynamic> json) {
    return ClassTable(
      headers: List<String>.from(json['headers'] ?? []),
      rows: (json['rows'] as List? ?? [])
          .map((row) => List<String>.from(row as List? ?? []))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'headers': headers,
        'rows': rows,
      };
}

class ClassFeature {
  final String name;
  final int level;
  final String description;

  ClassFeature({
    required this.name,
    required this.level,
    required this.description,
  });

  factory ClassFeature.fromJson(Map<String, dynamic> json) {
    return ClassFeature(
      name: json['name'] as String? ?? 'Feature',
      level: json['level'] as int? ?? 1,
      description: json['description'] as String? ?? '',
    );
  }
}

// 5. Class Model
class Class extends CatalogItem {
  final String primaryAbility;
  final List<String> savingThrows;
  final String hitDice;
  final List<String> weaponProficiencies;
  final List<String> armorProficiencies;
  final List<String> toolProficiencies;
  final List<String> skillProficiencies;
  final ClassTable classTable;
  final List<ClassFeature> features;

  Class({
    required super.id,
    required super.name,
    required super.source,
    required super.description,
    required super.legacy,
    required super.tags,
    required this.primaryAbility,
    required this.savingThrows,
    required this.hitDice,
    required this.weaponProficiencies,
    required this.armorProficiencies,
    required this.toolProficiencies,
    required this.skillProficiencies,
    required this.classTable,
    required this.features,
  });

  factory Class.fromJson(Map<String, dynamic> json) {
    var tableJson = json['class_table'];
    ClassTable parsedTable;
    if (tableJson is Map<String, dynamic>) {
      parsedTable = ClassTable.fromJson(tableJson);
    } else {
      parsedTable = ClassTable(headers: [], rows: []);
    }

    var featuresList = json['features'] as List? ?? [];
    List<ClassFeature> parsedFeatures = featuresList
        .map((f) => ClassFeature.fromJson(f as Map<String, dynamic>))
        .toList();

    return Class(
      id: json['id'] as int,
      name: json['name'] as String,
      source: json['source'] as String? ?? 'Unknown Source',
      description: json['description'] as String? ?? '',
      legacy: json['legacy'] as bool? ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      primaryAbility: json['primary_ability'] as String? ?? 'Strength',
      savingThrows: List<String>.from(json['saving_throws'] ?? []),
      hitDice: json['hit_dice'] as String? ?? '1d8',
      weaponProficiencies: List<String>.from(json['weapon_proficiencies'] ?? []),
      armorProficiencies: List<String>.from(json['armor_proficiencies'] ?? []),
      toolProficiencies: List<String>.from(json['tool_proficiencies'] ?? []),
      skillProficiencies: List<String>.from(json['skill_proficiencies'] ?? []),
      classTable: parsedTable,
      features: parsedFeatures,
    );
  }
}

// 6. Subclass Feature Model
class SubclassFeature {
  final String name;
  final int level;
  final String description;

  SubclassFeature({
    required this.name,
    required this.level,
    required this.description,
  });

  factory SubclassFeature.fromJson(Map<String, dynamic> json) {
    return SubclassFeature(
      name: json['name'] as String? ?? 'Feature',
      level: json['level'] as int? ?? 3,
      description: json['description'] as String? ?? '',
    );
  }
}

// Subclass Model
class Subclass extends CatalogItem {
  final String className;
  final List<SubclassFeature> features;

  Subclass({
    required super.id,
    required super.name,
    required super.source,
    required super.description,
    required super.legacy,
    required super.tags,
    required this.className,
    required this.features,
  });

  factory Subclass.fromJson(Map<String, dynamic> json) {
    var featuresList = json['features'] as List? ?? [];
    List<SubclassFeature> parsedFeatures = featuresList
        .map((f) => SubclassFeature.fromJson(f as Map<String, dynamic>))
        .toList();

    return Subclass(
      id: json['id'] as int,
      name: json['name'] as String,
      source: json['source'] as String? ?? 'Unknown Source',
      description: json['description'] as String? ?? '',
      legacy: json['legacy'] as bool? ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      className: json['class_name'] as String? ?? 'Fighter',
      features: parsedFeatures,
    );
  }
}

// 7. Equipment Model
class Equipment extends CatalogItem {
  final String category;
  final String? subCategory;
  final String cost;
  final String weight;
  final String? damage;
  final List<String> properties;
  final String? mastery;

  Equipment({
    required super.id,
    required super.name,
    required super.source,
    required super.description,
    required super.legacy,
    required super.tags,
    required this.category,
    this.subCategory,
    required this.cost,
    required this.weight,
    this.damage,
    required this.properties,
    this.mastery,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] as int,
      name: json['name'] as String,
      source: json['source'] as String? ?? 'Unknown Source',
      description: json['description'] as String? ?? '',
      legacy: json['legacy'] as bool? ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'] as String? ?? 'Adventuring Gear',
      subCategory: json['sub_category'] as String?,
      cost: json['cost'] as String? ?? '1 cp',
      weight: json['weight'] as String? ?? '—',
      damage: json['damage'] as String?,
      properties: List<String>.from(json['properties'] ?? []),
      mastery: json['mastery'] as String?,
    );
  }
}

// 8. Magic Item Model
class MagicItem extends CatalogItem {
  final String type;
  final String rarity;
  final String attunement;
  final String price;

  MagicItem({
    required super.id,
    required super.name,
    required super.source,
    required super.description,
    required super.legacy,
    required super.tags,
    required this.type,
    required this.rarity,
    required this.attunement,
    required this.price,
  });

  factory MagicItem.fromJson(Map<String, dynamic> json) {
    return MagicItem(
      id: json['id'] as int,
      name: json['name'] as String,
      source: json['source'] as String? ?? 'Unknown Source',
      description: json['description'] as String? ?? '',
      legacy: json['legacy'] as bool? ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      type: json['type'] as String? ?? 'Wondrous Item',
      rarity: json['rarity'] as String? ?? 'Uncommon',
      attunement: json['attunement'] as String? ?? 'No',
      price: json['price'] as String? ?? 'Varies',
    );
  }
}

// 9. Global Search Result Model
class GlobalSearchResult extends CatalogItem {
  final String type; // The table name (e.g. 'spells', 'classes', etc.)

  GlobalSearchResult({
    required super.id,
    required super.name,
    required super.source,
    required super.description,
    required super.legacy,
    required super.tags,
    required this.type,
  });

  factory GlobalSearchResult.fromJson(Map<String, dynamic> json) {
    return GlobalSearchResult(
      id: json['id'] as int,
      name: json['name'] as String,
      source: json['source'] as String? ?? 'Unknown Source',
      description: json['description'] as String? ?? '',
      legacy: json['legacy'] as bool? ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      type: json['type'] as String? ?? 'unknown',
    );
  }
}

// 10. Action Model
class ActionItem extends CatalogItem {
  ActionItem({
    required super.id,
    required super.name,
    required super.source,
    required super.description,
    required super.legacy,
    required super.tags,
  });

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    return ActionItem(
      id: json['id'] as int,
      name: json['name'] as String,
      source: json['source'] as String? ?? 'PHB 2024',
      description: json['description'] as String? ?? '',
      legacy: json['legacy'] as bool? ?? false,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}


