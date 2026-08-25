// lib/services/hifz_storage.dart
//
// What has been memorised, how firmly, and what is due to be heard again.
//
// THE MODEL
// ---------
// Memorisation is not a boolean. An ayah you recited perfectly this morning
// and one you last touched in March are both "memorised" and neither is in the
// same state, so a flag per ayah would be useless within a week. Each ayah
// instead carries a STRENGTH from 0 to 5 and the day it was last reviewed, and
// the pair decides when it comes back.
//
// The intervals are the ordinary spaced-repetition ladder — 1, 2, 4, 8, 16, 32
// days — with one deliberate difference: a failed recall drops the strength by
// two rather than resetting it to zero. Hifz is not vocabulary. Someone who
// has held an ayah for a month and stumbles once has not lost it, and sending
// them back to the very beginning is both untrue and dispiriting.
//
// WHY SHARED PREFERENCES AND NOT A DATABASE
// -----------------------------------------
// The whole Quran is 6236 ayat. Even someone who memorised every one of them
// would store 6236 short strings, which is a few hundred kilobytes — well
// inside what SharedPreferences handles without complaint, and it avoids
// adding a schema, a migration path and an async open to a feature that has to
// be instant.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One ayah's memorisation state.
@immutable
class HifzAyah {
  final int surah;
  final int ayah;

  /// 0 = just started, 5 = solid. Drives the review interval.
  final int strength;

  /// Day-of-epoch of the last review.
  final int lastReviewedDay;

  const HifzAyah({
    required this.surah,
    required this.ayah,
    required this.strength,
    required this.lastReviewedDay,
  });

  String get key => '$surah:$ayah';

  /// Days to wait at each strength. Index is the strength.
  static const List<int> intervals = <int>[1, 2, 4, 8, 16, 32];

  int get dueDay => lastReviewedDay + intervals[strength.clamp(0, 5)];

  bool isDueOn(int day) => day >= dueDay;

  /// Solid enough to count towards "memorised" rather than "learning".
  bool get isFirm => strength >= 3;

  /// `2:255|4|9733`
  String encode() => '$surah:$ayah|$strength|$lastReviewedDay';

  static HifzAyah? decode(String raw) {
    final parts = raw.split('|');
    if (parts.length != 3) return null;
    final ref = parts[0].split(':');
    if (ref.length != 2) return null;

    final s = int.tryParse(ref[0]);
    final a = int.tryParse(ref[1]);
    final strength = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (s == null || a == null || strength == null || day == null) return null;
    if (s < 1 || s > 114 || a < 1) return null;

    return HifzAyah(
      surah: s,
      ayah: a,
      strength: strength.clamp(0, 5),
      lastReviewedDay: day,
    );
  }
}

/// Everything the Hifz screens need, read in one go.
@immutable
class HifzProgress {
  /// Every tracked ayah, keyed by `surah:ayah`.
  final Map<String, HifzAyah> ayat;

  /// Day-of-epoch this was computed for. Due-dates are relative to it.
  final int today;

  const HifzProgress({required this.ayat, required this.today});

  static const HifzProgress empty =
      HifzProgress(ayat: <String, HifzAyah>{}, today: 0);

  int get trackedCount => ayat.length;

  int get firmCount => ayat.values.where((a) => a.isFirm).length;

  int get learningCount => ayat.length - firmCount;

  /// Everything whose interval has elapsed, weakest first — a review session
  /// should open on the ayah most at risk, not on whatever sorts first.
  List<HifzAyah> get due {
    final list = ayat.values.where((a) => a.isDueOn(today)).toList();
    list.sort((x, y) {
      final byStrength = x.strength.compareTo(y.strength);
      if (byStrength != 0) return byStrength;
      // Then by how overdue it is.
      return x.dueDay.compareTo(y.dueDay);
    });
    return list;
  }

  /// Ayat tracked per surah, for the progress list.
  Map<int, int> get bySurah {
    final counts = <int, int>{};
    for (final a in ayat.values) {
      counts[a.surah] = (counts[a.surah] ?? 0) + 1;
    }
    return counts;
  }

  /// Firm ayat per surah.
  Map<int, int> get firmBySurah {
    final counts = <int, int>{};
    for (final a in ayat.values) {
      if (a.isFirm) counts[a.surah] = (counts[a.surah] ?? 0) + 1;
    }
    return counts;
  }

