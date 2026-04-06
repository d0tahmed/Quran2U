import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_recitation/models/models.dart';

class QuranApiService {
  static const String baseUrl = 'https://api.quran.com/api/v4';
  // Bumped to v2 so the corrected Surah 38 name is picked up on next launch
  static const String _surahCacheKey = 'cached_surahs_v2';

  // API returns "Sad" for Surah 38 — correct display name is "Suad"
  static const _nameOverrides = <int, String>{38: 'Suad'};

  final Dio _dio;

  QuranApiService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  // =========================================================================
  // FETCH ALL SURAHS
  // =========================================================================
  Future<List<Surah>> fetchAllSurahs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_surahCacheKey);
      if (cached != null) {
        final list = jsonDecode(cached) as List;
        return list.map((ch) => _surahFromMap(ch)).toList();
      }
    } catch (_) {}

    try {
      final response = await _dio.get('/chapters');

      if (response.statusCode == 200) {
        final chapters = response.data['chapters'] as List;
        final surahs = chapters.map((ch) => _surahFromMap(ch)).toList();

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_surahCacheKey, jsonEncode(chapters));
        } catch (_) {}

        return surahs;
      }
      throw Exception('Failed to fetch Surahs');
    } catch (e) {
      throw Exception('Error fetching Surahs: $e');
    }
  }

  Surah _surahFromMap(Map<String, dynamic> ch) {
    final id = ch['id'] as int;
    final apiName = ch['name_simple'] as String;
    return Surah(
      number: id,
      name: _nameOverrides[id] ?? apiName,
      nameArabic: ch['name_arabic'],
      nameTranslation: ch['translated_name'] != null
          ? (ch['translated_name']['name'] ?? apiName)
          : apiName,
      ayahCount: ch['verses_count'],
      revelationType: ch['revelation_place'] == 'makkah' ? 'Meccan' : 'Medinan',
    );
  }

  // =========================================================================
  // FETCH SINGLE SURAH WITH AYAHS (PAGINATED)
  // =========================================================================
  Future<Map<String, dynamic>> fetchSurahWithAyahs(
    int surahNumber, {
    int translationId = 0,
  }) async {
    final cacheKey = 'ayahs_${surahNumber}_${translationId}_v3';

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        final list = jsonDecode(cached) as List;
        return {
          'surah': surahNumber,
          'ayahs': list.map((v) => _ayahFromMap(v, surahNumber)).toList()
        };
      }
    } catch (_) {}

    final params = <String, dynamic>{
      'fields': 'text_uthmani',
      'per_page': 50,
    };
    if (translationId > 0) params['translations'] = translationId;

    try {
      int currentPage = 1;
      int totalPages = 1;
      List<dynamic> allVerses = [];

      do {
        params['page'] = currentPage;
        final response = await _dio.get('/verses/by_chapter/$surahNumber', queryParameters: params);

        if (response.statusCode == 200) {
          allVerses.addAll(response.data['verses'] as List);
          totalPages = response.data['pagination']['total_pages'] ?? 1;
          currentPage++;
        } else {
          throw Exception('Failed to fetch Ayahs page $currentPage');
        }
      } while (currentPage <= totalPages);

      final ayahs = allVerses.map((v) => _ayahFromMap(v, surahNumber)).toList();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, jsonEncode(allVerses));
      } catch (_) {}

      return {'surah': surahNumber, 'ayahs': ayahs};
    } catch (e) {
      throw Exception('Error fetching Ayahs: $e');
    }
  }

  static String _stripHtml(String html) {
    var clean = html.replaceAll(
        RegExp(r'<sup[^>]*>.*?<\/sup>', caseSensitive: false), '');
    clean = clean.replaceAll(
        RegExp(r'<sub[^>]*>.*?<\/sub>', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'<[^>]*>'), '');
    return clean
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  Ayah _ayahFromMap(Map<String, dynamic> v, int surahNumber) {
    final rawTranslation =
        v['translations'] != null && (v['translations'] as List).isNotEmpty
            ? v['translations'][0]['text'] ?? ''
            : '';
    return Ayah(
      number: v['id'],
      numberInSurah: v['verse_key'] != null
          ? int.parse((v['verse_key'] as String).split(':')[1])
          : 0,
      surahNumber: surahNumber,
      text: v['text_uthmani'] ?? '',
      translation: _stripHtml(rawTranslation),
    );
  }

  // =========================================================================
  // FETCH AUDIO URL FOR SPECIFIC SURAH & QARI
  // =========================================================================
  Future<String> fetchAudioUrl(
    int surahNumber,
    int qariId,
  ) async {
    try {
      final response =
          await _dio.get('/chapter_recitations/$qariId/$surahNumber');

      if (response.statusCode == 200) {
        return response.data['audio_file']['audio_url'] ?? '';
      }
      throw Exception('Failed to fetch audio URL');
    } catch (e) {
      throw Exception('Error fetching audio: $e');
    }
  }

  // =========================================================================
  // FETCH ALL AVAILABLE QARIS (IMAMS) FROM API
  // =========================================================================
  Future<List<Imam>> fetchImams() async {
    try {
      final response = await _dio.get('/resources/chapter_reciters');

      if (response.statusCode == 200) {
        final reciters = response.data['reciters'] as List;

        return reciters.map((r) {
          return Imam(
            id: r['id'],
            name: r['name'] ?? 'Unknown',
            identifier: r['arabic_name'] ?? '',
            country: '',
          );
        }).toList();
      }
      throw Exception('Failed to fetch Qaris');
    } catch (e) {
      throw Exception('Error fetching Qaris: $e');
    }
  }
}