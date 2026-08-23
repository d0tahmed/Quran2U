// lib/screens/quran_search_screen.dart
//
// "Ask the Quran" — type a question in plain language, get the ayat the
// tradition cites for it. Matching is fully offline; only the verse text
// needs a network call, and only the first time each ayah is seen.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quran_recitation/data/quran_theme_index.dart';
import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/providers/search_providers.dart';
import 'package:quran_recitation/screens/share_ayah_screen.dart';
import 'package:quran_recitation/screens/surah_detail_screen.dart';
import 'package:quran_recitation/services/quran_search_service.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/app_typography.dart';
import 'package:quran_recitation/ui_v2/glass.dart';
import 'package:quran_recitation/ui_v2/widgets/q_kit.dart';

class QuranSearchScreen extends ConsumerStatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  ConsumerState<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends ConsumerState<QuranSearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  /// The query actually being searched — only updated on submit so we do not
  /// fire a network round trip per keystroke.
  String _submitted = '';

  // Deliberately mixed: two emotional entry points, two everyday-life ones,
  // and the topics people are least likely to guess the index covers.
  static const List<String> _examples = <String>[
    'patience in hardship',
    'i feel anxious',
    'how should a husband treat his wife',
    'menstruation and purity',
    'trying to have a child',
    'how do I ask forgiveness',
    'kindness to parents',
    'what happens after death',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _run(String query) {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = query.trim());
  }

  void _openSurah(SearchVerse verse) {
    final surahs = ref.read(surahsProvider).asData?.value ?? const <Surah>[];
    final match = surahs
        .cast<Surah?>()
        .firstWhere((s) => s?.number == verse.surahNumber, orElse: () => null);
    if (match == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SurahDetailScreen(surah: match),
    ));
  }

  String _surahName(int number) {
    final surahs = ref.read(surahsProvider).asData?.value ?? const <Surah>[];
    for (final s in surahs) {
      if (s.number == number) return s.name;
    }
    return 'Surah $number';
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _submitted.isNotEmpty;
    final results = hasQuery
        ? ref.watch(quranSearchProvider(_submitted))
        : const AsyncValue<SearchOutcome>.data(SearchOutcome());

    return Scaffold(
      backgroundColor: AppColorsV2.bg,
      appBar: AppBar(
        title: Text('Ask the Quran', style: AppTypeV2.title(size: 16)),
      ),
      body: Column(
        children: [
          // ── Query field ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: _run,
              style: AppTypeV2.title(size: 14, weight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Ask anything, search any word, or type 2:255',
                prefixIcon: const Icon(Icons.auto_awesome_rounded, size: 19),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: AppColorsV2.onSurfaceVariant,
                        onPressed: () {
                          _controller.clear();
                          setState(() => _submitted = '');
                        },
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          Expanded(
            child: !hasQuery
                ? _BrowseThemes(
                    examples: _examples,
                    onPick: (q) {
                      _controller.text = q;
                      _run(q);
                    },
                  )
                : results.when(
                    // The concept index is offline and instant, so the
                    // loading state is not a blank spinner: it already shows
                    // the themes that matched while the text layer is still
                    // on the wire.
                    loading: () => _Searching(
                      themes: ref.watch(themeMatchesProvider(_submitted)),
                    ),
                    error: (_, __) => const _Empty(
                      icon: Icons.error_outline_rounded,
                      title: 'Something went wrong',
                      body: 'Try rephrasing your question.',
                    ),
                    data: (outcome) {
                      if (outcome.isEmpty) {
                        return _Empty(
                          icon: Icons.search_off_rounded,
                          title: outcome.textSearchOffline
                              ? 'Nothing found offline'
                              : 'No match',
                          body: outcome.textSearchOffline
                              ? 'Searching the full text needs a connection. '
                                  'Themes and anything you have searched '
                                  'before still work offline.'
                              : 'No verse contains that. Try another word, or '
                                  'a reference like 2:255.',
                        );
                      }
                      return _Results(
                        outcome: outcome,
                        surahName: _surahName,
                        onOpen: _openSurah,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Idle state — examples and the full theme list
// ─────────────────────────────────────────────────────────────────────────────

class _BrowseThemes extends StatelessWidget {
  final List<String> examples;
  final ValueChanged<String> onPick;

  const _BrowseThemes({required this.examples, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final themes = QuranSearchService.allThemes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
      children: [
        const QSectionHeader(label: 'Try asking'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: examples
              .map((e) => GlassPill(
                    onTap: () => onPick(e),
                    child: Text(
                      e,
                      style: AppTypeV2.caption(
                          size: 12, color: AppColorsV2.onSurfaceVariant),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 26),
        QSectionHeader(
          label: 'Browse ${themes.length} themes',
        ),
        const SizedBox(height: 8),
        ...themes.map((t) => _ThemeRow(theme: t, onTap: () => onPick(t.title))),
        const SizedBox(height: 20),
        const _Disclaimer(),
      ],
    );
  }
}

class _ThemeRow extends StatelessWidget {
  final QuranTheme theme;
  final VoidCallback onTap;

  const _ThemeRow({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColorsV2.hairline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(theme.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypeV2.title(size: 13.5)),
                  const SizedBox(height: 3),
                  Text(theme.blurb,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypeV2.caption(
                          size: 11,
                          color: AppColorsV2.onSurfaceVariant
                              .withValues(alpha: 0.8))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text('${theme.verses.length}',
                style: AppTypeV2.caption(
                    size: 11, color: AppColorsV2.tertiary)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColorsV2.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Results
// ─────────────────────────────────────────────────────────────────────────────

class _Results extends StatelessWidget {
  final SearchOutcome outcome;
  final String Function(int) surahName;
  final ValueChanged<SearchVerse> onOpen;

  const _Results({
    required this.outcome,
    required this.surahName,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
      children: [
        if (outcome.themes.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: outcome.themes
                .map((m) => GlassPill(
                      selected: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      child: Text(
                        m.theme.title,
                        style: AppTypeV2.caption(
                            size: 11, color: AppColorsV2.primary),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 18),
        ],

        // Surfaced before the results, not after: if the list is thin because
        // the device is offline, the user should know that before they scroll
        // it and conclude the Quran has nothing to say.
        if (outcome.textSearchOffline) ...[
          _OfflineNotice(hasCached: outcome.textMatches.isNotEmpty),
          const SizedBox(height: 16),
        ],

        ...outcome.verses.map((v) => _VerseResult(
              verse: v,
              surahName: surahName(v.surahNumber),
              onOpen: () => onOpen(v),
            )),

        // ── Layer two: literal matches from the full text ─────────────
        if (outcome.textMatches.isNotEmpty) ...[
          if (outcome.verses.isNotEmpty) const SizedBox(height: 10),
          QSectionHeader(
            label: 'Found in the text',
            trailing: Text(
              outcome.totalTextMatches > outcome.textMatches.length
                  ? 'showing ${outcome.textMatches.length} of '
                      '${outcome.totalTextMatches}'
                  : '${outcome.textMatches.length}',
              maxLines: 1,
              style: AppTypeV2.caption(
                size: 10.5,
                color: AppColorsV2.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...outcome.textMatches.map((v) => _VerseResult(
                verse: v,
                surahName: surahName(v.surahNumber),
                onOpen: () => onOpen(v),
              )),
        ],

        const SizedBox(height: 18),
        const _Disclaimer(),
      ],
    );
  }
}

/// Shown while layer two is still on the wire. Layer one has already answered,
/// so this is a populated screen with a progress line, not a spinner.
class _Searching extends StatelessWidget {
  final List<ThemeMatch> themes;
  const _Searching({required this.themes});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
      children: [
        if (themes.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: themes
                .map((m) => GlassPill(
                      selected: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      child: Text(
                        m.theme.title,
                        style: AppTypeV2.caption(
                            size: 11, color: AppColorsV2.primary),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 22),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 1.8, color: AppColorsV2.primary),
            ),
            const SizedBox(width: 12),
            Text(
              themes.isEmpty
                  ? 'Searching the Quran…'
                  : 'Searching the full text…',
              style: AppTypeV2.caption(
                  size: 12, color: AppColorsV2.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  /// True when cached full-text results for this exact query were available.
  final bool hasCached;

  const _OfflineNotice({required this.hasCached});

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      radius: 16,
      padding: const EdgeInsets.all(13),
      edgeColor: AppColorsV2.tertiary,
      edgeIntensity: 0.20,
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 15, color: AppColorsV2.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasCached
                  ? 'Offline — these are the results saved the last time you '
                      'searched this.'
                  : 'Offline — showing themes only. Connect to search every '
                      'word of the text.',
              style: AppTypeV2.caption(
                  size: 11, color: AppColorsV2.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseResult extends StatelessWidget {
  final SearchVerse verse;
  final String surahName;
  final VoidCallback onOpen;

  const _VerseResult({
    required this.verse,
    required this.surahName,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FrostedCard(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        edgeColor: AppColorsV2.tertiary,
        edgeIntensity: 0.22,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(colors: [
                    AppColorsV2.tertiary.withValues(alpha: 0.24),
                    AppColorsV2.tertiary.withValues(alpha: 0.10),
                  ]),
                  border: Border.all(color: AppColorsV2.goldHairline),
                ),
                child: Text(verse.verseKey,
                    maxLines: 1,
                    style: AppTypeV2.caption(
                        size: 10.5, color: AppColorsV2.tertiary)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(surahName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypeV2.caption(
                        size: 11, color: AppColorsV2.onSurfaceVariant)),
              ),
              if (verse.themeTitle.isNotEmpty)
                Flexible(
                  child: Text(
                    verse.themeTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTypeV2.caption(
                      size: 9.5,
                      color: AppColorsV2.onSurfaceVariant
                          .withValues(alpha: 0.6),
                      weight: FontWeight.w600,
                    ),
                  ),
                )
              else if (verse.source == VerseSource.fullText)
                Icon(Icons.search_rounded,
                    size: 13,
                    color: AppColorsV2.onSurfaceVariant
                        .withValues(alpha: 0.45)),
            ],
          ),

          if (verse.arabic.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              verse.arabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: AppTypeV2.arabic(
                size: 21,
                color: AppColorsV2.onSurface,
                height: 1.95,
              ),
            ),
          ],

          if (verse.translation.isNotEmpty) ...[
            const SizedBox(height: 10),
            // The engine tells us which words it matched on; showing them in
            // jade is the difference between "here are 20 verses" and "here
            // is why each of these 20 verses came back".
            if (verse.segments.any((s) => s.match))
              Text.rich(
                TextSpan(
                  children: [
                    for (final seg in verse.segments)
                      TextSpan(
                        text: seg.text,
                        style: seg.match
                            ? AppTypeV2.body(
                                size: 13,
                                height: 1.65,
                                color: AppColorsV2.primary,
                                weight: FontWeight.w800,
                              )
                            : null,
                      ),
                  ],
                ),
                style: AppTypeV2.body(size: 13, height: 1.65),
              )
            else
              Text(
                verse.translation,
                style: AppTypeV2.body(size: 13, height: 1.65),
              ),

            // Full-text search returns whichever of ~90 translations matched,
            // not the one picked in Settings. Quoting it without saying whose
            // words they are would be misattribution.
            if (verse.translationName.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                '— ${verse.translationName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypeV2.caption(
                  size: 10,
                  color: AppColorsV2.onSurfaceVariant.withValues(alpha: 0.6),
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ],

          if (!verse.hasText) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 14, color: AppColorsV2.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Go online once to download this ayah.',
                    style: AppTypeV2.caption(
                        size: 11, color: AppColorsV2.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text: '${verse.arabic}\n\n${verse.translation}\n'
                        '— $surahName ${verse.verseKey}',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColorsV2.surfaceHigh,
                      content: Text('Ayah copied',
                          style: AppTypeV2.caption(
                              size: 12.5, color: AppColorsV2.onSurface)),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 17),
                color: AppColorsV2.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints.tightFor(width: 36, height: 36),
                padding: EdgeInsets.zero,
              ),
              if (verse.hasText)
                IconButton(
                  tooltip: 'Share as image',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ShareAyahScreen(
                        arabic: verse.arabic,
                        translation: verse.translation,
                        surahName: surahName,
                        surahNumber: verse.surahNumber,
                        ayahNumber: verse.ayahNumber,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.ios_share_rounded, size: 16),
                  color: AppColorsV2.onSurfaceVariant,
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints.tightFor(width: 36, height: 36),
                  padding: EdgeInsets.zero,
                ),
              TextButton(
                onPressed: onOpen,
                style: TextButton.styleFrom(
                  foregroundColor: AppColorsV2.primary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: Text('Open surah',
                    style: AppTypeV2.caption(
                        size: 11.5, color: AppColorsV2.primary)),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared bits
// ─────────────────────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Empty({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColorsV2.outlineVariant),
            const SizedBox(height: 14),
            Text(title, style: AppTypeV2.title(size: 15)),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: AppTypeV2.body(size: 12.5)),
          ],
        ),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      edgeIntensity: 0.12,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_moon_rounded,
              size: 16, color: AppColorsV2.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Themed results are starting points drawn from commonly cited '
              'ayat. Text results are literal matches from published '
              'translations. Neither is a fatwā — always read the full '
              'passage and its tafsīr in context.',
              style: AppTypeV2.body(size: 11.5, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
