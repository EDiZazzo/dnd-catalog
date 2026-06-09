import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/catalog_item.dart';
import '../services/api_service.dart';
import '../utils/translation_helper.dart';
import '../utils/summons_helper.dart';
import 'widgets/linked_text.dart';

class DetailScreen extends StatelessWidget {
  final CatalogItem item;
  final Color themeColor;

  const DetailScreen({
    super.key,
    required this.item,
    required this.themeColor,
  });

  String _getTableForItem(CatalogItem item) {
    if (item is Spell) return 'spells';
    if (item is Species) return 'species';
    if (item is Feat) return 'feats';
    if (item is Background) return 'backgrounds';
    if (item is Class) return 'classes';
    if (item is Subclass) return 'subclasses';
    if (item is Equipment) return 'equipment';
    if (item is MagicItem) return 'magic_items';
    if (item is GlobalSearchResult) return item.type;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          TranslationHelper.translate(_getItemTypeName(), ApiService.currentLanguage),
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF020617),
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Line
              Text(
                item.name,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              // Source Citation
              Text(
                '${TranslationHelper.translate('Source', ApiService.currentLanguage)}: ${TranslationHelper.translate(item.source, ApiService.currentLanguage)}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey.shade400,
                ),
              ),
              const SizedBox(height: 16),

              // Legacy Warning Alert
              if (item.legacy) _buildLegacyWarningAlert(),

              // Quick Specs Grid/Cards depending on category
              _buildSpecsSection(),
              const SizedBox(height: 20),

