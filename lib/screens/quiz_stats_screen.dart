// lib/screens/quiz_stats_screen.dart
//
// What the quiz has taught you, and how consistently.
//
// The calendar is the point of the screen. A number that says "23 day streak"
// is abstract; a grid where the gaps are visible is the thing that makes
// someone not want another gap.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:quran_recitation/services/quiz_engine.dart';
import 'package:quran_recitation/services/quiz_storage.dart';
import 'package:quran_recitation/ui_v2/app_colors.dart';
import 'package:quran_recitation/ui_v2/app_typography.dart';
import 'package:quran_recitation/ui_v2/glass.dart';
import 'package:quran_recitation/ui_v2/widgets/q_kit.dart';

class QuizStatsScreen extends StatefulWidget {
  const QuizStatsScreen({super.key});

  @override
  State<QuizStatsScreen> createState() => _QuizStatsScreenState();
}

class _QuizStatsScreenState extends State<QuizStatsScreen> {
  QuizProgress? _progress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await QuizStorage.load();
    if (mounted) setState(() => _progress = p);
  }

  @override
  Widget build(BuildContext context) {
    final p = _progress;

    return Scaffold(
      backgroundColor: AppColorsV2.bg,
      appBar: AppBar(
        title: Text('Your progress', style: AppTypeV2.title(size: 16)),
      ),
      body: p == null
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColorsV2.primary),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
              children: [
                // ── Headline numbers ──────────────────────────────────
                FrostedCard(
                  radius: 24,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 20),
                  accent: AppColorsV2.primary,
                  edgeColor: AppColorsV2.primary,
                  edgeIntensity: 0.34,
                  glow: p.currentStreak > 0 ? AppColorsV2.primary : null,
                  child: Row(
                    children: [
                      _Big(value: '${p.currentStreak}', label: 'day streak'),
                      _VDivider(),
                      _Big(value: '${p.bestStreak}', label: 'best'),
                      _VDivider(),
                      _Big(value: '${p.totalStars}', label: 'stars'),
                    ],
                  ),
                ),

                const SizedBox(height: 22),
                const QSectionHeader(label: 'Last 12 weeks'),
                const SizedBox(height: 12),
                _Calendar(progress: p),

                const SizedBox(height: 26),
                QSectionHeader(
                  label: 'What you know',
                  trailing: p.accuracy == null
                      ? null
                      : Text(
                          '${(p.accuracy! * 100).round()}% overall',
                          style: AppTypeV2.caption(
                              size: 11, color: AppColorsV2.primary),
                        ),
                ),
                const SizedBox(height: 12),
                FrostedCard(
                  radius: 22,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                  child: Column(
                    children: [
                      for (final c in QuizCategory.values)
                        _MasteryBar(
                          label: c.label,
                          value: p.masteryFor(c),
                          seen: p.seenByCategory[c] ?? 0,
                        ),
                    ],
                  ),
                ),

                if (p.weakest != null) ...[
                  const SizedBox(height: 14),
                  FrostedCard(
                    radius: 18,
                    padding: const EdgeInsets.all(15),
                    edgeColor: AppColorsV2.tertiary,
                    edgeIntensity: 0.24,
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded,
                            size: 16, color: AppColorsV2.tertiary),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'Your weakest area is ${p.weakest!.label}. '
                            'Questions there will come up a little more often.',
                            style: AppTypeV2.body(size: 12, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 26),
                const QSectionHeader(label: 'All time'),
                const SizedBox(height: 12),
                FrostedCard(
                  radius: 22,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 6),
                  child: Column(
                    children: [
                      _Row(
                          label: 'Quizzes completed',
                          value: '${p.quizzesTaken}'),
                      _Row(
                          label: 'Questions answered',
                          value: '${p.totalAnswered}'),
                      _Row(
                          label: 'Answered correctly',
                          value: '${p.totalCorrect}'),
                      _Row(
                        label: 'Accuracy',
                        value: p.accuracy == null
                            ? '—'
                            : '${(p.accuracy! * 100).round()}%',
                        last: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Calendar ────────────────────────────────────────────────────────────────

/// Twelve weeks of dots, most recent column on the right. A filled dot is a
/// day the quiz was completed; tapping any dot opens that day below the grid.
///
/// The old footer printed one fixed date ("2 Jun") that never changed and
/// explained nothing. It has been replaced by month labels along the top —
/// which give the grid a real time axis — and a detail panel that answers the
/// question a date label was only gesturing at: what happened on that day.
class _Calendar extends StatefulWidget {
  final QuizProgress progress;
  const _Calendar({required this.progress});

  @override
  State<_Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<_Calendar> {
  static const int _weeks = 12;

  /// The day the detail panel is describing. Defaults to today.
  late int _selected = QuizDay.today;

  void _select(int day) {
    if (_selected == day) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = day);
  }

  @override
  Widget build(BuildContext context) {
    final today = QuizDay.today;
    // Align so the last column ends on today.
    final start = today - (_weeks * 7 - 1);

    return FrostedCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // SLOTS, not cell-plus-padding.
              //
              // The previous version computed a cell and a gap that summed to
              // the available width, and then wrapped each dot in extra
              // padding to make the tap target big enough — which added ~50dp
              // of width the arithmetic knew nothing about, and the grid ran
              // straight off the card. Dividing the width into twelve equal
              // slots and centring a dot inside each one cannot overflow by
              // construction: the row is exactly `slot * 12` wide whatever the
              // dot does, and the whole slot is the tap target.
              const double maxCell = 18;
              const double minCell = 6;
              const double minGap = 4;
              const double maxSlot = 30;

              final slot =
                  (constraints.maxWidth / _weeks).clamp(minCell + minGap, maxSlot);
              final cell = (slot - minGap).clamp(minCell, maxCell);
              const double vGap = 5;

              return Column(
                children: [
                  // Month labels give the grid a time axis, so a column can be
                  // located without counting weeks backwards from today.
                  _MonthRuler(start: start, weeks: _weeks, slot: slot),
                  const SizedBox(height: 6),
                  for (var row = 0; row < 7; row++)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var col = 0; col < _weeks; col++)
                          _dot(
                            start + col * 7 + row,
                            today,
                            cell,
                            slot,
                            cell + vGap,
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          const GlassDivider(),
          const SizedBox(height: 13),
          _DayDetail(
            day: _selected,
            today: QuizDay.today,
            result: widget.progress.resultFor(_selected),
          ),
        ],
      ),
    );
  }

  /// One day. [slot] and [slotHeight] are the tap target; [size] is the dot
  /// drawn inside it.
  Widget _dot(
    int day,
    int today,
    double size,
    double slot,
    double slotHeight,
  ) {
    final future = day > today;
    final result = widget.progress.resultFor(day);
    final done = result != null;
    final isToday = day == today;
    final isSelected = day == _selected;

    // Completed days are shaded by how well they went, so the grid reads as
    // performance over time rather than as mere attendance.
    final Color fill;
    if (future) {
      fill = AppColorsV2.surfaceHighest.withValues(alpha: 0.28);
    } else if (done) {
      final stars = result.stars;
      fill = AppColorsV2.primary.withValues(
          alpha: stars >= 3 ? 1.0 : (stars == 2 ? 0.72 : 0.46));
    } else {
      fill = AppColorsV2.surfaceHighest;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _select(day),
      // The tap target is the whole slot — roughly 24 x 23 on a 360dp phone
      // rather than the 18dp dot. The dot is centred inside it and the gap
      // between dots is what is left over, so nothing is added to the width.
      child: SizedBox(
        width: slot,
        height: slotHeight,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.28),
              color: fill,
              border: isSelected
                  ? Border.all(color: AppColorsV2.onSurface, width: 1.6)
                  : isToday
                      ? Border.all(color: AppColorsV2.tertiary, width: 1.4)
                      : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// The month names running along the top of the grid.
///
/// A label is drawn only on the first column of each month, positioned over
/// that column — the same convention a contribution graph uses, because
/// labelling every column would be unreadable at this width.
class _MonthRuler extends StatelessWidget {
  final int start;
  final int weeks;
  final double slot;

  const _MonthRuler({
    required this.start,
    required this.weeks,
    required this.slot,
  });

  @override
  Widget build(BuildContext context) {
    final labels = <int, String>{};
    var lastMonth = -1;

    for (var col = 0; col < weeks; col++) {
      // The month a column belongs to is the month of its middle day, so a
      // column straddling a boundary is not labelled twice.
      final date = QuizDay.dateFor(start + col * 7 + 3);
      if (date.month != lastMonth) {
        lastMonth = date.month;
        // "Aug" needs about two slots. A label starting in the last two
        // columns would paint past the edge of the card, so it is dropped —
        // the column it would have marked is still readable from its
        // neighbour.
        if (col < weeks - 2) labels[col] = DateFormat('MMM').format(date);
      }
    }

    return SizedBox(
      height: 13,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var col = 0; col < weeks; col++)
            SizedBox(
              width: slot,
              child: labels.containsKey(col)
                  // Deliberate overflow: "Aug" is wider than one slot, and
                  // clipping it to the slot would render "A". OverflowBox lets
                  // it spill into the next column, which by definition has no
                  // label of its own — a month is at least four columns wide.
                  ? OverflowBox(
                      alignment: Alignment.centerLeft,
                      maxWidth: slot * 2.4,
                      child: Text(
                        labels[col]!,
                        maxLines: 1,
                        softWrap: false,
                        style: AppTypeV2.caption(
                            size: 9.5,
                            color: AppColorsV2.onSurfaceVariant
                                .withValues(alpha: 0.85)),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

/// What happened on the selected day.
class _DayDetail extends StatelessWidget {
  final int day;
  final int today;
  final QuizDayResult? result;

  const _DayDetail({
    required this.day,
    required this.today,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final date = QuizDay.dateFor(day);
    final isToday = day == today;
    final future = day > today;
    final away = day - today;

    late final IconData icon;
    late final Color color;
    late final String title;
    late final String subtitle;

    if (result != null) {
      icon = Icons.check_circle_rounded;
      color = AppColorsV2.primary;
      title = '${result!.correct} out of ${result!.total} correct';
      final stars = result!.stars;
      subtitle = stars == 0
          ? 'No stars that day'
          : '${stars == 1 ? '1 star' : '$stars stars'} earned';
    } else if (future) {
      icon = Icons.lock_clock_rounded;
      color = AppColorsV2.onSurfaceVariant;
      title = away == 1
          ? 'Tomorrow\'s quiz'
          : 'Unlocks in $away days';
      // The user asked for "reach week N and find out" — this is that, said
      // in days when it is close and in weeks when it is not, because "in 38
      // days" means less to a person than "about 5 weeks away".
      final weeks = (away / 7).ceil();
      subtitle = away <= 6
          ? 'Come back on ${DateFormat('EEEE').format(date)} to play it'
          : 'About $weeks weeks away — keep the streak going until then';
    } else if (isToday) {
      icon = Icons.today_rounded;
      color = AppColorsV2.tertiary;
      title = 'Today';
      subtitle = 'Not played yet — ten questions are waiting';
    } else {
      icon = Icons.remove_circle_outline_rounded;
      color = AppColorsV2.onSurfaceVariant;
      title = 'Not played';
      final ago = today - day;
      subtitle = ago == 1
          ? 'Yesterday — this one got away'
          : '$ago days ago';
    }

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypeV2.title(size: 13.5),
                    ),
                  ),
                  if (result != null) ...[
                    const SizedBox(width: 8),
                    for (var i = 0; i < 3; i++)
                      Icon(
                        i < result!.stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 12,
                        color: i < result!.stars
                            ? AppColorsV2.tertiary
                            : AppColorsV2.onSurfaceVariant
                                .withValues(alpha: 0.35),
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypeV2.caption(
                    size: 10.5, color: AppColorsV2.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          DateFormat('d MMM').format(date),
          style: AppTypeV2.caption(
              size: 10.5,
              color: AppColorsV2.onSurfaceVariant.withValues(alpha: 0.75)),
        ),
      ],
    );
  }
}

// ── Small parts ─────────────────────────────────────────────────────────────

class _Big extends StatelessWidget {
  final String value;
  final String label;
  const _Big({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTypeV2.display(size: 30)),
          const SizedBox(height: 3),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypeV2.caption(
                  size: 10.5, color: AppColorsV2.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 34,
        color: AppColorsV2.hairline,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      );
}

class _MasteryBar extends StatelessWidget {
  final String label;
  final double? value;
  final int seen;

  const _MasteryBar({
    required this.label,
    required this.value,
    required this.seen,
  });

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypeV2.caption(
                        size: 12, color: AppColorsV2.onSurface)),
              ),
              Text(
                v == null ? 'not seen yet' : '${(v * 100).round()}%',
                style: AppTypeV2.caption(
                  size: 11,
                  color: v == null
                      ? AppColorsV2.onSurfaceVariant.withValues(alpha: 0.7)
                      : AppColorsV2.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: v ?? 0,
              minHeight: 5,
              backgroundColor: AppColorsV2.surfaceHighest,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColorsV2.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _Row({required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColorsV2.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppTypeV2.body(size: 13, color: AppColorsV2.onSurface)),
          ),
          Text(value,
              style: AppTypeV2.title(size: 14, weight: FontWeight.w800)),
        ],
      ),
    );
  }
}
