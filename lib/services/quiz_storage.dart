// lib/services/quiz_storage.dart
//
// Streak, stars, per-category mastery and the record of which days were
// played. Small enough for SharedPreferences: a few ints, one short string per
// completed day, and a capped list of day indices for the calendar.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_recitation/services/quiz_engine.dart';

/// Which quiz belongs to which calendar day.
///
/// Deliberately NOT the helper the Daily Inspiration pool uses — that one
/// returns an index already wrapped by the pool length, which would make the
/// quiz repeat every 56 days. This is the raw day count, so the seed keeps
/// increasing forever.
class QuizDay {
  QuizDay._();

  static int indexFor(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day)
          .difference(DateTime.utc(2000, 1, 1))
          .inDays;

  static int get today => indexFor(DateTime.now());

  /// Turns a day index back into a calendar date, for the labels.
  ///
  /// Deliberately NOT `.toLocal()`. The index is built from local *calendar*
  /// components anchored to a UTC midnight, so converting back through the
  /// timezone would shift the date a day earlier for anyone west of UTC —
  /// their calendar would be labelled with yesterday. Reading the UTC
  /// components straight back out is the exact inverse of [indexFor].
  static DateTime dateFor(int index) {
    final utc = DateTime.utc(2000, 1, 1).add(Duration(days: index));
    return DateTime(utc.year, utc.month, utc.day);
  }
}

/// One finished day, as the calendar needs it.
@immutable
class QuizDayResult {
  final int dayIndex;
  final int correct;
  final int total;

  const QuizDayResult({
    required this.dayIndex,
    required this.correct,
    required this.total,
  });

  int get stars => QuizEngine.starsFor(correct, total);

  DateTime get date => QuizDay.dateFor(dayIndex);
}

@immutable
class QuizProgress {
  final int currentStreak;
  final int bestStreak;
  final int totalStars;
  final int quizzesTaken;
  final int totalCorrect;
  final int totalAnswered;

  /// Day index of the most recently completed quiz, or -1.
  final int lastCompletedDay;

  /// Score for today, or null when today has not been played.
  final int? todayCorrect;
  final int? todayTotal;

  /// Day indices that were completed, newest last.
  final List<int> playedDays;

  /// The score for every day in [playedDays], keyed by day index.
  ///
  /// Loaded eagerly rather than on tap: the list is capped at 120 entries and
  /// each is a six-character string, so reading them all costs less than the
  /// async round-trip a tap handler would otherwise need — and the calendar
  /// can then answer instantly instead of flashing a spinner per square.
  final Map<int, QuizDayResult> results;

  /// Correct and seen counts per category.
  final Map<QuizCategory, int> correctByCategory;
  final Map<QuizCategory, int> seenByCategory;

  const QuizProgress({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.totalStars = 0,
    this.quizzesTaken = 0,
    this.totalCorrect = 0,
    this.totalAnswered = 0,
    this.lastCompletedDay = -1,
    this.todayCorrect,
    this.todayTotal,
    this.playedDays = const <int>[],
    this.results = const <int, QuizDayResult>{},
    this.correctByCategory = const <QuizCategory, int>{},
    this.seenByCategory = const <QuizCategory, int>{},
  });

  /// The stored result for a day, or null if it was never played (or has
  /// aged out of the 120-day window).
  QuizDayResult? resultFor(int dayIndex) => results[dayIndex];

  bool get playedToday => todayCorrect != null;

  /// Stars earned today, or null when today has not been played.
  int? get todayStars {
    final c = todayCorrect, t = todayTotal;
    if (c == null || t == null || t == 0) return null;
    return QuizEngine.starsFor(c, t);
  }

  /// 0..1 accuracy overall, or null before anything has been answered.
  double? get accuracy =>
      totalAnswered == 0 ? null : totalCorrect / totalAnswered;

  /// 0..1 mastery for one category, or null when it has never appeared.
  double? masteryFor(QuizCategory category) {
    final seen = seenByCategory[category] ?? 0;
    if (seen == 0) return null;
    return (correctByCategory[category] ?? 0) / seen;
  }

  /// The category with the lowest mastery that has been seen enough to judge.
  QuizCategory? get weakest {
    QuizCategory? worst;
    double lowest = 2;
    for (final c in QuizCategory.values) {
      if ((seenByCategory[c] ?? 0) < 4) continue;
      final m = masteryFor(c);
      if (m != null && m < lowest) {
        lowest = m;
        worst = c;
      }
    }
    return worst;
  }
}

class QuizStorage {
  QuizStorage._();

  static const _kStreak = 'quiz_streak_v1';
  static const _kBest = 'quiz_best_streak_v1';
  static const _kStars = 'quiz_total_stars_v1';
  static const _kTaken = 'quiz_taken_v1';
  static const _kLastDay = 'quiz_last_day_v1';
  static const _kDays = 'quiz_days_v1';
  static const _kCorrect = 'quiz_total_correct_v1';
  static const _kAnswered = 'quiz_total_answered_v1';

  /// How many day indices the calendar keeps. Roughly four months.
  static const int _dayHistoryCap = 120;

