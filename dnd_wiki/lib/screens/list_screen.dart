import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/catalog_item.dart';
import '../services/api_service.dart';
import '../utils/translation_helper.dart';
import 'detail_screen.dart';
import 'detail_popup.dart';

class ListScreen extends StatefulWidget {
  final String categoryName;
  final String dbTable;
  final Color themeColor;
  final String initialSchema;

  const ListScreen({
    super.key,
    required this.categoryName,
    required this.dbTable,
    required this.themeColor,
    this.initialSchema = 'official',
  });

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _currentSchema = 'official'; // Default schema
  List<CatalogItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _currentSchema = widget.initialSchema;
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({String search = ''}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await ApiService.fetchItems(
        table: widget.dbTable,
        schema: _currentSchema,
        search: search,
      );
      setState(() {
        _items = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        _items = [];
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchData(search: query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isUaAllowed = ['spells', 'feats', 'classes', 'subclasses', 'magic_items'].contains(widget.dbTable);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          TranslationHelper.translate(widget.categoryName, ApiService.currentLanguage),
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Search Input
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: TranslationHelper.translate('Search by name or description...', ApiService.currentLanguage),
                  hintStyle: GoogleFonts.inter(color: Colors.blueGrey.shade500),
                  prefixIcon: Icon(Icons.search_rounded, color: widget.themeColor),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.blueGrey),
                          onPressed: () {
                            _searchController.clear();
                            _fetchData();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF1E293B).withOpacity(0.5),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.blueGrey.shade800, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: widget.themeColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Schema toggle (Official vs UA)
              if (isUaAllowed)
                Row(
                  children: [
                    Expanded(
                      child: _buildSchemaButton('official', TranslationHelper.translate('Official Only', ApiService.currentLanguage)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSchemaButton('all', TranslationHelper.translate('Include UA', ApiService.currentLanguage)),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              // List items
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: widget.themeColor),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 16),
                              ),
                            ),
                          )
                        : _items.isEmpty
                            ? Center(
                                child: Text(
                                  TranslationHelper.translate('No entries found.', ApiService.currentLanguage),
                                  style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: _items.length,
                                itemBuilder: (context, index) {
                                  final item = _items[index];
                                  return _buildItemCard(item);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchemaButton(String schema, String label) {
    final isSelected = _currentSchema == schema;
    return GestureDetector(
      onTap: () {
        if (_currentSchema != schema) {
          setState(() {
            _currentSchema = schema;
          });
          _fetchData(search: _searchController.text);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [widget.themeColor.withOpacity(0.8), widget.themeColor])
              : null,
          color: isSelected ? null : const Color(0xFF1E293B).withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? widget.themeColor : Colors.blueGrey.shade800,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.blueGrey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(CatalogItem item) {
    return Card(
      color: const Color(0xFF1E293B).withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.blueGrey.shade800.withOpacity(0.6), width: 1.5),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (item is Class || item is Subclass) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(item: item, themeColor: widget.themeColor),
              ),
            );
          } else {
            DetailPopup.show(context, item: item, themeColor: widget.themeColor);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header line
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (item.legacy)
                    _buildBadge(TranslationHelper.translate('LEGACY', ApiService.currentLanguage), Colors.redAccent, Colors.redAccent.withOpacity(0.12))
                  else if (item.source.contains('UA') || item.source.contains('Playtest'))
                    _buildBadge(TranslationHelper.translate('PLAYTEST', ApiService.currentLanguage), Colors.amberAccent, Colors.amberAccent.withOpacity(0.12)),
                ],
              ),
              const SizedBox(height: 6),
              // Subtitle metadata row
              _buildMetadataRow(item),
              const SizedBox(height: 10),
              // Description snippet
              Text(
                item.description.length > 140
                    ? '${item.description.substring(0, 137).trim()}...'
                    : item.description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.blueGrey.shade400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMetadataRow(CatalogItem item) {
    final lang = ApiService.currentLanguage;
    // Return specific meta descriptors based on item types
    if (item is Spell) {
      final lvlStr = item.level == 0 
          ? TranslationHelper.translate('Cantrip', lang) 
          : TranslationHelper.translate('Level ${item.level}', lang);
      final schoolStr = TranslationHelper.translate(item.school, lang);
      return Text(
        '$lvlStr • $schoolStr',
        style: GoogleFonts.inter(color: widget.themeColor, fontWeight: FontWeight.w600, fontSize: 13),
      );
    } else if (item is Feat) {
      final catStr = TranslationHelper.translate(item.category, lang);
      return Text(
        catStr,
        style: GoogleFonts.inter(color: widget.themeColor, fontWeight: FontWeight.w600, fontSize: 13),
      );
    } else if (item is MagicItem) {
      final typeStr = TranslationHelper.translate(item.type, lang);
      final rarityStr = TranslationHelper.translate(item.rarity, lang);
      return Text(
        '$typeStr • $rarityStr',
        style: GoogleFonts.inter(color: widget.themeColor, fontWeight: FontWeight.w600, fontSize: 13),
      );
    } else if (item is Equipment) {
      final catStr = TranslationHelper.translate(item.category, lang);
      return Text(
        '$catStr • ${item.cost}',
        style: GoogleFonts.inter(color: widget.themeColor, fontWeight: FontWeight.w600, fontSize: 13),
      );
    } else if (item is Subclass) {
      final classStr = TranslationHelper.translate('Subclass of ${item.className}', lang);
      return Text(
        classStr,
        style: GoogleFonts.inter(color: widget.themeColor, fontWeight: FontWeight.w600, fontSize: 13),
      );
    } else if (item is ActionItem) {
      return Text(
        TranslationHelper.translate('Action', lang),
        style: GoogleFonts.inter(color: widget.themeColor, fontWeight: FontWeight.w600, fontSize: 13),
      );
    }
    
    // Fallback source descriptor
    final sourceStr = TranslationHelper.translate(item.source, lang);
    return Text(
      sourceStr,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500, fontSize: 12),
    );
  }
}
