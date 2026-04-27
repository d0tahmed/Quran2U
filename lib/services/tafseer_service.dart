import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TafseerEntry {
  final int ayahNumber;
  final String verseKey;
  final String text;

  const TafseerEntry({
    required this.ayahNumber,
    required this.verseKey,
    required this.text,
  });
}
// Service to fetch and cache tafseer (exegesis) for Quranic verses from the Quran.com API. 
class TafseerService {
  static const String _baseUrl = 'https://api.quran.com/api/v4';

  // ── Tafsir IDs ────────────────────────────────────────────────────────────
  // Call GET /tafsirs to see the full list and verify these IDs.
  static const int ibnKathirEnglishId  = 169;
  static const int maarifulQuranUrduId = 168;

  final Dio _dio;

  TafseerService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: _baseUrl));

  Future<List<TafseerEntry>> fetchTafseerForSurah({
    required int surahNumber,
    required int tafsirId,
  }) async {
    final cacheKey = 'tafseer_${surahNumber}_${tafsirId}_v1';

    // Return cached if available
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        final list = jsonDecode(cached) as List;
        return list
            .map((e) => TafseerEntry(
                  ayahNumber: e['ayah'] as int,
                  verseKey: e['verse_key'] as String,
                  text: e['text'] as String,
                ))
            .toList();
      }
    } catch (_) {}

    // Fetch from API with pagination
    try {
      final List<TafseerEntry> entries = [];
      int page = 1;
      int totalPages = 1;

      do {
        final response = await _dio.get(
          '/tafsirs/$tafsirId/by_chapter/$surahNumber',
          queryParameters: {'page': page, 'per_page': 50},
        );

        if (response.statusCode == 200) {
          final tafsirs = response.data['tafsirs'] as List;
          for (final t in tafsirs) {
            final rawText = t['text'] as String? ?? '';
            entries.add(TafseerEntry(
              ayahNumber: _parseAyahNumber(t['verse_key']),
              verseKey: t['verse_key'] as String? ?? '',
              text: _stripHtml(rawText),
            ));
          }
          totalPages = response.data['pagination']?['total_pages'] ?? 1;
          page++;
        } else {
          throw Exception('API error ${response.statusCode}');
        }
      } while (page <= totalPages);

      // Cache the result
      try {
        final prefs = await SharedPreferences.getInstance();
        final toCache = entries
            .map((e) => {
                  'ayah': e.ayahNumber,
                  'verse_key': e.verseKey,
                  'text': e.text,
                })
            .toList();
        await prefs.setString(cacheKey, jsonEncode(toCache));
      } catch (_) {}

      return entries;
    } catch (e) {
      throw Exception('Error fetching tafseer: $e');
    }
  }

  int _parseAyahNumber(dynamic verseKey) {
    if (verseKey == null) return 0;
    final parts = verseKey.toString().split(':');
    if (parts.length < 2) return 0;
    return int.tryParse(parts[1]) ?? 0;
  }

  static String _stripHtml(String html) {
    var clean = html.replaceAll(
        RegExp(r'<sup[^>]*>.*?<\/sup>', caseSensitive: false, dotAll: true), '');
    clean = clean.replaceAll(
        RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    clean = clean.replaceAll(RegExp(r'<[^>]*>'), '');
    return clean
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}