  HifzAyah? forKey(int surah, int ayah) => ayat['$surah:$ayah'];

  /// The lowest ayah number in [surah] that is not tracked yet — where a
  /// "memorise new" session should begin.
  int nextUnlearned(int surah, int ayahCount) {
    for (var a = 1; a <= ayahCount; a++) {
      if (!ayat.containsKey('$surah:$a')) return a;
    }
    return ayahCount; // Whole surah tracked; land on the last ayah.
  }
}

class HifzStorage {
  HifzStorage._();

  static const String _kAyat = 'hifz_ayat_v1';
  static const String _kRepeat = 'hifz_repeat_v1';
  static const String _kLastSurah = 'hifz_last_surah_v1';
  static const String _kLastAyah = 'hifz_last_ayah_v1';

  /// Day-of-epoch, the same convention the quiz uses. Built from local
  /// calendar parts anchored to a UTC midnight so it advances by exactly one
  /// per calendar day and never shifts under a timezone change.
  static int dayIndex(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day)
          .difference(DateTime.utc(2000, 1, 1))
          .inDays;

  static int get today => dayIndex(DateTime.now());

  static Future<HifzProgress> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kAyat) ?? const <String>[];

      final map = <String, HifzAyah>{};
      for (final line in raw) {
        final decoded = HifzAyah.decode(line);
        if (decoded != null) map[decoded.key] = decoded;
      }
      return HifzProgress(ayat: map, today: today);
    } catch (e) {
      debugPrint('[Hifz] load failed: $e');
      return HifzProgress(ayat: const <String, HifzAyah>{}, today: today);
    }
  }

  /// Records one recall attempt and returns the updated progress.
  ///
  /// [remembered] true promotes by one, false demotes by two — see the note at
  /// the top of the file for why two and not all the way down.
  static Future<HifzProgress> record({
    required int surah,
    required int ayah,
    required bool remembered,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = List<String>.of(prefs.getStringList(_kAyat) ?? const <String>[]);

      final map = <String, HifzAyah>{};
      for (final line in raw) {
        final decoded = HifzAyah.decode(line);
        if (decoded != null) map[decoded.key] = decoded;
      }

      final key = '$surah:$ayah';
      final existing = map[key];
      final was = existing?.strength ?? 0;
      final now = remembered ? (was + 1).clamp(0, 5) : (was - 2).clamp(0, 5);

      map[key] = HifzAyah(
        surah: surah,
        ayah: ayah,
        strength: now,
        lastReviewedDay: today,
      );

      await prefs.setStringList(
        _kAyat,
        map.values.map((a) => a.encode()).toList(growable: false),
      );
    } catch (e) {
      debugPrint('[Hifz] record failed: $e');
    }
    return load();
  }

  /// Removes an ayah from tracking entirely.
  static Future<HifzProgress> forget({
    required int surah,
    required int ayah,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kAyat) ?? const <String>[];
      final kept = raw.where((line) {
        final decoded = HifzAyah.decode(line);
        return decoded == null || decoded.key != '$surah:$ayah';
      }).toList(growable: false);
      await prefs.setStringList(_kAyat, kept);
    } catch (e) {
      debugPrint('[Hifz] forget failed: $e');
    }
    return load();
  }

  // ── Session preferences ──────────────────────────────────────────────

  /// How many times an ayah plays before the drill moves on.
  static Future<int> repeatCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getInt(_kRepeat) ?? 3).clamp(1, 10);
    } catch (_) {
      return 3;
    }
  }

  static Future<void> setRepeatCount(int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kRepeat, value.clamp(1, 10));
    } catch (_) {
      // A lost preference is not worth surfacing.
    }
  }

  /// Where the last session left off, so "Continue" means something.
  static Future<(int, int)?> lastPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getInt(_kLastSurah);
      final a = prefs.getInt(_kLastAyah);
      if (s == null || a == null) return null;
      if (s < 1 || s > 114 || a < 1) return null;
      return (s, a);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setLastPosition(int surah, int ayah) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastSurah, surah);
      await prefs.setInt(_kLastAyah, ayah);
    } catch (_) {
      // Same.
    }
  }
}
