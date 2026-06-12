import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/catalog_item.dart';
import '../utils/translation_helper.dart';
import '../utils/summons_helper.dart';
import 'detail_screen.dart';

import '../services/api_service.dart';
import 'widgets/linked_text.dart';

class DetailPopup extends StatefulWidget {
  final CatalogItem? item;
  final int? id;
  final String? table;
  final String? schema;
  final Color themeColor;

  const DetailPopup({
    super.key,
    this.item,
    this.id,
    this.table,
    this.schema,
    required this.themeColor,
  });

  static void show(
    BuildContext context, {
    CatalogItem? item,
    int? id,
    String? table,
    String? schema,
    required Color themeColor,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) => DetailPopup(
        item: item,
        id: id,
        table: table,
        schema: schema,
        themeColor: themeColor,
      ),
    );
  }

  @override
  State<DetailPopup> createState() => _DetailPopupState();
}

class _DetailPopupState extends State<DetailPopup> {
  CatalogItem? _item;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _item = widget.item;
    } else {
      _loadItem();
    }
  }

  Future<void> _loadItem() async {
    if (widget.id == null || widget.table == null || widget.schema == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final loadedItem = await ApiService.fetchItemById(
        table: widget.table!,
        schema: widget.schema!,
        id: widget.id!,
      );
      if (mounted) {
        setState(() {
          _item = loadedItem;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  CatalogItem get item => _item ?? widget.item!;
  Color get themeColor => widget.themeColor;

  String _getTableForItem(CatalogItem item) {
    if (item is Spell) return 'spells';
    if (item is Species) return 'species';
    if (item is Feat) return 'feats';
    if (item is Background) return 'backgrounds';
    if (item is Class) return 'classes';
    if (item is Subclass) return 'subclasses';
    if (item is Equipment) return 'equipment';
    if (item is MagicItem) return 'magic_items';
    if (item is ActionItem) return 'actions';
    if (item is GlobalSearchResult) return item.type;
    return widget.table ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;
    
    Widget content;
    if (_isLoading) {
      content = Container(
        height: 250,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: themeColor),
            const SizedBox(height: 16),
            Text(
              TranslationHelper.translate('Loading details...', ApiService.currentLanguage),
              style: GoogleFonts.outfit(
                color: Colors.blueGrey.shade300,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    } else if (_error != null) {
      content = Container(
        height: 250,
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              TranslationHelper.translate('Failed to load details', ApiService.currentLanguage),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.outfit(
                color: Colors.blueGrey.shade400,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadItem,
              child: Text(TranslationHelper.translate('Retry', ApiService.currentLanguage), style: TextStyle(color: themeColor)),
            ),
          ],
        ),
      );
    } else if (_item == null) {
      content = const SizedBox.shrink();
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          _buildHeader(context),
          
          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Specs Grid
                  _buildSpecsSection(),
                  const SizedBox(height: 20),
                  
                  // Description Title
                  Text(
                    TranslationHelper.translate('Description', ApiService.currentLanguage),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description Body
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueGrey.shade900, width: 1.5),
                    ),
                    child: LinkedText(
                      text: item.description.isNotEmpty ? item.description : TranslationHelper.translate('No description available.', ApiService.currentLanguage),
                      excludeItemId: item.id,
                      excludeItemTable: _getTableForItem(item),
                      style: GoogleFonts.inter(
                        fontSize: 14.2,
                        color: Colors.blueGrey.shade200,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Type specific detail blocks (Traits, Benefits, subclass features)
                  _buildSpecificSection(),
                  
                  // Summonable creatures / pets statistics
                  _buildSummonsSection(),
                  
                  // Tags list
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      TranslationHelper.translate('Tags', ApiService.currentLanguage),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
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
                ],
              ),
            ),
          ),
          
          // Footer Action Panel
          _buildFooter(context),
        ],
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? size.width * 0.2 : 20.0,
        vertical: isDesktop ? 60.0 : 40.0,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E293B), // Slate 800
              Color(0xFF0F172A), // Slate 900
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.blueGrey.shade800,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: content,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF020617).withOpacity(0.4),
        border: Border(
          bottom: BorderSide(color: Colors.blueGrey.shade800, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item.legacy)
                      _buildBadge(TranslationHelper.translate('LEGACY', ApiService.currentLanguage), Colors.redAccent)
                    else if (item.source.contains('UA') || item.source.contains('Playtest'))
                      _buildBadge(TranslationHelper.translate('PLAYTEST', ApiService.currentLanguage), Colors.amberAccent),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${TranslationHelper.translate('Source', ApiService.currentLanguage)}: ${TranslationHelper.translate(item.source, ApiService.currentLanguage)} • ${TranslationHelper.translate(_getCategoryLabel(), ApiService.currentLanguage)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey.shade400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.blueGrey),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _getCategoryLabel() {
    if (item is Spell) return 'Spell';
    if (item is Species) return 'Species';
    if (item is Feat) return 'Feat';
    if (item is Background) return 'Background';
    if (item is Class) return 'Class';
    if (item is Subclass) return 'Subclass';
    if (item is Equipment) return 'Equipment';
    if (item is MagicItem) return 'Magic Item';
    if (item is ActionItem) return 'Action';
    if (item is GlobalSearchResult) {
      final type = (item as GlobalSearchResult).type;
      return type[0].toUpperCase() + type.substring(1);
    }
    return 'Catalog Item';
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade800, width: 1),
      ),
      child: Text(
        tag,
        style: GoogleFonts.inter(
          fontSize: 11,
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
      specs['Cost'] = eq.cost;
      specs['Weight'] = eq.weight;
      if (eq.damage != null) specs['Damage'] = eq.damage!;
    } else if (item is MagicItem) {
      final mi = item as MagicItem;
      specs['Type'] = mi.type;
      specs['Rarity'] = mi.rarity;
      specs['Attunement'] = mi.attunement;
    }

    if (specs.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueGrey.shade800, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                translatedKey,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: themeColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                translatedValue,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 13,
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

  Widget _buildSpecificSection() {
    final lang = ApiService.currentLanguage;
    if (item is Spell && (item as Spell).upgrades != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationHelper.translate('At Higher Levels / Upgrades', lang),
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          _buildDetailBlock(TranslationHelper.translate('Upgrades', lang), (item as Spell).upgrades!),
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
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
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
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          ...f.benefits.map((b) => _buildDetailBlock(b.name, b.description)),
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
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
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

  Widget _buildDetailBlock(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade800, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.blueGrey.shade300,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final lang = ApiService.currentLanguage;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF020617).withOpacity(0.4),
        border: Border(
          top: BorderSide(color: Colors.blueGrey.shade800, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              TranslationHelper.translate('Close', lang),
              style: GoogleFonts.outfit(
                color: Colors.blueGrey.shade300,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Only show full page navigation for native models (not dummy GlobalSearchResult itself unless mapped, but we can map it)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(
                    item: item,
                    themeColor: themeColor,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              TranslationHelper.translate('View Full Page', lang),
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
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
            fontSize: 15,
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
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
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
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: themeColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          creature.type,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (creature.lore.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      creature.lore,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                  ],
                  const Divider(color: Colors.blueGrey, height: 16, thickness: 0.5),
                  
                  // AC, HP, Speed, Senses
                  _buildCreatureSpecRow(lang == 'it' ? 'CA' : (lang == 'da' ? 'AC' : 'AC'), creature.ac, lang == 'it' ? 'PF' : (lang == 'da' ? 'HP' : 'HP'), creature.hp),
                  const SizedBox(height: 6),
                  _buildCreatureSpecRow(lang == 'it' ? 'Velocità' : (lang == 'da' ? 'Hastighed' : 'Speed'), creature.speed, lang == 'it' ? 'Sensi' : (lang == 'da' ? 'Sanser' : 'Senses'), creature.senses),
                  
                  if (creature.resistances.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildSingleCreatureSpec(lang == 'it' ? 'Resistenze' : (lang == 'da' ? 'Modstande' : 'Resistances'), creature.resistances),
                  ],
                  
                  const SizedBox(height: 10),
                  // Abilities Block
                  _buildCreatureAbilities(creature.abilities),
                  
                  if (creature.actions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      lang == 'it' ? 'Azioni' : (lang == 'da' ? 'Handlinger' : 'Actions'),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...creature.actions.map((act) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${act.name}: ',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: act.description,
                              style: GoogleFonts.inter(
                                fontSize: 12,
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
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade400),
                ),
                TextSpan(
                  text: val1,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
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
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade400),
                ),
                TextSpan(
                  text: val2,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
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
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade400),
          ),
          TextSpan(
            text: val,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatureAbilities(Map<String, int> ab) {
    final names = ['STR', 'DEX', 'CON', 'INT', 'WIS', 'CHA'];
    final keys = ['str', 'dex', 'con', 'int', 'wis', 'cha'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade400),
              ),
              const SizedBox(height: 2),
              Text(
                '$score ($modSign$mod)',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          );
        }),
      ),
    );
  }
}
