// lib/screens/word_insight_screen.dart
//
// "Word Deep Dive" — opened by holding a word (or an ayah) in the reader.
//
// Shows, for a single Quranic word:
//   • the word itself, its transliteration and its meaning in context
//   • its trilateral root, morphology and derived family
//   • the classical lexical depth of that root and why the Quran chose it
//   • every place the same form occurs across the whole Quran
//   • the situation/background of the ayah it was used in (tafsīr excerpt)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/models/word_insight.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/providers/word_insight_providers.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/glass.dart';
import 'package:quran_recitation/ui_v2/app_typography.dart';

const _kGreen = AppColorsV2.primary;
const _kGold = AppColorsV2.tertiary;
const _kBlue = AppColorsV2.secondary;

class WordInsightScreen extends ConsumerWidget {
  /// Surface form exactly as written in the mushaf (diacritics kept).
  final String word;
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String revelationType;

  /// 1-based index of the word inside the ayah (0 when unknown).
  final int position;

  /// Word meaning / transliteration supplied by the picker, when it already
  /// has them — saves a round trip.
  final String contextTranslation;
  final String transliteration;

  const WordInsightScreen({
    super.key,
    required this.word,
    required this.surahNumber,
    required this.ayahNumber,
    this.surahName = '',
    this.revelationType = '',
    this.position = 0,
    this.contextTranslation = '',
    this.transliteration = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(wordAnalysisProvider(word));
    final occurrencesAsync =
        ref.watch(wordOccurrencesProvider(analysis.normalized));
    final contextAsync =
        ref.watch(ayahContextProvider((surah: surahNumber, ayah: ayahNumber)));

    final surahs = ref.watch(surahsProvider).asData?.value ?? const <Surah>[];

    return Scaffold(
      backgroundColor: AppColorsV2.bg,
      appBar: AppBar(
        backgroundColor: AppColorsV2.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Word Study',
          style: AppTypeV2.manrope(
            color: AppColorsV2.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy word',
            icon: const Icon(Icons.copy_rounded, size: 20),
            color: AppColorsV2.onSurfaceVariant,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: word));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColorsV2.surfaceHigh,
                  content: Text(
                    'Word copied',
                    style: AppTypeV2.manrope(
                      color: AppColorsV2.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        children: [
          _HeroWordCard(
            word: word,
            transliteration: transliteration,
            meaning: contextTranslation,
            surahName: surahName,
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
            position: position,
          ),
          const SizedBox(height: 18),
          _RootCard(analysis: analysis),
          if (analysis.hasLexicon) ...[
            const SizedBox(height: 18),
            _SectionCard(
              icon: Icons.auto_awesome_rounded,
              tint: _kGold,
              title: 'Deep meaning of the root',
              subtitle: analysis.entry!.coreSense,
              body: analysis.entry!.deepMeaning,
            ),
            const SizedBox(height: 18),
            _SectionCard(
              icon: Icons.psychology_alt_rounded,
              tint: _kBlue,
              title: 'Why this word was chosen',
              body: analysis.entry!.whyUsed,
            ),
          ] else ...[
            const SizedBox(height: 18),
            _NoLexiconCard(analysis: analysis),
          ],
          const SizedBox(height: 18),
          _OccurrencesCard(
            query: analysis.normalized,
            state: occurrencesAsync,
            surahs: surahs,
            currentKey: '$surahNumber:$ayahNumber',
            onRetry: () =>
                ref.invalidate(wordOccurrencesProvider(analysis.normalized)),
          ),
          const SizedBox(height: 18),
          _ContextCard(
            state: contextAsync,
            surahName: surahName,
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
            revelationType: revelationType,
            onRetry: () => ref.invalidate(
                ayahContextProvider((surah: surahNumber, ayah: ayahNumber))),
          ),
          const SizedBox(height: 22),
          const _Disclaimer(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────────────────────────

class _HeroWordCard extends StatelessWidget {
  final String word;
  final String transliteration;
  final String meaning;
  final String surahName;
  final int surahNumber;
  final int ayahNumber;
  final int position;

  const _HeroWordCard({
    required this.word,
    required this.transliteration,
    required this.meaning,
    required this.surahName,
    required this.surahNumber,
    required this.ayahNumber,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final label = surahName.isEmpty
        ? 'Ayah $surahNumber:$ayahNumber'
        : '$surahName · $surahNumber:$ayahNumber';

    return FrostedCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      tint: AppColorsV2.surfaceLow,
      accent: _kGreen,
      edgeColor: _kGreen,
      edgeIntensity: 0.44,
      glow: _kGreen,
      elevated: true,
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              word,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                fontSize: 46,
                height: 1.9,
                color: Colors.white,
                fontFamily: AppTypeV2.amiriFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (transliteration.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              transliteration.trim(),
              textAlign: TextAlign.center,
              style: AppTypeV2.manrope(
                color: _kGold,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
          if (meaning.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              meaning.trim(),
              textAlign: TextAlign.center,
              style: AppTypeV2.manrope(
                color: AppColorsV2.onSurface,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(text: label, tint: _kGreen, icon: Icons.menu_book_rounded),
              if (position > 0)
                _Pill(
                  text: 'Word $position',
                  tint: AppColorsV2.secondary,
                  icon: Icons.tag_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Root / morphology
// ─────────────────────────────────────────────────────────────────────────────

class _RootCard extends StatelessWidget {
  final WordAnalysis analysis;
  const _RootCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final isParticle = analysis.confidence == RootConfidence.particle;
    final hasRoot = analysis.root.isNotEmpty;

    return _Shell(
      icon: Icons.account_tree_rounded,
      tint: _kGreen,
      title: isParticle ? 'Grammatical function' : 'Root & morphology',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isParticle)
            Text(
              analysis.particleNote,
              style: AppTypeV2.manrope(
                color: AppColorsV2.onSurface,
                fontSize: 14,
                height: 1.7,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (hasRoot) ...[
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    analysis.root,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 26,
                      color: _kGreen,
                      fontFamily: AppTypeV2.amiriFamily,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (analysis.hasLexicon)
                        Text(
                          analysis.entry!.transliteration,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypeV2.manrope(
                            color: AppColorsV2.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      const SizedBox(height: 6),
                      _ConfidenceChip(confidence: analysis.confidence),
                    ],
                  ),
                ),
              ],
            ),
          ] else
            Text(
              'No trilateral root could be resolved for this form. It may be a '
              'proper noun, a foreign-origin term, or a rare pattern.',
              style: AppTypeV2.manrope(
                color: AppColorsV2.onSurfaceVariant,
                fontSize: 13,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (analysis.grammarHint.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 15, color: AppColorsV2.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    analysis.grammarHint,
                    style: AppTypeV2.manrope(
                      color: AppColorsV2.onSurfaceVariant,
                      fontSize: 12.5,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (analysis.hasLexicon && analysis.entry!.family.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'FAMILY OF THIS ROOT',
              style: AppTypeV2.manrope(
                color: AppColorsV2.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: analysis.entry!.family
                    .map((f) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColorsV2.surfaceHigh
                                .withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColorsV2.outlineVariant
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColorsV2.onSurface,
                              fontFamily: AppTypeV2.amiriFamily,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfidenceChip extends StatelessWidget {
  final RootConfidence confidence;
  const _ConfidenceChip({required this.confidence});

  @override
  Widget build(BuildContext context) {
    late final String text;
    late final Color tint;
    late final IconData icon;

    switch (confidence) {
      case RootConfidence.verified:
        text = 'Verified root';
        tint = _kGreen;
        icon = Icons.verified_rounded;
      case RootConfidence.estimated:
        text = 'Estimated by analyser';
        tint = _kGold;
        icon = Icons.functions_rounded;
      case RootConfidence.particle:
        text = 'Function word';
        tint = _kBlue;
        icon = Icons.link_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tint),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypeV2.manrope(
                color: tint,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoLexiconCard extends StatelessWidget {
  final WordAnalysis analysis;
  const _NoLexiconCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    if (analysis.confidence == RootConfidence.particle) {
      return const SizedBox.shrink();
    }
    return _Shell(
      icon: Icons.auto_awesome_rounded,
      tint: _kGold,
      title: 'Deep meaning',
      child: Text(
        'A full lexical entry for this root is not bundled yet. The occurrence '
        'list below still shows every place this form appears in the Quran, and '
        'the tafsīr excerpt explains how it functions in this ayah — together '
        'they are the classical way of reading a word: usage first, then '
        'commentary.',
        style: AppTypeV2.manrope(
          color: AppColorsV2.onSurfaceVariant,
          fontSize: 13.5,
          height: 1.75,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Occurrences
// ─────────────────────────────────────────────────────────────────────────────

class _OccurrencesCard extends StatelessWidget {
  final String query;
  final AsyncValue<OccurrenceResult> state;
  final List<Surah> surahs;
  final String currentKey;
  final VoidCallback onRetry;

  const _OccurrencesCard({
    required this.query,
    required this.state,
    required this.surahs,
    required this.currentKey,
    required this.onRetry,
  });

  String _surahName(int number) {
    for (final s in surahs) {
      if (s.number == number) return s.name;
    }
    return 'Surah $number';
  }

  @override
  Widget build(BuildContext context) {
    return _Shell(
      icon: Icons.travel_explore_rounded,
      tint: _kBlue,
      title: 'Across the whole Quran',
      child: state.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: _kBlue),
            ),
          ),
        ),
        error: (e, _) => _Retry(
          message: 'Could not load occurrences.',
          onRetry: onRetry,
        ),
        data: (result) {
          if (result.items.isEmpty) {
            return _Retry(
              message:
                  'No occurrences loaded. Connect to the internet once and this '
                  'list is cached for offline use.',
              onRetry: onRetry,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Stat(
                    value: '${result.totalResults}',
                    label: 'matches',
                    tint: _kBlue,
                  ),
                  const SizedBox(width: 10),
                  _Stat(
                    value: '${result.surahSpread}',
                    label: 'surahs',
                    tint: _kGreen,
                  ),
                ],
              ),
              if (result.isTruncated) ...[
                const SizedBox(height: 10),
                Text(
                  'Showing the first ${result.items.length} of '
                  '${result.totalResults} matches.',
                  style: AppTypeV2.manrope(
                    color: AppColorsV2.onSurfaceVariant,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              ...result.items.take(25).map((o) => _OccurrenceTile(
                    occurrence: o,
                    surahName: _surahName(o.surahNumber),
                    isCurrent: o.verseKey == currentKey,
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _OccurrenceTile extends StatelessWidget {
  final WordOccurrence occurrence;
  final String surahName;
  final bool isCurrent;

  const _OccurrenceTile({
    required this.occurrence,
    required this.surahName,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: isCurrent
            ? _kGreen.withValues(alpha: 0.08)
            : AppColorsV2.surfaceHigh.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? _kGreen.withValues(alpha: 0.30)
              : AppColorsV2.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  occurrence.verseKey,
                  style: AppTypeV2.manrope(
                    color: _kGold,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  surahName,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeV2.manrope(
                    color: AppColorsV2.onSurfaceVariant,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isCurrent)
                Text(
                  'THIS AYAH',
                  maxLines: 1,
                  style: AppTypeV2.manrope(
                    color: _kGreen,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
            ],
          ),
          if (occurrence.arabicText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              occurrence.arabicText,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 21,
                height: 1.95,
                color: Colors.white.withValues(alpha: 0.92),
                fontFamily: AppTypeV2.amiriFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (occurrence.translation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              occurrence.translation,
              style: AppTypeV2.manrope(
                color: AppColorsV2.onSurfaceVariant,
                fontSize: 12.5,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Context / background
// ─────────────────────────────────────────────────────────────────────────────

class _ContextCard extends StatelessWidget {
  final AsyncValue<String> state;
  final String surahName;
  final int surahNumber;
  final int ayahNumber;
  final String revelationType;
  final VoidCallback onRetry;

  const _ContextCard({
    required this.state,
    required this.surahName,
    required this.surahNumber,
    required this.ayahNumber,
    required this.revelationType,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _Shell(
      icon: Icons.history_edu_rounded,
      tint: _kGold,
      title: 'Situation & background',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (surahName.isNotEmpty)
                _Pill(
                  text: surahName,
                  tint: _kGreen,
                  icon: Icons.menu_book_rounded,
                ),
              if (revelationType.isNotEmpty)
                _Pill(
                  text: revelationType,
                  tint: _kGold,
                  icon: Icons.place_rounded,
                ),
              _Pill(
                text: 'Ayah $ayahNumber',
                tint: AppColorsV2.secondary,
                icon: Icons.numbers_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          state.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: _kGold),
                ),
              ),
            ),
            error: (e, _) =>
                _Retry(message: 'Could not load the tafsīr.', onRetry: onRetry),
            data: (text) {
              if (text.isEmpty) {
                return _Retry(
                  message:
                      'Tafsīr for this ayah is not cached yet. Go online once '
                      'to download it.',
                  onRetry: onRetry,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: AppTypeV2.manrope(
                      color: AppColorsV2.onSurface,
                      fontSize: 13.5,
                      height: 1.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Excerpt — Tafsīr Ibn Kathīr (abridged), via Quran.com',
                    style: AppTypeV2.manrope(
                      color: AppColorsV2.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared bits
// ─────────────────────────────────────────────────────────────────────────────

class _Shell extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final Widget child;

  const _Shell({
    required this.icon,
    required this.tint,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      tint: AppColorsV2.surfaceLow,
      accent: tint,
      edgeColor: tint,
      edgeIntensity: 0.30,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tint.withValues(alpha: 0.26),
                      tint.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(color: tint.withValues(alpha: 0.24)),
                ),
                child: Icon(icon, color: tint, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypeV2.manrope(
                    color: AppColorsV2.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String? subtitle;
  final String body;

  const _SectionCard({
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return _Shell(
      icon: icon,
      tint: tint,
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            Text(
              subtitle!,
              style: AppTypeV2.manrope(
                color: tint,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            body,
            style: AppTypeV2.manrope(
              color: AppColorsV2.onSurface,
              fontSize: 13.5,
              height: 1.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color tint;
  final IconData icon;

  const _Pill({required this.text, required this.tint, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tint),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypeV2.manrope(
                color: tint,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color tint;

  const _Stat({required this.value, required this.label, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value,
            style: AppTypeV2.manrope(
              color: tint,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypeV2.manrope(
              color: AppColorsV2.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _Retry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: AppTypeV2.manrope(
            color: AppColorsV2.onSurfaceVariant,
            fontSize: 12.5,
            height: 1.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text(
            'Try again',
            style: AppTypeV2.manrope(fontWeight: FontWeight.w800),
          ),
          style: TextButton.styleFrom(
            foregroundColor: _kGreen,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColorsV2.surfaceLow.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColorsV2.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_moon_rounded,
              size: 16, color: AppColorsV2.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'These notes summarise classical lexicons (Ibn Fāris, al-Rāghib, '
              'Lane) and are offered for reflection, not as a fatwā. For rulings '
              'and detailed exegesis, return to the full tafsīr and to qualified '
              'scholars.',
              style: AppTypeV2.manrope(
                color: AppColorsV2.onSurfaceVariant,
                fontSize: 11.5,
                height: 1.65,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
