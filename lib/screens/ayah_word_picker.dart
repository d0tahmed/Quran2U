// lib/screens/ayah_word_picker.dart
//
// Hold-to-explore entry point for the Word Deep Dive feature.
//
//  • [AyahWordText]        renders an ayah as individually holdable words.
//  • [showAyahWordPicker]  bottom sheet listing every word of an ayah.
//  • [openWordInsight]     pushes the study page for one word.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quran_recitation/models/word_insight.dart';
import 'package:quran_recitation/providers/word_insight_providers.dart';
import 'package:quran_recitation/screens/word_insight_screen.dart';
import 'package:quran_recitation/services/arabic_text_utils.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';

/// How long a word must be held before the study page opens.
/// Tune here — 1500 ms feels deliberate without being sluggish; raise to
/// 2000–3000 ms for a slower hold.
const Duration kWordHoldDuration = Duration(milliseconds: 1500);

const _kGreen = AppColorsV2.primary;
const _kGold = AppColorsV2.tertiary;

// ─────────────────────────────────────────────────────────────────────────────
// Navigation helpers
// ─────────────────────────────────────────────────────────────────────────────

Route<void> wordInsightRoute({
  required String word,
  required int surahNumber,
  required int ayahNumber,
  String surahName = '',
  String revelationType = '',
  int position = 0,
  String contextTranslation = '',
  String transliteration = '',
}) {
  return MaterialPageRoute<void>(
    builder: (_) => WordInsightScreen(
      word: word,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      surahName: surahName,
      revelationType: revelationType,
      position: position,
      contextTranslation: contextTranslation,
      transliteration: transliteration,
    ),
  );
}

void openWordInsight(
  BuildContext context, {
  required String word,
  required int surahNumber,
  required int ayahNumber,
  String surahName = '',
  String revelationType = '',
  int position = 0,
  String contextTranslation = '',
  String transliteration = '',
}) {
  if (ArabicText.isOrnament(word)) return;
  Navigator.of(context).push(wordInsightRoute(
    word: word,
    surahNumber: surahNumber,
    ayahNumber: ayahNumber,
    surahName: surahName,
    revelationType: revelationType,
    position: position,
    contextTranslation: contextTranslation,
    transliteration: transliteration,
  ));
}

