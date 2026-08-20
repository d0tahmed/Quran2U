// lib/providers/search_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/services/quran_search_service.dart';

final quranSearchServiceProvider =
    Provider<QuranSearchService>((ref) => QuranSearchService());

/// Concept-index ranking only: pure, synchronous, offline, sub-millisecond.
///
/// The screen watches this alongside [quranSearchProvider] so it can paint the
/// matched themes in the very first frame after a query is submitted, while
/// the networked full-text layer is still in flight. A search box that shows
/// something useful immediately feels far faster than one that shows a spinner
/// for the same total duration.
final themeMatchesProvider =
    Provider.autoDispose.family<List<ThemeMatch>, String>(
  (ref, query) => QuranSearchService.topThemes(query),
);

/// Runs the full two-layer search: curated concept index, then full text.
/// The family key is the raw query string, so identical queries are served
/// from Riverpod's cache for free.
final quranSearchProvider =
    FutureProvider.autoDispose.family<SearchOutcome, String>((ref, query) async {
  if (query.trim().isEmpty) return const SearchOutcome();

  // Respect the translation the user picked in Settings; fall back to
  // Saheeh International (131) when the setting is "Off".
  final selected = ref.watch(selectedTranslationProvider);
  final translationId = selected.id > 0 ? selected.id : 131;

  return ref
      .read(quranSearchServiceProvider)
      .search(query, translationId: translationId);
});