  static String _resultKey(int day) => 'quiz_result_${day}_v1';
  static String _catCorrect(QuizCategory c) => 'quiz_cat_${c.name}_correct_v1';
  static String _catSeen(QuizCategory c) => 'quiz_cat_${c.name}_seen_v1';

  static Future<QuizProgress> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = QuizDay.today;

      int? correct, total;
      final raw = prefs.getString(_resultKey(today));
      if (raw != null) {
        final parts = raw.split('/');
        if (parts.length == 2) {
          correct = int.tryParse(parts[0]);
          total = int.tryParse(parts[1]);
        }
      }

      final days = (prefs.getStringList(_kDays) ?? const <String>[])
          .map(int.tryParse)
          .whereType<int>()
          .toList(growable: false);

      final results = <int, QuizDayResult>{};
      for (final day in days) {
        final stored = prefs.getString(_resultKey(day));
        if (stored == null) continue;
        final parts = stored.split('/');
        if (parts.length != 2) continue;
        final c = int.tryParse(parts[0]);
        final t = int.tryParse(parts[1]);
        if (c == null || t == null || t <= 0) continue;
        results[day] = QuizDayResult(dayIndex: day, correct: c, total: t);
      }

      final byCorrect = <QuizCategory, int>{};
      final bySeen = <QuizCategory, int>{};
      for (final c in QuizCategory.values) {
        byCorrect[c] = prefs.getInt(_catCorrect(c)) ?? 0;
        bySeen[c] = prefs.getInt(_catSeen(c)) ?? 0;
      }

      return QuizProgress(
        currentStreak: prefs.getInt(_kStreak) ?? 0,
        bestStreak: prefs.getInt(_kBest) ?? 0,
        totalStars: prefs.getInt(_kStars) ?? 0,
        quizzesTaken: prefs.getInt(_kTaken) ?? 0,
        totalCorrect: prefs.getInt(_kCorrect) ?? 0,
        totalAnswered: prefs.getInt(_kAnswered) ?? 0,
        lastCompletedDay: prefs.getInt(_kLastDay) ?? -1,
        todayCorrect: correct,
        todayTotal: total,
        playedDays: days,
        results: results,
        correctByCategory: byCorrect,
        seenByCategory: bySeen,
      );
    } catch (e) {
      debugPrint('[Quiz] load failed: $e');
      return const QuizProgress();
    }
  }

  /// Records a finished quiz and returns the updated progress.
  ///
  /// The streak counts DAYS ATTEMPTED, not days passed. Breaking someone's
  /// streak over a low score punishes exactly the person who most needs to
  /// come back tomorrow.
  ///
  /// Replaying the same day updates the stored score but inflates nothing —
  /// no extra streak, stars, or category counts.
  static Future<QuizProgress> record({
    required int dayIndex,
    required int correct,
    required int total,
    required int stars,
    required Map<QuizCategory, int> categoryCorrect,
    required Map<QuizCategory, int> categorySeen,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final alreadyPlayed = prefs.getString(_resultKey(dayIndex)) != null;
      await prefs.setString(_resultKey(dayIndex), '$correct/$total');

      if (!alreadyPlayed) {
        final lastDay = prefs.getInt(_kLastDay) ?? -1;
        final streak = prefs.getInt(_kStreak) ?? 0;
        final next = lastDay == dayIndex - 1 ? streak + 1 : 1;

        await prefs.setInt(_kStreak, next);
        if (next > (prefs.getInt(_kBest) ?? 0)) {
          await prefs.setInt(_kBest, next);
        }
        await prefs.setInt(_kLastDay, dayIndex);
        await prefs.setInt(_kStars, (prefs.getInt(_kStars) ?? 0) + stars);
        await prefs.setInt(_kTaken, (prefs.getInt(_kTaken) ?? 0) + 1);
        await prefs.setInt(_kCorrect, (prefs.getInt(_kCorrect) ?? 0) + correct);
        await prefs.setInt(_kAnswered, (prefs.getInt(_kAnswered) ?? 0) + total);

        for (final c in QuizCategory.values) {
          final gotRight = categoryCorrect[c] ?? 0;
          final saw = categorySeen[c] ?? 0;
          if (saw == 0) continue;
          await prefs.setInt(_catCorrect(c), (prefs.getInt(_catCorrect(c)) ?? 0) + gotRight);
          await prefs.setInt(_catSeen(c), (prefs.getInt(_catSeen(c)) ?? 0) + saw);
        }

        final days = List<String>.of(prefs.getStringList(_kDays) ?? const <String>[]);
        if (!days.contains('$dayIndex')) days.add('$dayIndex');
        while (days.length > _dayHistoryCap) {
          // Drop the day AND its score. Leaving the score behind would grow
          // SharedPreferences by one orphaned key per day, forever.
          final dropped = days.removeAt(0);
          final droppedDay = int.tryParse(dropped);
          if (droppedDay != null) {
            await prefs.remove(_resultKey(droppedDay));
          }
        }
        await prefs.setStringList(_kDays, days);
      }
    } catch (e) {
      debugPrint('[Quiz] record failed: $e');
    }
    return load();
  }
}
