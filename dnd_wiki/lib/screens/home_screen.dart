import 'dart:async';
import 'dart:ui'; // Added for BackdropFilter
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/catalog_item.dart';
import '../services/api_service.dart';
import '../services/keyword_service.dart';
import '../utils/translation_helper.dart';
import 'list_screen.dart';
import 'detail_popup.dart';
import 'detail_screen.dart';

class CategoryInfo {
  final String name;
  final String dbTable;
  final IconData icon;
  final int officialCount;
  final int uaCount;
  final Color color;

  CategoryInfo({
    required this.name,
    required this.dbTable,
    required this.icon,
    required this.officialCount,
    required this.uaCount,
    required this.color,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<GlobalSearchResult> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  Timer? _debounce;
  bool _includeUa = false; // Global schema search toggle
  bool _isChangingLanguage = false;

  void _setLanguage(String newLang) async {
    if (ApiService.currentLanguage == newLang) return;

    setState(() {
      _isChangingLanguage = true;
    });

    ApiService.currentLanguage = newLang;

    try {
      await KeywordService().initialize(force: true);
    } catch (e) {
      print('Failed to reinitialize keywords: $e');
    }

    if (mounted) {
      setState(() {
        _isChangingLanguage = false;
      });
      if (_searchQuery.isNotEmpty) {
        _performGlobalSearch(_searchQuery);
      }
    }
  }

  final List<CategoryInfo> categories = [
    CategoryInfo(
      name: 'Spells',
      dbTable: 'spells',
      icon: Icons.auto_stories_rounded,
      officialCount: 419,
      uaCount: 0,
      color: const Color(0xFFC084FC), // Lavender purple
    ),
    CategoryInfo(
      name: 'Classes',
      dbTable: 'classes',
      icon: Icons.shield_rounded,
      officialCount: 13,
      uaCount: 0,
      color: const Color(0xFF60A5FA), // Soft blue
    ),
    CategoryInfo(
      name: 'Subclasses',
      dbTable: 'subclasses',
      icon: Icons.workspace_premium_rounded,
      officialCount: 70,
      uaCount: 0,
      color: const Color(0xFF818CF8), // Indigo
    ),
    CategoryInfo(
      name: 'Feats',
      dbTable: 'feats',
      icon: Icons.bolt_rounded,
      officialCount: 161,
      uaCount: 0,
      color: const Color(0xFFFBBF24), // Amber
    ),
    CategoryInfo(
      name: 'Species',
      dbTable: 'species',
      icon: Icons.pets_rounded,
      officialCount: 18,
      uaCount: 0,
      color: const Color(0xFF34D399), // Emerald green
    ),
    CategoryInfo(
      name: 'Backgrounds',
      dbTable: 'backgrounds',
      icon: Icons.account_box_rounded,
      officialCount: 53,
      uaCount: 0,
      color: const Color(0xFF2DD4BF), // Teal
    ),
    CategoryInfo(
      name: 'Equipment',
      dbTable: 'equipment',
      icon: Icons.gavel_rounded,
      officialCount: 88,
      uaCount: 0,
      color: const Color(0xFFFB923C), // Orange
    ),
    CategoryInfo(
      name: 'Magic Items',
      dbTable: 'magic_items',
      icon: Icons.key_rounded,
      officialCount: 364,
      uaCount: 0,
      color: const Color(0xFFF472B6), // Pink
    ),
    CategoryInfo(
      name: 'Actions',
      dbTable: 'actions',
      icon: Icons.directions_run_rounded,
      officialCount: 10,
      uaCount: 0,
      color: const Color(0xFFF87171), // Coral
    ),
  ];


  Color _getCategoryColor(String tableType) {
    final cat = categories.firstWhere(
      (c) => c.dbTable == tableType,
      orElse: () => CategoryInfo(
        name: 'Other',
        dbTable: 'other',
        icon: Icons.info,
        officialCount: 0,
        uaCount: 0,
        color: Colors.blueGrey,
      ),
    );
    return cat.color;
  }

  String _getCategoryDisplayName(String tableType) {
    final cat = categories.firstWhere(
      (c) => c.dbTable == tableType,
      orElse: () => CategoryInfo(
        name: 'Other',
        dbTable: 'other',
        icon: Icons.info,
        officialCount: 0,
        uaCount: 0,
        color: Colors.blueGrey,
      ),
    );
    return cat.name;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _searchResults = [];
        _isSearching = false;
        _searchError = null;
        return;
      }
    });