Future<void> showAyahWordPicker(
  BuildContext context, {
  required String ayahText,
  required int surahNumber,
  required int ayahNumber,
  String surahName = '',
  String revelationType = '',
}) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AyahWordPickerSheet(
      ayahText: ayahText,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      surahName: surahName,
      revelationType: revelationType,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Holdable ayah text
// ─────────────────────────────────────────────────────────────────────────────

class AyahWordText extends StatelessWidget {
  final String text;
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String revelationType;
  final TextStyle style;
  final Duration holdDuration;

  const AyahWordText({
    super.key,
    required this.text,
    required this.surahNumber,
    required this.ayahNumber,
    required this.style,
    this.surahName = '',
    this.revelationType = '',
    this.holdDuration = kWordHoldDuration,
  });

  @override
  Widget build(BuildContext context) {
    final words = ArabicText.splitWords(text);

    // Defensive: if tokenisation produced nothing usable, fall back to a
    // plain Text so the ayah is never blank.
    if (words.isEmpty) {
      return Text(
        text,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: style,
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        alignment: WrapAlignment.start,
        runAlignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        children: List<Widget>.generate(words.length, (i) {
          final word = words[i];
          if (ArabicText.isOrnament(word)) {
            return Text(word, style: style);
          }
          return _HoldableWord(
            word: word,
            style: style,
            holdDuration: holdDuration,
            onHold: () => openWordInsight(
              context,
              word: word,
              surahNumber: surahNumber,
              ayahNumber: ayahNumber,
              surahName: surahName,
              revelationType: revelationType,
              position: i + 1,
            ),
          );
        }),
      ),
    );
  }
}

class _HoldableWord extends StatefulWidget {
  final String word;
  final TextStyle style;
  final Duration holdDuration;
  final VoidCallback onHold;

  const _HoldableWord({
    required this.word,
    required this.style,
    required this.holdDuration,
    required this.onHold,
  });

  @override
  State<_HoldableWord> createState() => _HoldableWordState();
}

class _HoldableWordState extends State<_HoldableWord> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(duration: widget.holdDuration),
          (LongPressGestureRecognizer instance) {
            // NOTE: keep these as separate statements. Written as a cascade
            // (`..onLongPressDown = (_) => f()`), the arrow body swallows the
            // following `..` operators and the analyzer reports use_of_void_result.
            instance.onLongPressDown = (_) {
              _setPressed(true);
            };
            instance.onLongPressCancel = () {
              _setPressed(false);
            };
            instance.onLongPressUp = () {
              _setPressed(false);
            };
            instance.onLongPress = () {
              _setPressed(false);
              HapticFeedback.mediumImpact();
              widget.onHold();
            };
          },
        ),
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: _pressed ? _kGreen.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(widget.word, style: widget.style),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Picker sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AyahWordPickerSheet extends ConsumerWidget {
  final String ayahText;
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String revelationType;

  const _AyahWordPickerSheet({
    required this.ayahText,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.revelationType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync =
        ref.watch(ayahWordsProvider((surah: surahNumber, ayah: ayahNumber)));
    final fallback = ArabicText.splitWords(ayahText)
        .where((w) => !ArabicText.isOrnament(w))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.35,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColorsV2.bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: _kGreen.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.spellcheck_rounded,
                            color: _kGreen, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explore a word',
                              style: GoogleFonts.manrope(
                                color: AppColorsV2.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              surahName.isEmpty
                                  ? 'Ayah $surahNumber:$ayahNumber'
                                  : '$surahName · $surahNumber:$ayahNumber',
                              style: GoogleFonts.manrope(
                                color: AppColorsV2.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: AppColorsV2.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app_rounded,
                          size: 14, color: _kGold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap any word for its root, deep meaning and every '
                          'place it appears in the Quran.',
                          style: GoogleFonts.manrope(
                            color: AppColorsV2.onSurfaceVariant,
                            fontSize: 11.5,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                Expanded(
                  child: wordsAsync.when(
                    loading: () => _buildFallbackGrid(
                      context,
                      scrollController,
                      fallback,
                      loading: true,
                    ),
                    error: (_, __) => _buildFallbackGrid(
                      context,
                      scrollController,
                      fallback,
                    ),
                    data: (words) {
                      if (words.isEmpty) {
                        return _buildFallbackGrid(
                            context, scrollController, fallback);
                      }
                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                        itemCount: words.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _WordRow(
                          word: words[i],
                          onTap: () {
                            final navigator = Navigator.of(context);
                            final route = wordInsightRoute(
                              word: words[i].arabic,
                              surahNumber: surahNumber,
                              ayahNumber: ayahNumber,
                              surahName: surahName,
                              revelationType: revelationType,
                              position: words[i].position,
                              contextTranslation: words[i].translation,
                              transliteration: words[i].transliteration,
                            );
                            navigator.pop();
                            navigator.push(route);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackGrid(
    BuildContext context,
    ScrollController controller,
    List<String> words, {
    bool loading = false,
  }) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        if (loading)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _kGreen),
                ),
                const SizedBox(width: 10),
                Text(
                  'Loading word-by-word meanings…',
                  style: GoogleFonts.manrope(
                    color: AppColorsV2.onSurfaceVariant,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List<Widget>.generate(words.length, (i) {
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  if (ArabicText.isOrnament(words[i])) return;
                  final navigator = Navigator.of(context);
                  final route = wordInsightRoute(
                    word: words[i],
                    surahNumber: surahNumber,
                    ayahNumber: ayahNumber,
                    surahName: surahName,
                    revelationType: revelationType,
                    position: i + 1,
                  );
                  navigator.pop();
                  navigator.push(route);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColorsV2.surfaceLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColorsV2.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    words[i],
                    style: TextStyle(
                      fontSize: 24,
                      height: 1.8,
                      color: Colors.white,
                      fontFamily: GoogleFonts.amiri().fontFamily,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _WordRow extends StatelessWidget {
  final QuranWord word;
  final VoidCallback onTap;

  const _WordRow({required this.word, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColorsV2.surfaceLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kGold.withValues(alpha: 0.12),
              ),
              child: Text(
                '${word.position}',
                style: GoogleFonts.manrope(
                  color: _kGold,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (word.transliteration.isNotEmpty)
                    Text(
                      word.transliteration,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        color: AppColorsV2.onSurfaceVariant,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (word.translation.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        word.translation,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          color: AppColorsV2.onSurface,
                          fontSize: 13.5,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  word.arabic,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 24,
                    height: 1.9,
                    color: Colors.white,
                    fontFamily: GoogleFonts.amiri().fontFamily,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_left_rounded,
                size: 18, color: AppColorsV2.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
