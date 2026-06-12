import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/catalog_item.dart';

class ApiService {
  static const String baseUrl = 'https://xculeusuctxdujcevnwv.supabase.co/functions/v1/dnd-catalog';
  static String currentLanguage = 'en';

  // Fetches catalog items dynamically from the Edge Function
  static Future<List<CatalogItem>> fetchItems({
    required String table,
    required String schema,
    String search = '',
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      'table': table,
      'schema': schema,
      if (search.isNotEmpty) 'search': search,
      'limit': limit.toString(),
      'offset': offset.toString(),
      'lang': currentLanguage,
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        switch (table) {
          case 'spells':
            return data.map((json) => Spell.fromJson(json as Map<String, dynamic>)).toList();
          case 'species':
            return data.map((json) => Species.fromJson(json as Map<String, dynamic>)).toList();
          case 'feats':
            return data.map((json) => Feat.fromJson(json as Map<String, dynamic>)).toList();
          case 'backgrounds':
            return data.map((json) => Background.fromJson(json as Map<String, dynamic>)).toList();
          case 'classes':
            return data.map((json) => Class.fromJson(json as Map<String, dynamic>)).toList();
          case 'subclasses':
            return data.map((json) => Subclass.fromJson(json as Map<String, dynamic>)).toList();
          case 'equipment':
            return data.map((json) => Equipment.fromJson(json as Map<String, dynamic>)).toList();
          case 'magic_items':
            return data.map((json) => MagicItem.fromJson(json as Map<String, dynamic>)).toList();
          case 'actions':
            return data.map((json) => ActionItem.fromJson(json as Map<String, dynamic>)).toList();
          case 'global':
            return data.map((json) => GlobalSearchResult.fromJson(json as Map<String, dynamic>)).toList();
          default:
            throw Exception('Unsupported table type: $table');
        }
      } else {
        final Map<String, dynamic> errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'API responded with status code ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Fetches a single catalog item by ID from the Edge Function
  static Future<CatalogItem> fetchItemById({
    required String table,
    required String schema,
    required int id,
  }) async {
    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      'table': table,
      'schema': schema,
      'id': id.toString(),
      'lang': currentLanguage,
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isEmpty) throw Exception('Item not found');
        final itemJson = data.first as Map<String, dynamic>;
        
        switch (table) {
          case 'spells':
            return Spell.fromJson(itemJson);
          case 'species':
            return Species.fromJson(itemJson);
          case 'feats':
            return Feat.fromJson(itemJson);
          case 'backgrounds':
            return Background.fromJson(itemJson);
          case 'classes':
            return Class.fromJson(itemJson);
          case 'subclasses':
            return Subclass.fromJson(itemJson);
          case 'equipment':
            return Equipment.fromJson(itemJson);
          case 'magic_items':
            return MagicItem.fromJson(itemJson);
          case 'actions':
            return ActionItem.fromJson(itemJson);
          default:
            throw Exception('Unsupported table type: $table');
        }
      } else {
        final Map<String, dynamic> errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'API responded with status code ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Fetches all keywords for dynamic hyperlinking
  static Future<List<Map<String, dynamic>>> fetchKeywords() async {
    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      'table': 'keywords',
      'schema': 'all',
      'lang': currentLanguage,
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final Map<String, dynamic> errorBody = json.decode(response.body);
        throw Exception(errorBody['error'] ?? 'API responded with status code ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
