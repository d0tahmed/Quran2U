// lib/services/arabic_text_utils.dart
//
// Small, dependency-free Arabic text helpers used by the Word Deep Dive
// feature: diacritic stripping, orthographic normalisation, a lightweight
// stemmer and a heuristic morphology reader.
//
// NOTE: every invisible code point is written as a \u escape on purpose —
// never paste raw combining marks into source.

class ArabicText {
  ArabicText._();

  /// Harakat, tanween, shadda, sukun, superscript alef, Quranic annotation
  /// signs, tatweel, and the bidi/zero-width marks that ride along in
  /// API payloads.
  static final RegExp _diacritics = RegExp(
    '[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640'
    '\u200B-\u200F\uFEFF]',
  );

  /// Anything that is not an Arabic letter (U+0621..U+064A) or a space.
  static final RegExp _nonArabic = RegExp('[^\u0621-\u064A ]');

  static final RegExp _whitespace = RegExp(r'\s+');

  /// Removes vowel marks and unifies the letter shapes that vary between
  /// mushaf orthography and plain search text.
  static String normalize(String input) {
    if (input.isEmpty) return '';
    var s = input.replaceAll(_diacritics, '');
    s = s
        .replaceAll('\u0622', '\u0627') // aa -> alef
        .replaceAll('\u0623', '\u0627') // alef+hamza above -> alef
        .replaceAll('\u0625', '\u0627') // alef+hamza below -> alef
        .replaceAll('\u0671', '\u0627') // alef wasla -> alef
        .replaceAll('\u0649', '\u064A') // alef maqsura -> ya
        .replaceAll('\u0624', '\u0648') // waw+hamza -> waw
        .replaceAll('\u0626', '\u064A'); // ya+hamza -> ya
    s = s.replaceAll(_nonArabic, '');
    return s.trim();
  }

  /// Normalisation tuned for root matching (also folds ة -> ه, drops ء).
  static String normalizeForRoot(String input) {
    return normalize(input)
        .replaceAll('\u0629', '\u0647') // ta marbuta -> ha
        .replaceAll('\u0621', ''); // hamza
  }

  /// Splits an ayah into displayable word tokens (keeps mushaf diacritics).
  static List<String> splitWords(String ayahText) {
    return ayahText
        .split(_whitespace)
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList();
  }

  /// True when the token carries no Arabic letters (ayah-number glyph etc.).
  static bool isOrnament(String token) => normalize(token).isEmpty;

  // ── Stemmer ───────────────────────────────────────────────────────────────
  // Ordered longest-first so "بال" is stripped before "ب".
  static const List<String> _prefixes = <String>[
    'وبال', 'فبال', 'وكال', 'بال', 'كال', 'فال', 'وال', 'لل',
    'ال', 'سي', 'ست', 'سن', 'و', 'ف', 'ب', 'ك', 'ل',
  ];

  static const List<String> _suffixes = <String>[
    'هما', 'كما', 'تما', 'وهم', 'ناه', 'وها',
    'ون', 'ين', 'ان', 'ات', 'وا', 'تم', 'تن', 'نا', 'ها', 'هم', 'هن',
    'كم', 'كن', 'يه',
    'ه', 'ك', 'ي', 'ا', 'ت', 'ن',
  ];

  /// Best-effort trilateral root. Correct for a large share of regular forms;
  /// always surfaced to the user as an *estimate*, never as fact.
  static String guessRoot(String word) {
    var s = normalizeForRoot(word);
    if (s.length < 3) return '';

    // Strip at most one prefix, never dropping below three letters.
    for (final p in _prefixes) {
      if (s.length - p.length >= 3 && s.startsWith(p)) {
        s = s.substring(p.length);
        break;
      }
    }

    // Strip suffixes greedily.
    var changed = true;
    while (changed && s.length > 3) {
      changed = false;
      for (final suf in _suffixes) {
        if (s.length - suf.length >= 3 && s.endsWith(suf)) {
          s = s.substring(0, s.length - suf.length);
          changed = true;
          break;
        }
      }
    }

    // Imperfect-verb marker (ي/ت/ن/ا) sitting on a clean triliteral.
    if (s.length == 4 && 'يتنا'.contains(s[0])) {
      s = s.substring(1);
    }
    // Derived-noun mīm (مفعول / مفعل patterns).
    if (s.length == 4 && s.startsWith('م')) {
      s = s.substring(1);
    }

    if (s.length < 3) return '';
    if (s.length > 3) s = s.substring(0, 3);
    return s.split('').join(' ');
  }

  /// Very small morphology reader — enough to give the reader a useful cue.
  static String grammarHint(String word) {
    final s = normalizeForRoot(word);
    if (s.length < 2) return '';

    final hints = <String>[];
    final hasAl = s.startsWith('ال') ||
        s.startsWith('وال') ||
        s.startsWith('بال') ||
        s.startsWith('لل');

    if (hasAl) hints.add('Carries the definite article "al-"');
    if (s.length >= 4 &&
        'يتن'.contains(s[0]) &&
        !hasAl) {
      hints.add('Imperfect (present/future) verb pattern');
    }
    if (s.endsWith('ون') || s.endsWith('ين')) {
      hints.add('Sound masculine plural ending');
    } else if (s.endsWith('ات')) {
      hints.add('Sound feminine plural ending');
    } else if (s.endsWith('ان')) {
      hints.add('Dual ending');
    }
    if (s.startsWith('م') && s.length >= 5) {
      hints.add('Mīm-prefixed derived noun (participle pattern)');
    }
    if ((s.endsWith('هم') || s.endsWith('كم') || s.endsWith('نا')) &&
        s.length >= 5) {
      hints.add('Ends with an attached pronoun');
    }

    if (hints.isEmpty) return '';
    return '${hints.join(' · ')}.';
  }
}
