// lib/services/word_insight_service.dart
//
// Network layer for the Word Deep Dive feature.
//
// Every call is wrapped so that a failure degrades to cached data or an empty
// result — this screen must never throw into the widget tree.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_recitation/models/word_insight.dart';
import 'package:quran_recitation/services/arabic_text_utils.dart';

class WordInsightService {
  static const String _baseUrl = 'https://api.quran.com/api/v4';

  /// Ibn Kathīr (abridged, English) — same source the Tafseer tab uses.
  static const int defaultTafsirId = 169;

  /// Hard cap on occurrences pulled per word (keeps payload + cache small).
  static const int occurrenceLimit = 40;

  final Dio _dio;

  WordInsightService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
            ));

  // ── Word-by-word breakdown of one ayah ────────────────────────────────────

  Future<List<QuranWord>> fetchAyahWords(int surahNumber, int ayahNumber) async {
    final key = '$surahNumber:$ayahNumber';
    final cacheKey = 'wi_words_${surahNumber}_${ayahNumber}_v1';

    final cached = await _readCache(cacheKey);
    if (cached != null) {
      try {
        final list = jsonDecode(cached) as List;
        final words = list
            .whereType<Map>()
            .map((e) => QuranWord.fromCache(Map<String, dynamic>.from(e)))
            .where((w) => w.isRealWord)
            .toList();
        if (words.isNotEmpty) return words;
      } catch (_) {
        // Corrupt cache entry — fall through to the network.
      }
    }

    try {
      final response = await _dio.get(
        '/verses/by_key/$key',
        queryParameters: <String, dynamic>{
          'words': true,
          'fields': 'text_uthmani',
          'word_fields': 'text_uthmani,location,char_type_name',
          'word_translation_language': 'en',
        },
      );

      if (response.statusCode != 200) return const [];

      final verse = response.data is Map ? response.data['verse'] : null;
      final rawWords = verse is Map ? verse['words'] : null;
      if (rawWords is! List) return const [];

      final words = <QuranWord>[];
      for (var i = 0; i < rawWords.length; i++) {
        final item = rawWords[i];
        if (item is! Map) continue;
        final word =
            QuranWord.fromApi(Map<String, dynamic>.from(item), i + 1);
        if (word.isRealWord) words.add(word);
      }

      if (words.isNotEmpty) {
        await _writeCache(
          cacheKey,
          jsonEncode(words.map((w) => w.toCache()).toList()),
        );
      }
      return words;
    } catch (e) {
      debugPrint('[WordInsight] fetchAyahWords($key) failed: $e');
      return const [];
    }
  }

  // ── Quran-wide occurrences ────────────────────────────────────────────────

  Future<OccurrenceResult> findOccurrences(String word) async {
    final query = ArabicText.normalize(word);
    if (query.isEmpty) return const OccurrenceResult();

    final cacheKey = 'wi_occ_${query}_v1';
    final cached = await _readCache(cacheKey);
    if (cached != null) {
      try {
        return OccurrenceResult.fromCache(
            Map<String, dynamic>.from(jsonDecode(cached) as Map));
      } catch (_) {
        // Fall through.
      }
    }

    try {
      final response = await _dio.get(
        '/search',
        queryParameters: <String, dynamic>{
          'q': query,
          'size': occurrenceLimit,
          'page': 0,
        },
      );

      if (response.statusCode != 200) return const OccurrenceResult();

      final search = response.data is Map ? response.data['search'] : null;
      if (search is! Map) return const OccurrenceResult();

      final rawResults = search['results'];
      final items = <WordOccurrence>[];
      if (rawResults is List) {
        for (final r in rawResults) {
          if (r is! Map) continue;
          final verseKey = r['verse_key']?.toString() ?? '';
          if (verseKey.isEmpty) continue;

          var translation = '';
          final translations = r['translations'];
          if (translations is List && translations.isNotEmpty) {
            final first = translations.first;
            if (first is Map) translation = first['text']?.toString() ?? '';
          }

          items.add(WordOccurrence(
            verseKey: verseKey,
            arabicText: _stripHtml(r['text']?.toString() ?? ''),
            translation: _stripHtml(translation),
          ));
        }
      }

      final total = search['total_results'] is num
          ? (search['total_results'] as num).toInt()
          : items.length;

      final result = OccurrenceResult(items: items, totalResults: total);
      if (items.isNotEmpty) {
        await _writeCache(cacheKey, jsonEncode(result.toCache()));
      }
      return result;
    } catch (e) {
      debugPrint('[WordInsight] findOccurrences($query) failed: $e');
      return const OccurrenceResult();
    }
  }

  // ── Context: tafsīr of the ayah the word sits in ──────────────────────────

  Future<String> fetchAyahContext(
    int surahNumber,
    int ayahNumber, {
    int tafsirId = defaultTafsirId,
    int maxChars = 1400,
  }) async {
    final key = '$surahNumber:$ayahNumber';
    final cacheKey = 'wi_ctx_${surahNumber}_${ayahNumber}_${tafsirId}_v1';

    final cached = await _readCache(cacheKey);
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final response = await _dio.get('/tafsirs/$tafsirId/by_ayah/$key');
      if (response.statusCode != 200) return '';

      final data = response.data;
      String text = '';
      if (data is Map) {
        final tafsirs = data['tafsirs'];
        if (tafsirs is List && tafsirs.isNotEmpty) {
          final first = tafsirs.first;
          if (first is Map) text = first['text']?.toString() ?? '';
        } else if (data['tafsir'] is Map) {
          text = (data['tafsir'] as Map)['text']?.toString() ?? '';
        }
      }

      text = _stripHtml(text);
      if (text.length > maxChars) {
        text = '${text.substring(0, maxChars).trimRight()}…';
      }
      if (text.isNotEmpty) await _writeCache(cacheKey, text);
      return text;
    } catch (e) {
      debugPrint('[WordInsight] fetchAyahContext($key) failed: $e');
      return '';
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static final RegExp _tagRe = RegExp(r'<[^>]*>');
  static final RegExp _blankLines = RegExp(r'\n{3,}');

  static String _stripHtml(String html) {
    if (html.isEmpty) return '';
    var clean = html
        .replaceAll(RegExp(r'<sup[^>]*>.*?</sup>',
            caseSensitive: false, dotAll: true), '')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(_tagRe, '');
    return clean
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(_blankLines, '\n\n')
        .trim();
  }

  Future<String?> _readCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {
      // Cache is a nicety — never surface a failure here.
    }
  }
}
