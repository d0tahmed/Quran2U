// lib/services/time_format.dart
//
// One place that decides how a clock time is written in Quran2U.
//
// `DateFormat.jm()` is locale-dependent — on a device whose locale prefers a
// 24-hour clock it silently renders "17:03". Prayer times are always shown in
// 12-hour form here, so the pattern is explicit rather than locale-derived.

import 'package:intl/intl.dart';

class TimeFormat {
  TimeFormat._();

  /// "5:03 PM" — the canonical prayer-time format.
  static String clock(DateTime time) => DateFormat('h:mm a').format(time);

  /// "5:03" — the numerals only, for tight cells where the meridiem is
  /// rendered on its own line.
  static String hourMinute(DateTime time) => DateFormat('h:mm').format(time);

  /// "PM" — the meridiem on its own.
  static String meridiem(DateTime time) => DateFormat('a').format(time);

  /// Minutes elapsed since local midnight — the form the home-screen widget
  /// stores so it can recompute the active prayer without Dart running.
  static int minutesSinceMidnight(DateTime time) =>
      time.hour * 60 + time.minute;

  /// "2h 14m" / "14m" — a countdown with no leading preposition.
  static String countdown(Duration diff) {
    if (diff.isNegative) return '';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}
