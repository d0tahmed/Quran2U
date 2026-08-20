// lib/services/quran_search_service.dart
//
// Search over the whole Quran, in two layers.
//
// LAYER 1 — CONCEPT INDEX (offline, instant, high precision)
// ----------------------------------------------------------
// A natural-language query is scored against a curated concept index
// (lib/data/quran_theme_index.dart). This is what answers "i feel anxious" or
// "how should a husband treat his wife" with the ayat the tradition actually
// cites, rather than whichever verse happens to contain the word "anxious".
// It needs no network and returns in microseconds.
//
// LAYER 2 — FULL TEXT (online, high recall)
// -----------------------------------------
// The index is curated, so it can only ever cover what someone curated. Layer
// two hands the raw query to Quran.com's search endpoint, which matches across
// ~90 translations and the Arabic. That is what makes the box a real search
// engine: "dhul qarnayn", "she-camel", "iron", "honey", a half-remembered
// phrase — anything in the text is findable, whether or not it is a theme.
//
// The two are merged, not chosen between: curated hits lead (they are the
// trustworthy answer to "what does the Quran say about X"), literal hits
// follow (they are the complete answer to "where does the word X appear").
//
// WHAT THIS DELIBERATELY DOES NOT DO
// ----------------------------------
// It does not send the query to a language model to have an answer written.
// Every word this screen displays is either Quranic text or a published
// translation, fetched and attributed. For religious content a generated
// paraphrase that reads like tafsīr is a liability, not a feature — and an
// API key shipped inside an APK is extractable by anyone who downloads it.
//
// OFFLINE BEHAVIOUR
// -----------------
// Full-text results are cached per query, so a repeated search works with no
// connection. Quranic text does not change, so the cache has no expiry, only
// an LRU cap. A first-time query with no network degrades to layer one rather
// than erroring.

import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_recitation/data/quran_theme_index.dart';

/// Why a verse is in the result list.
enum VerseSource {
  /// The query was a direct reference such as "2:255".
  reference,

  /// Surfaced by the curated concept index.
  theme,

  /// Surfaced by full-text search over the Arabic and the translations.
  fullText,
}

/// A run of translation text, flagged if the search engine matched on it.
@immutable
class TextSegment {
  final String text;
  final bool match;
  const TextSegment(this.text, this.match);
}

/// A theme plus how well it matched the query.
@immutable
class ThemeMatch {
  final QuranTheme theme;
  final double score;
  const ThemeMatch(this.theme, this.score);
}

/// One ayah in a result list.
@immutable
class SearchVerse {
  final String verseKey;
  final String arabic;
  final String translation;

  /// Which theme surfaced it (empty unless [source] is [VerseSource.theme]).
  final String themeTitle;

  final VerseSource source;

  /// Which translation the text came from. Full-text search returns whichever
  /// translation matched — which is NOT necessarily the one chosen in
  /// Settings — so the name has to be shown for the quote to be honest.
  final String translationName;

  /// Translation split into matched / unmatched runs, for highlighting.
  /// Empty when the engine returned no highlight markers.
  final List<TextSegment> segments;

  const SearchVerse({
    required this.verseKey,
    this.arabic = '',
    this.translation = '',
    this.themeTitle = '',
    this.source = VerseSource.theme,
    this.translationName = '',
    this.segments = const <TextSegment>[],
  });

  int get surahNumber => int.tryParse(verseKey.split(':').first) ?? 0;
  int get ayahNumber {
    final parts = verseKey.split(':');
    return parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  }

  bool get hasText => arabic.isNotEmpty || translation.isNotEmpty;

  SearchVerse withText(String arabic, String translation) => SearchVerse(
        verseKey: verseKey,
        arabic: arabic,
        translation: translation,
        themeTitle: themeTitle,
        source: source,
        translationName: translationName,
        segments: segments,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'k': verseKey,
        'a': arabic,
        't': translation,
        'n': translationName,
        's': segments
            .map((seg) => <String, dynamic>{'t': seg.text, 'm': seg.match})
            .toList(),
      };

  factory SearchVerse.fromJson(Map<String, dynamic> map) => SearchVerse(
        verseKey: map['k']?.toString() ?? '',
        arabic: map['a']?.toString() ?? '',
        translation: map['t']?.toString() ?? '',
        translationName: map['n']?.toString() ?? '',
        source: VerseSource.fullText,
        segments: (map['s'] as List?)
                ?.whereType<Map>()
                .map((seg) => TextSegment(
                      seg['t']?.toString() ?? '',
                      seg['m'] == true,
                    ))
                .toList() ??
            const <TextSegment>[],
      );
}