              // Description section
              Text(
                TranslationHelper.translate('Description', ApiService.currentLanguage),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueGrey.shade800, width: 1.5),
                ),
                child: LinkedText(
                  text: item.description.isNotEmpty ? item.description : TranslationHelper.translate('No description available.', ApiService.currentLanguage),
                  excludeItemId: item.id,
                  excludeItemTable: _getTableForItem(item),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.blueGrey.shade300,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Type specific lists (Traits, Benefits, Features)
              _buildSpecificSection(),

              // Summonable creatures / pets statistics
              _buildSummonsSection(),

              // Tags
              if (item.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Tags',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.tags.map((tag) => _buildTagChip(tag)).toList(),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegacyWarningAlert() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslationHelper.translate('Legacy Playtest Material', ApiService.currentLanguage),
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  TranslationHelper.translate('This playtest version has been superseded by a newer playtest iteration or officially released in the 2024 Player\'s Handbook.', ApiService.currentLanguage),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.blueGrey.shade300,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade800, width: 1),
      ),
      child: Text(
        tag,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.blueGrey.shade400,
        ),
      ),
    );
  }

  Widget _buildSpecsSection() {
    final Map<String, String> specs = {};

    if (item is Spell) {
      final s = item as Spell;
      specs['Level'] = s.level == 0 ? 'Cantrip' : 'Level ${s.level}';
      specs['School'] = s.school;
      specs['Casting Time'] = s.castingTime;
      specs['Range'] = s.range;
      specs['Components'] = s.components;
      specs['Duration'] = s.duration;
    } else if (item is Species) {
      final sp = item as Species;
      specs['Creature Type'] = sp.creatureType;
      specs['Size'] = sp.size;
      specs['Speed'] = sp.speed;
    } else if (item is Feat) {
      final f = item as Feat;
      specs['Category'] = f.category;
      if (f.prerequisite != null) specs['Prerequisites'] = f.prerequisite!;
    } else if (item is Background) {
      final b = item as Background;
      specs['Ability Scores'] = b.abilityScores;
      specs['Feat'] = b.feat;
      specs['Skills'] = b.skillProficiencies;
      specs['Tools'] = b.toolProficiencies;
    } else if (item is Class) {
      final c = item as Class;
      specs['Primary Ability'] = c.primaryAbility;
      specs['Hit Dice'] = c.hitDice;
      specs['Saves'] = c.savingThrows.join(', ');
    } else if (item is Subclass) {
      final sub = item as Subclass;
      specs['Base Class'] = sub.className;
    } else if (item is Equipment) {
      final eq = item as Equipment;
      specs['Category'] = eq.category;
      if (eq.subCategory != null) specs['Sub-Category'] = eq.subCategory!;
      specs['Cost'] = eq.cost;
      specs['Weight'] = eq.weight;
      if (eq.damage != null) specs['Damage'] = eq.damage!;
      if (eq.mastery != null) specs['Mastery'] = eq.mastery!;
    } else if (item is MagicItem) {
      final mi = item as MagicItem;
      specs['Type'] = mi.type;
      specs['Rarity'] = mi.rarity;
      specs['Attunement'] = mi.attunement;
      specs['Price'] = mi.price;
    }

    if (specs.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.7,
      ),
      itemCount: specs.length,
      itemBuilder: (context, index) {
        final key = specs.keys.elementAt(index);
        final value = specs[key]!;
        final lang = ApiService.currentLanguage;
        final translatedKey = TranslationHelper.translate(key, lang);
        final translatedValue = TranslationHelper.translate(value, lang);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueGrey.shade800, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                translatedKey,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: themeColor.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                translatedValue,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getItemTypeName() {
    if (item is Spell) return 'Spell Detail';
    if (item is Species) return 'Species Detail';
    if (item is Feat) return 'Feat Detail';
    if (item is Background) return 'Background Detail';
    if (item is Class) return 'Class Detail';
    if (item is Subclass) return 'Subclass Detail';
    if (item is Equipment) return 'Equipment Detail';
    if (item is MagicItem) return 'Magic Item Detail';
    return 'Detail';
  }

  Widget _buildSpecificSection() {
    final lang = ApiService.currentLanguage;
    if (item is Spell && (item as Spell).upgrades != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationHelper.translate('At Higher Levels / Upgrades', lang),
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: themeColor.withOpacity(0.25), width: 1.5),
            ),
            child: LinkedText(
              text: (item as Spell).upgrades!,
              excludeItemId: item.id,
              excludeItemTable: _getTableForItem(item),
              style: GoogleFonts.inter(fontSize: 14, color: Colors.blueGrey.shade300, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
    }

    if (item is Species && (item as Species).traits.isNotEmpty) {
      final s = item as Species;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationHelper.translate('Species Traits', lang),
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          ...s.traits.map((t) => _buildDetailBlock(t.name, t.description)),
        ],
      );
    }

    if (item is Feat && (item as Feat).benefits.isNotEmpty) {
      final f = item as Feat;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationHelper.translate('Feat Benefits', lang),
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          ...f.benefits.map((b) => _buildDetailBlock(b.name, b.description)),
        ],
      );
    }

    if (item is Class) {
      final c = item as Class;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClassProficiencies(c),
          _buildClassTableSection(c),
          _buildClassFeaturesSection(c),
        ],
      );
    }

    if (item is Subclass && (item as Subclass).features.isNotEmpty) {
      final sub = item as Subclass;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationHelper.translate('Subclass Features', lang),
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          ...sub.features.map(
            (feat) => _buildDetailBlock(
              '${feat.name} (Level ${feat.level})',
              feat.description,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildClassProficiencies(Class c) {
    final lang = ApiService.currentLanguage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationHelper.translate('Proficiencies', lang),
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueGrey.shade800, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProficiencyRow(TranslationHelper.translate('Weapons', lang), c.weaponProficiencies),
              const Divider(color: Colors.blueGrey, height: 20, thickness: 0.5),
              _buildProficiencyRow(TranslationHelper.translate('Armor', lang), c.armorProficiencies),
              const Divider(color: Colors.blueGrey, height: 20, thickness: 0.5),
              _buildProficiencyRow(TranslationHelper.translate('Tools', lang), c.toolProficiencies),
              const Divider(color: Colors.blueGrey, height: 20, thickness: 0.5),
              _buildProficiencyRow(TranslationHelper.translate('Skills', lang), c.skillProficiencies),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProficiencyRow(String label, List<String> items) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
        ),
        Expanded(
          child: Text(
            items.isEmpty ? TranslationHelper.translate('None', ApiService.currentLanguage) : items.join(', '),
            style: GoogleFonts.inter(fontSize: 14, color: Colors.blueGrey.shade300),
          ),
        ),
      ],
    );
  }

  Widget _buildClassTableSection(Class c) {
    if (c.classTable.headers.isEmpty || c.classTable.rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final lang = ApiService.currentLanguage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationHelper.translate('Class Progression', lang),
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueGrey.shade800, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(const Color(0xFF1E293B).withOpacity(0.6)),
              dataRowMinHeight: 48,
              dataRowMaxHeight: 64,
              columnSpacing: 20,
              columns: c.classTable.headers.map((header) {
                return DataColumn(
                  label: Text(
                    TranslationHelper.translate(header, lang),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF818CF8),
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              rows: c.classTable.rows.map((row) {
                return DataRow(
                  cells: row.map((cell) {
                    return DataCell(
                      Text(
                        cell,
                        style: GoogleFonts.inter(
                          color: Colors.blueGrey.shade200,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildClassFeaturesSection(Class c) {
    if (c.features.isEmpty) return const SizedBox.shrink();

    final lang = ApiService.currentLanguage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationHelper.translate('Class Features', lang),
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),
        ...c.features.map(
          (feat) => _buildDetailBlock(
            '${feat.name} (Level ${feat.level})',
            feat.description,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailBlock(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade800, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          LinkedText(
            text: content,
            excludeItemId: item.id,
            excludeItemTable: _getTableForItem(item),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.blueGrey.shade300,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummonsSection() {
    if (item is! Spell) return const SizedBox.shrink();
    
    final lang = ApiService.currentLanguage;
    final summons = SummonsHelper.getSummonsForSpell(item.name, lang);
    if (summons.isEmpty) return const SizedBox.shrink();
    
    final sectionTitle = lang == 'it' 
        ? 'Creature Evocabili / Statistiche' 
        : (lang == 'da' ? 'Fremkaldelige Væsener' : 'Summonable Creatures');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          sectionTitle,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: summons.length,
          itemBuilder: (context, index) {
            final creature = summons[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: themeColor.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          creature.name,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: themeColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          creature.type,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (creature.lore.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      creature.lore,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                  ],
                  const Divider(color: Colors.blueGrey, height: 20, thickness: 0.5),
                  
                  // AC, HP, Speed, Senses
                  _buildCreatureSpecRow(lang == 'it' ? 'CA' : (lang == 'da' ? 'AC' : 'AC'), creature.ac, lang == 'it' ? 'PF' : (lang == 'da' ? 'HP' : 'HP'), creature.hp),
                  const SizedBox(height: 8),
                  _buildCreatureSpecRow(lang == 'it' ? 'Velocità' : (lang == 'da' ? 'Hastighed' : 'Speed'), creature.speed, lang == 'it' ? 'Sensi' : (lang == 'da' ? 'Sanser' : 'Senses'), creature.senses),
                  
                  if (creature.resistances.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildSingleCreatureSpec(lang == 'it' ? 'Resistenze' : (lang == 'da' ? 'Modstande' : 'Resistances'), creature.resistances),
                  ],
                  
                  const SizedBox(height: 12),
                  // Abilities Block
                  _buildCreatureAbilities(creature.abilities),
                  
                  if (creature.actions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      lang == 'it' ? 'Azioni' : (lang == 'da' ? 'Handlinger' : 'Actions'),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...creature.actions.map((act) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${act.name}: ',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: act.description,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.blueGrey.shade300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCreatureSpecRow(String key1, String val1, String key2, String val2) {
    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$key1: ',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade400),
                ),
                TextSpan(
                  text: val1,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$key2: ',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade400),
                ),
                TextSpan(
                  text: val2,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleCreatureSpec(String key, String val) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$key: ',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade400),
          ),
          TextSpan(
            text: val,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatureAbilities(Map<String, int> ab) {
    final names = ['STR', 'DEX', 'CON', 'INT', 'WIS', 'CHA'];
    final keys = ['str', 'dex', 'con', 'int', 'wis', 'cha'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(6, (index) {
          final score = ab[keys[index]] ?? 10;
          final mod = (score - 10) ~/ 2;
          final modSign = mod >= 0 ? '+' : '';
          return Column(
            children: [
              Text(
                names[index],
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade400),
              ),
              const SizedBox(height: 2),
              Text(
                '$score ($modSign$mod)',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          );
        }),
      ),
    );
  }
}
