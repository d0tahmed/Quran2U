// lib/screens/quiz_screen.dart
//
// The daily quiz and its result.
//
// The answer is revealed immediately after each tap rather than at the end.
// This is a study app, not an exam: the moment someone gets one wrong is the
// moment they are most receptive to being told why, and to a button that opens
// the surah it came from.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quran_recitation/models/models.dart';
import 'package:quran_recitation/providers/providers.dart';
import 'package:quran_recitation/screens/surah_detail_screen.dart';
import 'package:quran_recitation/services/quiz_engine.dart';
import 'package:quran_recitation/services/quiz_storage.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/app_typography.dart';
import 'package:quran_recitation/ui_v2/glass.dart';
import 'package:quran_recitation/ui_v2/widgets/q_kit.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late final int _dayIndex = QuizDay.today;
  late final DailyQuiz _quiz = QuizEngine.build(_dayIndex);

  int _index = 0;
  int _correct = 0;
  int? _picked;
  bool _finished = false;
  QuizProgress? _progress;

  /// Question indices whose hint has been opened.
  ///
  /// Tracked per index rather than as a single bool so going back over a
  /// question — or a rebuild — cannot silently re-hide a hint that was already
  /// spent, and so the result screen can report an honest count.
  final Set<int> _hinted = <int>{};

  bool get _hintShown => _hinted.contains(_index);

  /// Per-category tallies, so the stats screen can show where someone is weak.
  final Map<QuizCategory, int> _catCorrect = <QuizCategory, int>{};
  final Map<QuizCategory, int> _catSeen = <QuizCategory, int>{};

  QuizQuestion get _q => _quiz.questions[_index];

  Future<void> _choose(int option) async {
    if (_picked != null) return;
    final right = option == _q.correctIndex;
    HapticFeedback.selectionClick();
    setState(() {
      _picked = option;
      if (right) _correct++;
      _catSeen[_q.category] = (_catSeen[_q.category] ?? 0) + 1;
      if (right) {
        _catCorrect[_q.category] = (_catCorrect[_q.category] ?? 0) + 1;
      }
    });
  }

  Future<void> _next() async {
    if (_index + 1 < _quiz.questions.length) {
      setState(() {
        _index++;
        _picked = null;
      });
      return;
    }

    final total = _quiz.questions.length;
    final stars = QuizEngine.starsFor(_correct, total);
    final progress = await QuizStorage.record(
      dayIndex: _dayIndex,
      correct: _correct,
      total: total,
      stars: stars,
      categoryCorrect: _catCorrect,
      categorySeen: _catSeen,
    );
    if (!mounted) return;
    setState(() {
      _finished = true;
      _progress = progress;
    });
  }

  void _revealHint() {
    if (_hintShown || _picked != null) return;
    HapticFeedback.lightImpact();
    setState(() => _hinted.add(_index));
  }

  void _openSurah(int number) {
    final surahs = ref.read(surahsProvider).asData?.value ?? const <Surah>[];
    final match = surahs
        .cast<Surah?>()
        .firstWhere((s) => s?.number == number, orElse: () => null);
    if (match == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SurahDetailScreen(surah: match)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_quiz.questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColorsV2.bg,
        appBar: AppBar(title: Text('Daily Quiz', style: AppTypeV2.title(size: 16))),
        body: Center(
          child: Text('No questions available.',
              style: AppTypeV2.body(size: 13.5)),
        ),
      );
    }

    if (_finished) {
      return _ResultView(
        correct: _correct,
        total: _quiz.questions.length,
        hintsUsed: _hinted.length,
        progress: _progress,
      );
    }

    final total = _quiz.questions.length;

    return Scaffold(
      backgroundColor: AppColorsV2.bg,
      appBar: AppBar(
        title: Text('Daily Quiz', style: AppTypeV2.title(size: 16)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: (_index + 1) / total),
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, __) => LinearProgressIndicator(
                        value: value,
                        minHeight: 4,
                        backgroundColor: AppColorsV2.surfaceHighest,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColorsV2.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('${_index + 1} of $total',
                          style: AppTypeV2.caption(
                              size: 11, color: AppColorsV2.onSurfaceVariant)),
                      const Spacer(),
                      Text('$_correct correct',
                          style: AppTypeV2.caption(
                              size: 11, color: AppColorsV2.primary)),
                    ],
                  ),
                ],
              ),
            ),

            // ── Question ─────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(_q.category.label.toUpperCase(),
                            style: AppTypeV2.overline(size: 9.5)),
                      ),
                      // The hint disappears once an answer is locked in —
                      // after the reveal it would be advice about a decision
                      // already made.
                      if (_picked == null)
                        _HintButton(
                          used: _hintShown,
                          onTap: _revealHint,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(_q.prompt,
                      style: AppTypeV2.title(size: 19, weight: FontWeight.w800)),

                  // ── Hint ───────────────────────────────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _hintShown && _picked == null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: _HintCard(text: _q.hint),
                          )
                        : const SizedBox(width: double.infinity, height: 0),
                  ),

                  const SizedBox(height: 22),

                  for (var i = 0; i < _q.options.length; i++) ...[
                    _OptionTile(
                      text: _q.options[i],
                      state: _stateFor(i),
                      onTap: () => _choose(i),
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (_picked != null) ...[
                    const SizedBox(height: 8),
                    FrostedCard(
                      radius: 18,
                      padding: const EdgeInsets.all(16),
                      edgeColor: AppColorsV2.tertiary,
                      edgeIntensity: 0.26,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _picked == _q.correctIndex
                                    ? Icons.check_circle_rounded
                                    : Icons.info_rounded,
                                size: 16,
                                color: _picked == _q.correctIndex
                                    ? AppColorsV2.primary
                                    : AppColorsV2.tertiary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _picked == _q.correctIndex
                                    ? 'Correct'
                                    : 'Answer: ${_q.correctAnswer}',
                                style: AppTypeV2.caption(
                                  size: 12,
                                  color: _picked == _q.correctIndex
                                      ? AppColorsV2.primary
                                      : AppColorsV2.tertiary,
                                  weight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_q.why,
                              style: AppTypeV2.body(size: 12.5, height: 1.55)),
                          if (_q.openSurah != null) ...[
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: () => _openSurah(_q.openSurah!),
                              borderRadius: BorderRadius.circular(999),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.menu_book_rounded,
                                        size: 14, color: AppColorsV2.primary),
                                    const SizedBox(width: 7),
                                    Text('Read this surah',
                                        style: AppTypeV2.caption(
                                            size: 11.5,
                                            color: AppColorsV2.primary)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Next ─────────────────────────────────────────────────
            if (_picked != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorsV2.primary,
                      foregroundColor: AppColorsV2.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      _index + 1 == total ? 'See result' : 'Next',
                      style: AppTypeV2.title(
                          size: 14, color: AppColorsV2.onPrimary),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  _OptionState _stateFor(int i) {
    if (_picked == null) return _OptionState.idle;
    if (i == _q.correctIndex) return _OptionState.correct;
    if (i == _picked) return _OptionState.wrong;
    return _OptionState.dimmed;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hint
// ─────────────────────────────────────────────────────────────────────────────

/// The ask-for-help control.
///
/// Once spent it stays visible but goes quiet — hiding it would make the
/// screen jump, and greying it out is the honest signal that this question's
/// help has already been taken.
class _HintButton extends StatelessWidget {
  final bool used;
  final VoidCallback onTap;

  const _HintButton({required this.used, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = used
        ? AppColorsV2.onSurfaceVariant.withValues(alpha: 0.55)
        : AppColorsV2.tertiary;

    return GlassPressable(
      onTap: used ? null : onTap,
      scale: 0.93,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: used ? 0.06 : 0.13),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: used ? 0.18 : 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(used ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                size: 14, color: color),
            const SizedBox(width: 6),
            Text(used ? 'Hint used' : 'Hint',
                style: AppTypeV2.caption(size: 11, color: color)),
          ],
        ),
      ),
    );
  }
}

/// The hint itself. Gold-railed so it reads as help rather than as the answer,
/// which is deliberately a different colour from the green "Correct" card.
class _HintCard extends StatelessWidget {
  final String text;
  const _HintCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: AppColorsV2.tertiary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorsV2.tertiary.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded,
              size: 15, color: AppColorsV2.tertiary),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: AppTypeV2.body(
                size: 12.5,
                height: 1.55,
                color: AppColorsV2.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  const _OptionTile({
    required this.text,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color edge;
    Color label;
    switch (state) {
      case _OptionState.idle:
        edge = AppColorsV2.onSurface;
        label = AppColorsV2.onSurface;
        break;
      case _OptionState.correct:
        edge = AppColorsV2.primary;
        label = AppColorsV2.primary;
        break;
      case _OptionState.wrong:
        edge = AppColorsV2.danger;
        label = AppColorsV2.danger;
        break;
      case _OptionState.dimmed:
        edge = AppColorsV2.onSurface;
        label = AppColorsV2.onSurfaceVariant;
        break;
    }

    return Opacity(
      opacity: state == _OptionState.dimmed ? 0.5 : 1,
      child: FrostedCard(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        edgeColor: edge,
        edgeIntensity: state == _OptionState.idle ? 0.20 : 0.50,
        accent: state == _OptionState.idle ? null : edge,
        onTap: state == _OptionState.idle ? onTap : null,
        child: Row(
          children: [
            Expanded(
              child: Text(text,
                  style: AppTypeV2.title(
                      size: 14.5, weight: FontWeight.w700, color: label)),
            ),
            if (state == _OptionState.correct)
              const Icon(Icons.check_rounded,
                  size: 18, color: AppColorsV2.primary),
            if (state == _OptionState.wrong)
              const Icon(Icons.close_rounded,
                  size: 18, color: AppColorsV2.danger),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result
// ─────────────────────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final int correct;
  final int total;
  final int hintsUsed;
  final QuizProgress? progress;

  const _ResultView({
    required this.correct,
    required this.total,
    required this.hintsUsed,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final stars = QuizEngine.starsFor(correct, total);

    return Scaffold(
      backgroundColor: AppColorsV2.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              const Spacer(),

              QStarMedallion(
                size: 78,
                color: AppColorsV2.tertiary.withValues(alpha: 0.5),
                child: Text('$correct',
                    style: AppTypeV2.display(size: 30)),
              ),
              const SizedBox(height: 18),
              Text('$correct out of $total',
                  style: AppTypeV2.display(size: 26)),
              const SizedBox(height: 8),
              Text(
                stars == 3
                    ? 'Excellent'
                    : stars == 2
                        ? 'Well done'
                        : stars == 1
                            ? 'Good effort'
                            : 'Keep going',
                style: AppTypeV2.body(size: 13.5),
              ),

              // Reported, never penalised. Someone who reads a hint and then
              // gets it right has learnt the thing — that is the whole point.
              if (hintsUsed > 0) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        size: 13, color: AppColorsV2.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      hintsUsed == 1 ? '1 hint used' : '$hintsUsed hints used',
                      style: AppTypeV2.caption(
                          size: 11, color: AppColorsV2.onSurfaceVariant),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Icon(
                        i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 34,
                        color: i < stars
                            ? AppColorsV2.tertiary
                            : AppColorsV2.outlineVariant,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 30),
              if (progress != null)
                FrostedCard(
                  radius: 20,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  accent: AppColorsV2.primary,
                  edgeColor: AppColorsV2.primary,
                  edgeIntensity: 0.30,
                  child: Row(
                    children: [
                      _Stat(
                          value: '${progress!.currentStreak}',
                          label: 'day streak'),
                      _Divider(),
                      _Stat(
                          value: '${progress!.bestStreak}', label: 'best'),
                      _Divider(),
                      _Stat(
                          value: '${progress!.totalStars}', label: 'stars'),
                    ],
                  ),
                ),

              const Spacer(),
              Text('A new quiz every day',
                  style: AppTypeV2.caption(
                      size: 11.5, color: AppColorsV2.onSurfaceVariant)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorsV2.primary,
                    foregroundColor: AppColorsV2.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Done',
                      style: AppTypeV2.title(
                          size: 14, color: AppColorsV2.onPrimary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTypeV2.display(size: 22)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypeV2.caption(
                  size: 10, color: AppColorsV2.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 30,
        color: AppColorsV2.hairline,
        margin: const EdgeInsets.symmetric(horizontal: 10),
      );
}
