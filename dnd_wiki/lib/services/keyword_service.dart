import 'api_service.dart';

class KeywordService {
  // Singleton pattern
  static final KeywordService _instance = KeywordService._internal();
  factory KeywordService() => _instance;
  KeywordService._internal();

  List<Map<String, dynamic>> _keywords = [];
  RegExp? _regex;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  // Initialize service by fetching all keywords from database
  Future<void> initialize({bool force = false}) async {
    if (_initialized && !force) return;
    _initialized = false;

    try {
      final data = await ApiService.fetchKeywords();
      _keywords = data;

      // Sort keywords descending by name length to match longer names first
      // E.g., matching "Holy Aura" before "Aura"
      _keywords.sort((a, b) {
        final String nameA = a['name'] as String? ?? '';
        final String nameB = b['name'] as String? ?? '';
        return nameB.length.compareTo(nameA.length);
      });

      _buildRegex();
      _initialized = true;
      print('KeywordService initialized successfully with ${_keywords.length} keywords.');
    } catch (e) {
      print('KeywordService failed to initialize: $e');
    }
  }

  // Compile sorted keywords into a single case-insensitive RegExp
  void _buildRegex() {
    if (_keywords.isEmpty) {
      _regex = null;
      return;
    }

    final escapedNames = _keywords.map((k) {
      final String name = k['name'] as String? ?? '';
      return RegExp.escape(name);
    }).join('|');

    // Use word boundaries \b to prevent matching keywords inside larger words
    _regex = RegExp('\\b($escapedNames)\\b', caseSensitive: false);
  }

  // Match keyword case-insensitively and return metadata
  Map<String, dynamic>? findKeyword(String text) {
    final lowerText = text.toLowerCase().trim();
    for (final k in _keywords) {
      final String kName = (k['name'] as String? ?? '').toLowerCase().trim();
      if (kName == lowerText) {
        return k;
      }
    }
    return null;
  }

  // Parses a text string and returns a list of segments
  // Segments are either plain text or matches: { 'text': String, 'isKeyword': bool, 'keyword': Map? }
  List<Map<String, dynamic>> parseText(String text) {
    if (!_initialized || _regex == null || text.isEmpty) {
      return [
        {'text': text, 'isKeyword': false, 'keyword': null}
      ];
    }

    final List<Map<String, dynamic>> segments = [];
    final matches = _regex!.allMatches(text);

    int lastMatchEnd = 0;
    for (final match in matches) {
      // Add plain text before match
      if (match.start > lastMatchEnd) {
        segments.add({
          'text': text.substring(lastMatchEnd, match.start),
          'isKeyword': false,
          'keyword': null,
        });
      }

      final matchText = match.group(0)!;
      final keywordMeta = findKeyword(matchText);

      if (keywordMeta != null) {
        segments.add({
          'text': matchText,
          'isKeyword': true,
          'keyword': keywordMeta,
        });
      } else {
        // Fallback if metadata lookup fails (should not happen)
        segments.add({
          'text': matchText,
          'isKeyword': false,
          'keyword': null,
        });
      }

      lastMatchEnd = match.end;
    }

    // Add trailing plain text
    if (lastMatchEnd < text.length) {
      segments.add({
        'text': text.substring(lastMatchEnd),
        'isKeyword': false,
        'keyword': null,
      });
    }

    return segments;
  }
}
