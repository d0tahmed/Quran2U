// lib/providers/word_insight_providers.dart
//
// Riverpod wiring + the offline resolver for the Word Deep Dive feature.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quran_recitation/data/quran_root_lexicon.dart';
import 'package:quran_recitation/models/word_insight.dart';
import 'package:quran_recitation/services/arabic_text_utils.dart';
import 'package:quran_recitation/services/word_insight_service.dart';

/// (surah, ayah) pair — Dart records give structural equality for free, so it
/// is safe as a provider family key.
typedef AyahRef = ({int surah, int ayah});

final wordInsightServiceProvider =
    Provider<WordInsightService>((ref) => WordInsightService());

/// Word-by-word breakdown of a single ayah. Returns an empty list (never
/// throws) when the device is offline and nothing is cached.
final ayahWordsProvider =
    FutureProvider.autoDispose.family<List<QuranWord>, AyahRef>((ref, r) async {
  return ref.read(wordInsightServiceProvider).fetchAyahWords(r.surah, r.ayah);
});

/// Every place the given word form appears in the Quran (capped, see service).
final wordOccurrencesProvider = FutureProvider.autoDispose
    .family<OccurrenceResult, String>((ref, word) async {
  return ref.read(wordInsightServiceProvider).findOccurrences(word);
});

/// Tafsīr excerpt for the ayah the word was pressed in — the "situation".
final ayahContextProvider =
    FutureProvider.autoDispose.family<String, AyahRef>((ref, r) async {
  return ref.read(wordInsightServiceProvider).fetchAyahContext(r.surah, r.ayah);
});

// ─────────────────────────────────────────────────────────────────────────────
// Offline resolver
// ─────────────────────────────────────────────────────────────────────────────

/// Attached pronouns that ride on the end of prepositions (ʿalayhim, fīhi…).
const List<String> _pronounSuffixes = <String>[
  'هما', 'كما', 'هم', 'هن', 'كم', 'كن', 'ها', 'نا', 'ه', 'ك', 'ي',
];

/// Definite-article + preposition combinations to peel before a dictionary
/// lookup: "لِلْمُتَّقِين" -> "المتقين", "بِالْغَيْب" -> "الغيب", "وَإِيَّاك" -> "إياك".
List<String> _lookupCandidates(String normalized, String rootForm) {
  final out = <String>[];

  void add(String value) {
    if (value.length >= 2 && !out.contains(value)) out.add(value);
  }

  for (final s in <String>[normalized, rootForm]) {
    if (s.isEmpty) continue;
    add(s);
    if (s.length > 2 && (s.startsWith('و') || s.startsWith('ف'))) {
      add(s.substring(1));
    }
    if (s.length > 3 && s.startsWith('لل')) {
      add('ال${s.substring(2)}');
    }
    for (final p in <String>['بال', 'كال', 'فال', 'وال']) {
      if (s.length > 4 && s.startsWith(p)) add('ال${s.substring(3)}');
    }
    for (final p in <String>['ب', 'ك', 'ل', 'ا']) {
      if (s.length >= 3 && s.startsWith(p)) add(s.substring(1));
    }
  }
  return out;
}

String? _particleFor(String candidate) {
  final direct = QuranRootLexicon.particleNote(candidate);
  if (direct != null) return direct;
  for (final suffix in _pronounSuffixes) {
    if (candidate.length - suffix.length >= 2 && candidate.endsWith(suffix)) {
      final base =
          candidate.substring(0, candidate.length - suffix.length);
      final note = QuranRootLexicon.particleNote(base);
      if (note != null) return note;
    }
  }
  return null;
}

/// Fully offline morphological + lexical analysis of a single surface form.
///
/// Resolution order (most reliable first):
///   1. exact function-word match
///   2. exact curated form -> root match
///   3. the same two lookups after peeling prefixes/attached pronouns
///   4. the built-in stemmer, flagged in the UI as an estimate
WordAnalysis analyzeWord(String surface) {
  final normalized = ArabicText.normalize(surface);
  final rootForm = ArabicText.normalizeForRoot(surface);

  if (normalized.isEmpty) {
    return WordAnalysis(surface: surface, normalized: normalized);
  }

  WordAnalysis particle(String note) => WordAnalysis(
        surface: surface,
        normalized: normalized,
        confidence: RootConfidence.particle,
        particleNote: note,
      );

  WordAnalysis verified(String root) => WordAnalysis(
        surface: surface,
        normalized: normalized,
        root: root,
        confidence: RootConfidence.verified,
        entry: QuranRootLexicon.entryForRoot(root),
        grammarHint: ArabicText.grammarHint(surface),
      );

  // 1 + 2 — exact matches on the untouched form.
  final exactParticle = QuranRootLexicon.particleNote(normalized);
  if (exactParticle != null) return particle(exactParticle);

  final exactRoot = QuranRootLexicon.rootForSurface(normalized) ??
      QuranRootLexicon.rootForSurface(rootForm);
  if (exactRoot != null) return verified(exactRoot);

  // 3 — retry after peeling conjunctions, prepositions and pronouns.
  final candidates = _lookupCandidates(normalized, rootForm);
  for (final c in candidates) {
    final note = _particleFor(c);
    if (note != null) return particle(note);
  }
  for (final c in candidates) {
    final root = QuranRootLexicon.rootForSurface(c);
    if (root != null) return verified(root);
  }

  // 4 — stemmer fallback.
  final guessed = ArabicText.guessRoot(surface);
  return WordAnalysis(
    surface: surface,
    normalized: normalized,
    root: guessed,
    confidence: RootConfidence.estimated,
    entry: guessed.isEmpty ? null : QuranRootLexicon.entryForRoot(guessed),
    grammarHint: ArabicText.grammarHint(surface),
  );
}

final wordAnalysisProvider = Provider.autoDispose
    .family<WordAnalysis, String>((ref, surface) => analyzeWord(surface));