@immutable
class SearchOutcome {
  final List<ThemeMatch> themes;

  /// Verses from the concept index (or the single verse of a direct lookup).
  final List<SearchVerse> verses;

  /// Verses from full-text search, deduped against [verses].
  final List<SearchVerse> textMatches;

  /// How many verses in the whole Quran matched, before truncation.
  final int totalTextMatches;

  /// True when the query was a direct reference such as "2:255".
  final bool isDirectReference;

  /// True when full-text search could not reach the network and nothing
  /// useful was cached. The UI uses this to explain a thin result list.
  final bool textSearchOffline;

  const SearchOutcome({
    this.themes = const [],
    this.verses = const [],
    this.textMatches = const [],
    this.totalTextMatches = 0,
    this.isDirectReference = false,
    this.textSearchOffline = false,
  });

  bool get isEmpty => verses.isEmpty && textMatches.isEmpty;
  int get resultCount => verses.length + textMatches.length;
}

class QuranSearchService {
  static const String _baseUrl = 'https://api.quran.com/api/v4';

  /// Cap on concept-index verses so a broad query stays readable.
  static const int maxVerses = 25;

  /// Cap on full-text hits shown. The API allows up to 50 per page.
  static const int maxTextResults = 20;

  /// How many distinct queries keep their full-text results on disk.
  static const int _cacheEntryLimit = 40;

  /// Parallel verse fetches for the concept layer. The old code awaited 25
  /// round trips one after another, which is five seconds of staring at a
  /// spinner; six at a time turns that into roughly one.
  static const int _fetchConcurrency = 6;

  final Dio _dio;

