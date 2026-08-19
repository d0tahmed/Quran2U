// lib/models/word_insight.dart
//
// Plain (hand-written) models for the "Word Deep Dive" feature.
// Deliberately NOT freezed — this keeps `build_runner` out of the loop so the
// feature can ship without regenerating models.freezed.dart.

/// A single word (or ayah-end marker) inside one ayah, as returned by
/// quran.com API v4 (`/verses/by_key/{key}?words=true`).
class QuranWord {
  final int position;
  final String arabic;
  final String transliteration;
  final String translation;
  final String charType; // 'word' | 'end'
  final String location; // e.g. "2:2:1"

  const QuranWord({
    required this.position,
    required this.arabic,
    this.transliteration = '',
    this.translation = '',
    this.charType = 'word',
    this.location = '',
  });

  /// Ayah-end glyphs (۝) are returned as words by the API — never show them.
  bool get isRealWord => charType != 'end' && arabic.trim().isNotEmpty;

  static String _str(dynamic v) => v == null ? '' : v.toString();

  static int _int(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse(_str(v)) ?? 0;
  }

  /// Tolerant parser: any missing/renamed field degrades to empty instead of
  /// throwing, so an upstream API tweak can never crash the screen.
  factory QuranWord.fromApi(Map<String, dynamic> json, int fallbackPosition) {
    final translation = json['translation'];
    final translit = json['transliteration'];
    return QuranWord(
      position: json['position'] == null ? fallbackPosition : _int(json['position']),
      arabic: _str(json['text_uthmani']).isNotEmpty
          ? _str(json['text_uthmani'])
          : _str(json['text']),
      transliteration:
          translit is Map ? _str(translit['text']) : _str(translit),
      translation:
          translation is Map ? _str(translation['text']) : _str(translation),
      charType: _str(json['char_type_name']).isEmpty
          ? 'word'
          : _str(json['char_type_name']),
      location: _str(json['location']),
    );
  }

  factory QuranWord.fromCache(Map<String, dynamic> json) => QuranWord(
        position: _int(json['p']),
        arabic: _str(json['a']),
        transliteration: _str(json['t']),
        translation: _str(json['e']),
        charType: _str(json['c']).isEmpty ? 'word' : _str(json['c']),
        location: _str(json['l']),
      );

  Map<String, dynamic> toCache() => {
        'p': position,
        'a': arabic,
        't': transliteration,
        'e': translation,
        'c': charType,
        'l': location,
      };
}

/// One place in the Quran where a word/form occurs.
class WordOccurrence {
  final String verseKey; // "2:2"
  final String arabicText;
  final String translation;

  const WordOccurrence({
    required this.verseKey,
    this.arabicText = '',
    this.translation = '',
  });

  int get surahNumber {
    final parts = verseKey.split(':');
    return parts.isEmpty ? 0 : int.tryParse(parts.first) ?? 0;
  }

  int get ayahNumber {
    final parts = verseKey.split(':');
    return parts.length < 2 ? 0 : int.tryParse(parts[1]) ?? 0;
  }

  factory WordOccurrence.fromCache(Map<String, dynamic> json) => WordOccurrence(
        verseKey: json['k']?.toString() ?? '',
        arabicText: json['a']?.toString() ?? '',
        translation: json['t']?.toString() ?? '',
      );

  Map<String, dynamic> toCache() => {
        'k': verseKey,
        'a': arabicText,
        't': translation,
      };
}

/// Result of a Quran-wide lookup for one word.
class OccurrenceResult {
  final List<WordOccurrence> items;
  final int totalResults;

  const OccurrenceResult({this.items = const [], this.totalResults = 0});

  bool get isTruncated => totalResults > items.length;

  /// How many distinct surahs the word appears in (within the fetched window).
  int get surahSpread => items.map((e) => e.surahNumber).toSet().length;

  factory OccurrenceResult.fromCache(Map<String, dynamic> json) {
    final raw = json['i'];
    return OccurrenceResult(
      totalResults: json['n'] is num ? (json['n'] as num).toInt() : 0,
      items: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => WordOccurrence.fromCache(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toCache() => {
        'n': totalResults,
        'i': items.map((e) => e.toCache()).toList(),
      };
}

/// A classical trilateral root and its lexical dossier.
class RootEntry {
  final String root; // "ح م د"
  final String transliteration; // "Ḥ-M-D"
  final String coreSense; // one-line gloss
  final String deepMeaning; // 2–4 sentences of lexical depth
  final String whyUsed; // why the Quran reaches for THIS word
  final List<String> family; // derived Quranic forms

  const RootEntry({
    required this.root,
    required this.transliteration,
    required this.coreSense,
    required this.deepMeaning,
    required this.whyUsed,
    this.family = const [],
  });
}

/// How confident we are about the morphology attributed to a word.
enum RootConfidence {
  /// Word form is in the curated index — root is verified.
  verified,

  /// Root derived by the built-in stemmer — shown as an estimate.
  estimated,

  /// Grammatical particle: it has a function, not a trilateral root.
  particle,
}

/// The fully-assembled, offline part of a word's analysis.
class WordAnalysis {
  final String surface; // as it appears in the mushaf
  final String normalized; // diacritic-free comparison form
  final String root; // '' when particle/unknown
  final RootConfidence confidence;
  final RootEntry? entry; // lexicon dossier, when known
  final String particleNote; // function of the particle, when applicable
  final String grammarHint; // heuristic morphology note

  const WordAnalysis({
    required this.surface,
    required this.normalized,
    this.root = '',
    this.confidence = RootConfidence.estimated,
    this.entry,
    this.particleNote = '',
    this.grammarHint = '',
  });

  bool get hasLexicon => entry != null;
}