    if (query.trim().isNotEmpty) {
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _performGlobalSearch(query.trim());
      });
    }
  }

  Future<void> _performGlobalSearch(String query) async {
    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final results = await ApiService.fetchItems(
        table: 'global',
        schema: _includeUa ? 'all' : 'official',
        search: query,
        limit: 30,
      );
      
      setState(() {
        _searchResults = results.cast<GlobalSearchResult>();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchError = e.toString().replaceFirst('Exception: ', '');
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  void _onResultTapped(GlobalSearchResult result) async {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF818CF8)),
      ),
    );

    try {
      // Fetch full details from database using the flexible multi-schema lookup
      final fullItem = await ApiService.fetchItemById(
        table: result.type,
        schema: _includeUa ? 'all' : ((result.source.contains('UA') || result.source.contains('Playtest')) ? 'ua' : 'official'),
        id: result.id,
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss the loading dialog
        final themeColor = _getCategoryColor(result.type);
        if (fullItem is Class || fullItem is Subclass) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailScreen(item: fullItem, themeColor: themeColor),
            ),
          );
        } else {
          DetailPopup.show(context, item: fullItem, themeColor: themeColor);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'Failed to fetch details: $e',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Scaffold(
      body: Stack(
        children: [
          // Main scrollable content
          Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // Slate 900
                  Color(0xFF020617), // Slate 950
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 84.0), // Extra bottom padding for floating bar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF818CF8), Color(0xFFC084FC)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'D&D 5.5e Wiki',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '2024 Player\'s Handbook Catalog',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.blueGrey.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Language Selector Button (Dropdown)
                        Theme(
                          data: Theme.of(context).copyWith(
                            popupMenuTheme: PopupMenuThemeData(
                              color: const Color(0xFF1E293B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.blueGrey.shade800, width: 1.5),
                              ),
                            ),
                          ),
                          child: PopupMenuButton<String>(
                            onSelected: _setLanguage,
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'en',
                                child: Row(
                                  children: [
                                    const Text('🇺🇸 ', style: TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Text('English', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'it',
                                child: Row(
                                  children: [
                                    const Text('🇮🇹 ', style: TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Text('Italiano', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'da',
                                child: Row(
                                  children: [
                                    const Text('🇩🇰 ', style: TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Text('Dansk', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF818CF8).withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    ApiService.currentLanguage == 'en' 
                                        ? '🇺🇸 EN' 
                                        : ApiService.currentLanguage == 'it' 
                                            ? '🇮🇹 IT' 
                                            : '🇩🇰 DA',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.translate_rounded,
                                    color: Color(0xFF818CF8),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                     // Global Search Input
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: TranslationHelper.translate('Search spells, classes, magic items globally...', ApiService.currentLanguage),
                        hintStyle: GoogleFonts.inter(color: Colors.blueGrey.shade500),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF818CF8)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: Colors.blueGrey),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
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
                          borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Conditional Layout: Search results vs Categories grid
                    Expanded(
                      child: _searchQuery.isNotEmpty
                          ? _buildSearchResultsSection()
                          : _buildCategoriesSection(isDesktop),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Floating dynamic toggle bar placed in comfortable Thumb Zone
          Positioned(
            bottom: 20,
            left: isDesktop ? size.width * 0.28 : 24,
            right: isDesktop ? size.width * 0.28 : 24,
            child: _buildFloatingToggleBar(),
          ),
          
          if (_isChangingLanguage)
            Positioned.fill(
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Color(0xFF818CF8)),
                          const SizedBox(height: 16),
                          Text(
                            TranslationHelper.translate('Loading details...', ApiService.currentLanguage),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationHelper.translate('Explore Categories', ApiService.currentLanguage),
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: isDesktop ? 1.25 : 0.95,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _buildCategoryCard(cat);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TranslationHelper.translate('Search Results', ApiService.currentLanguage),
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _isSearching
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF818CF8)),
                )
              : _searchError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          _searchError!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 16),
                        ),
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            TranslationHelper.translate('No entries found globally.', ApiService.currentLanguage),
                            style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return _buildSearchResultCard(result);
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(CategoryInfo cat) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => ListScreen(
                categoryName: TranslationHelper.translate(cat.name, ApiService.currentLanguage),
                dbTable: cat.dbTable,
                themeColor: cat.color,
                initialSchema: _includeUa ? 'all' : 'official',
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.blueGrey.shade800,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon block
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cat.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  cat.icon,
                  color: cat.color,
                  size: 24,
                ),
              ),
              // Text & counts block
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationHelper.translate(cat.name, ApiService.currentLanguage),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildCountBadge(
                        '${cat.officialCount} ${TranslationHelper.translate('Off', ApiService.currentLanguage)}',
                        Colors.blueGrey.shade400,
                      ),
                      if (cat.uaCount > 0)
                        _buildCountBadge(
                          '${cat.uaCount} ${TranslationHelper.translate('UA', ApiService.currentLanguage)}',
                          cat.color.withOpacity(0.8),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blueGrey.shade800, width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(GlobalSearchResult result) {
    final themeColor = _getCategoryColor(result.type);
    final categoryName = _getCategoryDisplayName(result.type);

    return Card(
      color: const Color(0xFF1E293B).withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blueGrey.shade800.withOpacity(0.6), width: 1.5),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onResultTapped(result),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      result.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Category pill styled dynamically
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: themeColor.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      TranslationHelper.translate(categoryName, ApiService.currentLanguage),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                result.description.length > 140
                    ? '${result.description.substring(0, 137).trim()}...'
                    : result.description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.blueGrey.shade400,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              // Source info badge
              Text(
                '${TranslationHelper.translate('Source', ApiService.currentLanguage)}: ${TranslationHelper.translate(result.source, ApiService.currentLanguage)}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingToggleBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.6),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF818CF8).withOpacity(0.05),
                blurRadius: 16,
                spreadRadius: 2,
               ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildToggleSegment(false, TranslationHelper.translate('Official 2024', ApiService.currentLanguage), Icons.verified_rounded),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildToggleSegment(true, TranslationHelper.translate('Include UA', ApiService.currentLanguage), Icons.science_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSegment(bool value, String label, IconData icon) {
    final isSelected = _includeUa == value;
    return GestureDetector(
      onTap: () {
        if (_includeUa != value) {
          setState(() {
            _includeUa = value;
          });
          if (_searchQuery.isNotEmpty) {
            _performGlobalSearch(_searchQuery);
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF818CF8), Color(0xFFC084FC)],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF818CF8).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.blueGrey.shade400,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.blueGrey.shade300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