  QuranSearchService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 15),
            ));

  // ── Query normalisation ───────────────────────────────────────────────────

  static final RegExp _nonWord = RegExp(r"[^a-z0-9\s':]");
  static final RegExp _spaces = RegExp(r'\s+');
  static final RegExp _reference =
      RegExp(r'^\s*(\d{1,3})\s*[:.\-]\s*(\d{1,3})\s*$');

  /// Words that carry no topical signal.
  static const Set<String> _stopWords = <String>{
    'a', 'about', 'all', 'am', 'an', 'and', 'any', 'are', 'as', 'at', 'be',
    'been', 'but', 'by', 'can', 'did', 'do', 'does', 'for', 'from', 'get',
    'has', 'have', 'how', 'i', 'if', 'in', 'is', 'it', 'its', 'me', 'my',
    'of', 'on', 'or', 'our', 'quran', 'say', 'says', 'should', 'so',
    'talk', 'talks', 'tell', 'that', 'the', 'their', 'there', 'they', 'this',
    'to', 'up', 'us', 'verse', 'verses', 'was', 'we', 'what', 'when', 'where',
    'which', 'who', 'why', 'will', 'with', 'you', 'your', 'ayah', 'ayat',
    'surah', 'allah', 'god', 'mention', 'mentioned', 'regarding', 'related',
  };

  static List<String> tokenize(String query) {
    final cleaned =
        query.toLowerCase().replaceAll(_nonWord, ' ').replaceAll(_spaces, ' ');
    return cleaned
        .split(' ')
        .map((t) => t.trim())
        .where((t) => t.length > 1 && !_stopWords.contains(t))
        .toList();
  }

  /// Crude English stemmer — enough to match "praying" to "pray".
  static String stem(String word) {
    if (word.length > 5 && word.endsWith('ness')) {
      return word.substring(0, word.length - 4);
    }
    if (word.length > 4 && word.endsWith('ing')) {
      return word.substring(0, word.length - 3);
    }
    if (word.length > 4 && word.endsWith('ed')) {
      return word.substring(0, word.length - 2);
    }
    if (word.length > 3 && word.endsWith('s') && !word.endsWith('ss')) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  // ── Layer 1: concept ranking ──────────────────────────────────────────────

  /// Scores every theme against the query. Pure, synchronous and offline —
  /// the UI calls this directly to paint theme chips before the network layer
  /// has answered.
  static List<ThemeMatch> rankThemes(String query) {
    final tokens = tokenize(query);
    final stems = tokens.map(stem).toList();
    final phrase = query.toLowerCase().trim();

    // NOTE: do not bail out on an empty token list. Queries made entirely of
    // stopwords ("who is allah") still match multi-word keywords verbatim.
    if (tokens.isEmpty && phrase.length < 3) return const [];

    final matches = <ThemeMatch>[];

    for (final theme in kQuranThemes) {
      var score = 0.0;

      // Multi-word keyword appearing verbatim in the query is the strongest
      // possible signal ("peace of heart", "day of judgement").
      for (final keyword in theme.keywords) {
        if (keyword.contains(' ') && phrase.contains(keyword)) {
          score += 6.0;
        }
      }

      final keywordStems = <String>{};
      for (final keyword in theme.keywords) {
        for (final part in keyword.split(' ')) {
          if (part.length > 1) keywordStems.add(stem(part));
        }
      }
      final titleStems = theme.title
          .toLowerCase()
          .split(RegExp(r'[^a-z]+'))
          .where((w) => w.length > 2)
          .map(stem)
          .toSet();

      for (var i = 0; i < tokens.length; i++) {
        final token = tokens[i];
        final tokenStem = stems[i];

        if (theme.keywords.contains(token)) {
          score += 4.0;
        } else if (keywordStems.contains(tokenStem)) {
          score += 3.0;
        } else if (keywordStems.any((k) =>
            k.length > 3 &&
            tokenStem.length > 3 &&
            (k.startsWith(tokenStem) || tokenStem.startsWith(k)))) {
          score += 1.5;
        }

        if (titleStems.contains(tokenStem)) score += 2.0;
      }

      if (score > 0) {
        // Normalise a little by query length so a long question does not
        // automatically outrank a short one.
        matches.add(ThemeMatch(
            theme, score / (1 + (tokens.isEmpty ? 1 : tokens.length) * 0.15)));
      }
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches;
  }

  /// The themes worth showing: meaningfully close to the best match, capped.
  static List<ThemeMatch> topThemes(String query) {
    final ranked = rankThemes(query);
    if (ranked.isEmpty) return const [];
    final best = ranked.first.score;
    return ranked
        .where((m) => m.score >= best * 0.45)
        .take(4)
        .toList(growable: false);
  }

  // ── Public entry point ────────────────────────────────────────────────────

  /// Runs a search. Never throws: an offline device falls back to the concept
  /// index and whatever is cached, rather than showing an error.
  Future<SearchOutcome> search(String query, {int translationId = 131}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const SearchOutcome();

    // "2:255" — jump straight there.
    final direct = _reference.firstMatch(trimmed);
    if (direct != null) {
      final key = '${direct.group(1)}:${direct.group(2)}';
      final verse = await fetchVerse(key, translationId: translationId);
      return SearchOutcome(
        verses: [
          verse ?? SearchVerse(verseKey: key, source: VerseSource.reference),
        ],
        isDirectReference: true,
      );
    }

    final kept = topThemes(trimmed);

    // Interleave so the top theme leads but the others are represented.
    final ordered = <SearchVerse>[];
    var depth = 0;
    var added = true;
    while (added && ordered.length < maxVerses) {
      added = false;
      for (final match in kept) {
        if (depth < match.theme.verses.length && ordered.length < maxVerses) {
          ordered.add(SearchVerse(
            verseKey: match.theme.verses[depth],
            themeTitle: match.theme.title,
          ));
          added = true;
        }
      }
      depth++;
    }

    // Both layers run at once — the concept layer's verse fetches and the
    // full-text query are independent, so there is no reason to queue them.
    final results = await Future.wait(<Future<Object?>>[
      _fillText(ordered, translationId),
      fullTextSearch(trimmed),
    ]);

    final filled = (results[0] as List<SearchVerse>?) ?? const <SearchVerse>[];
    final text = results[1] as TextSearchResult;

    // A verse already shown under a theme should not appear twice.
    final seen = filled.map((v) => v.verseKey).toSet();
    final deduped = text.verses
        .where((v) => !seen.contains(v.verseKey))
        .take(maxTextResults)
        .toList(growable: false);

    return SearchOutcome(
      themes: kept,
      verses: filled,
      textMatches: deduped,
      totalTextMatches: text.total,
      textSearchOffline: text.offline,
    );
  }

  /// Fills Arabic + translation for concept-index verses, [_fetchConcurrency]
  /// requests in flight at a time, preserving order.
  Future<List<SearchVerse>> _fillText(
      List<SearchVerse> verses, int translationId) async {
    if (verses.isEmpty) return const <SearchVerse>[];

    final out = List<SearchVerse>.from(verses);
    var cursor = 0;

    Future<void> worker() async {
      while (true) {
        final i = cursor++;
        if (i >= verses.length) return;
        final fetched =
            await fetchVerse(verses[i].verseKey, translationId: translationId);
        if (fetched != null) {
          out[i] = verses[i].withText(fetched.arabic, fetched.translation);
        }
      }
    }

    await Future.wait(List<Future<void>>.generate(
      math.min(_fetchConcurrency, verses.length),
      (_) => worker(),
    ));

    return out;
  }

  // ── Layer 2: full-text search ─────────────────────────────────────────────

  /// Hits Quran.com's search endpoint. Falls back to cached results when
  /// offline, and to an empty offline-flagged result when nothing is cached.
  Future<TextSearchResult> fullTextSearch(String query) async {
    final normalized = query.toLowerCase().trim().replaceAll(_spaces, ' ');
    if (normalized.length < 2) return const TextSearchResult.empty();

    final cacheKey = 'qs_ft_${normalized}_v1';

    try {
      final response = await _dio.get(
        '/search',
        queryParameters: <String, dynamic>{
          'q': query,
          'size': maxTextResults,
          'page': 1,
          'language': 'en',
        },
      );
      if (response.statusCode == 200) {
        final parsed = _parseSearchResponse(response.data);
        if (parsed != null) {
          await _writeCache(cacheKey, parsed);
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('[QuranSearch] fullTextSearch("$query") failed: $e');
    }

    final cached = await _readCache(cacheKey);
    if (cached != null) return cached;
    return const TextSearchResult.offline();
  }

  static TextSearchResult? _parseSearchResponse(dynamic data) {
    if (data is! Map) return null;
    final search = data['search'];
    if (search is! Map) return null;

    final rawResults = search['results'];
    if (rawResults is! List) return null;

    final verses = <SearchVerse>[];
    for (final item in rawResults) {
      if (item is! Map) continue;
      final key = item['verse_key']?.toString() ?? '';
      if (key.isEmpty) continue;

      var translationText = '';
      var translationName = '';
      var segments = const <TextSegment>[];

      final translations = item['translations'];
      if (translations is List && translations.isNotEmpty) {
        final first = translations.first;
        if (first is Map) {
          segments = parseHighlighted(first['text']?.toString() ?? '');
          translationText = segments.map((s) => s.text).join();
          translationName = first['name']?.toString() ?? '';
        }
      }

      verses.add(SearchVerse(
        verseKey: key,
        arabic: item['text']?.toString() ?? '',
        translation: translationText,
        source: VerseSource.fullText,
        translationName: translationName,
        segments: segments,
      ));
    }

    final total = search['total_results'];
    return TextSearchResult(
      verses: verses,
      total: total is int ? total : verses.length,
      offline: false,
    );
  }

  // ── Highlight parsing ─────────────────────────────────────────────────────

  static final RegExp _supRe =
      RegExp(r'<sup[^>]*>.*?</sup>', caseSensitive: false, dotAll: true);
  static final RegExp _emRe =
      RegExp(r'<em>(.*?)</em>', caseSensitive: false, dotAll: true);
  static final RegExp _tagRe = RegExp(r'<[^>]*>');

  /// Splits a translation into matched and unmatched runs.
  ///
  /// The API wraps matched words in `<em>`, but only sometimes — a fuzzy or
  /// multi-word match often comes back with no markers at all. Either way the
  /// output is a valid segment list, so callers never special-case it.
  ///
  /// Segments are NOT individually trimmed: the space between "seek help
  /// through" and "patience" lives at the edge of a segment, and trimming
  /// each one would glue the words together.
  static List<TextSegment> parseHighlighted(String html) {
    if (html.isEmpty) return const <TextSegment>[];

    final cleaned = html.replaceAll(_supRe, '');
    final out = <TextSegment>[];

    var last = 0;
    for (final m in _emRe.allMatches(cleaned)) {
      if (m.start > last) {
        final plain = _plain(cleaned.substring(last, m.start));
        if (plain.isNotEmpty) out.add(TextSegment(plain, false));
      }
      final hit = _plain(m.group(1) ?? '');
      if (hit.isNotEmpty) out.add(TextSegment(hit, true));
      last = m.end;
    }
    if (last < cleaned.length) {
      final plain = _plain(cleaned.substring(last));
      if (plain.isNotEmpty) out.add(TextSegment(plain, false));
    }

    if (out.isEmpty) return const <TextSegment>[];

    // Trim only the outer edges of the whole run.
    out[0] = TextSegment(out.first.text.trimLeft(), out.first.match);
    out[out.length - 1] = TextSegment(out.last.text.trimRight(), out.last.match);
    return out.where((s) => s.text.isNotEmpty).toList(growable: false);
  }

  static String _plain(String html) => _decode(html.replaceAll(_tagRe, ''));

  static String _decode(String text) => text
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lsquo;', '‘')
      .replaceAll('&rsquo;', '’')
      .replaceAll('&ldquo;', '“')
      .replaceAll('&rdquo;', '”')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ');

  static String _stripHtml(String html) =>
      parseHighlighted(html).map((s) => s.text).join();

  // ── Full-text cache (LRU, no expiry — the text does not change) ───────────

  static const String _cacheIndexKey = 'qs_ft_index_v1';

  Future<void> _writeCache(String key, TextSearchResult result) async {
    if (result.verses.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        key,
        jsonEncode(<String, dynamic>{
          'total': result.total,
          'verses': result.verses.map((v) => v.toJson()).toList(),
        }),
      );

      // Touch the key in the LRU index and evict the oldest beyond the cap, so
      // a heavy searcher cannot grow SharedPreferences without bound.
      //
      // List.of, not the returned list directly: some shared_preferences
      // versions hand back an unmodifiable view, and mutating it throws.
      final index =
          List<String>.of(prefs.getStringList(_cacheIndexKey) ?? const []);
      index.remove(key);
      index.add(key);
      while (index.length > _cacheEntryLimit) {
        await prefs.remove(index.removeAt(0));
      }
      await prefs.setStringList(_cacheIndexKey, index);
    } catch (_) {
      // A cache write failing is never worth failing a search over.
    }
  }

  Future<TextSearchResult?> _readCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;

      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final list = map['verses'];
      if (list is! List) return null;

      final verses = list
          .whereType<Map>()
          .map((m) => SearchVerse.fromJson(Map<String, dynamic>.from(m)))
          .where((v) => v.verseKey.isNotEmpty)
          .toList(growable: false);
      if (verses.isEmpty) return null;

      final total = map['total'];
      return TextSearchResult(
        verses: verses,
        total: total is int ? total : verses.length,
        offline: true,
      );
    } catch (_) {
      return null;
    }
  }

  /// Clears every cached full-text result.
  Future<void> clearTextCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getStringList(_cacheIndexKey) ?? <String>[]) {
        await prefs.remove(key);
      }
      await prefs.remove(_cacheIndexKey);
    } catch (_) {}
  }

  // ── Verse text, cached forever once seen ─────────────────────────────────

  Future<SearchVerse?> fetchVerse(String verseKey,
      {int translationId = 131}) async {
    final cacheKey = 'qs_v_${verseKey}_${translationId}_v1';

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        final map = Map<String, dynamic>.from(jsonDecode(cached) as Map);
        return SearchVerse(
          verseKey: verseKey,
          arabic: map['a']?.toString() ?? '',
          translation: map['t']?.toString() ?? '',
        );
      }
    } catch (_) {
      // fall through to the network
    }

    try {
      final response = await _dio.get(
        '/verses/by_key/$verseKey',
        queryParameters: <String, dynamic>{
          'fields': 'text_uthmani',
          'translations': translationId,
        },
      );
      if (response.statusCode != 200) return null;

      final verse = response.data is Map ? response.data['verse'] : null;
      if (verse is! Map) return null;

      final arabic = verse['text_uthmani']?.toString() ?? '';
      var translation = '';
      final translations = verse['translations'];
      if (translations is List && translations.isNotEmpty) {
        final first = translations.first;
        if (first is Map) {
          translation = _stripHtml(first['text']?.toString() ?? '');
        }
      }

      if (arabic.isEmpty && translation.isEmpty) return null;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            cacheKey, jsonEncode({'a': arabic, 't': translation}));
      } catch (_) {}

      return SearchVerse(
        verseKey: verseKey,
        arabic: arabic,
        translation: translation,
      );
    } catch (e) {
      debugPrint('[QuranSearch] fetchVerse($verseKey) failed: $e');
      return null;
    }
  }

  /// Every theme, for the browse grid shown before a query is typed.
  static List<QuranTheme> get allThemes => kQuranThemes;
}

/// What layer two returned: the hits, the true total, and whether it had to
/// fall back to cache because the network was unreachable.
@immutable
class TextSearchResult {
  final List<SearchVerse> verses;
  final int total;
  final bool offline;

  const TextSearchResult({
    required this.verses,
    required this.total,
    required this.offline,
  });

  const TextSearchResult.empty()
      : verses = const <SearchVerse>[],
        total = 0,
        offline = false;

  const TextSearchResult.offline()
      : verses = const <SearchVerse>[],
        total = 0,
        offline = true;
}
