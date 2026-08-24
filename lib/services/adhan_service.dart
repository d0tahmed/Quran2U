// lib/services/adhan_service.dart
//
// The Dart half of the adhan engine.
//
// It owns settings and publishing; it owns no playback and no alarms. Those
// live in Kotlin (AdhanScheduler, AdhanReceiver, AdhanService) because every
// step after "the alarm was set" happens with this isolate dead — the app
// swiped away, the device dozing, four minutes of audio to play.
//
// THE BRIDGE
// ----------
// There is no MethodChannel, because this app has no MainActivity to hang one
// on: the launcher activity comes from audio_service. Instead everything moves
// through the SharedPreferences file that home_widget already maintains, and
// the native side is nudged with an explicit broadcast. That is fewer moving
// parts than a channel, and it keeps working when the app is not running.
//
// ONE SOURCE OF TIMES
// -------------------
// The alarms are armed from `sched_v2` — the exact rows WidgetService writes
// for the home-screen widget. If the widget says Asr is at 5:10, the adhan
// fires at 5:10, because there is only one set of numbers to disagree about.

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'package:quran_recitation/services/widget_service.dart';

/// What should happen at a given prayer.
enum AdhanMode {
  /// Play the full adhan on the alarm stream.
  full,

  /// Post a silent notification, no audio.
  notify,

  /// Nothing at all.
  off,
}

extension AdhanModeX on AdhanMode {
  String get storageValue {
    switch (this) {
      case AdhanMode.full:
        return 'full';
      case AdhanMode.notify:
        return 'notify';
      case AdhanMode.off:
        return 'off';
    }
  }

  String get label {
    switch (this) {
      case AdhanMode.full:
        return 'Adhan';
      case AdhanMode.notify:
        return 'Silent';
      case AdhanMode.off:
        return 'Off';
    }
  }

  static AdhanMode parse(String? raw) {
    switch (raw) {
      case 'full':
        return AdhanMode.full;
      case 'notify':
        return AdhanMode.notify;
      default:
        return AdhanMode.off;
    }
  }
}

class AdhanService {
  AdhanService._();

  /// Prayers that have a call. Sunrise is excluded on purpose — there is no
  /// adhan for sunrise, and firing one would be a plain error of fact.
  static const List<String> prayers = <String>[
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  static const Map<String, String> prayerLabels = <String, String>{
    'fajr': 'Fajr',
    'dhuhr': 'Dhuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
  };

  static const String _enabledKey = 'adhan_enabled';

  /// The native receiver, addressed by its full class name. home_widget sends
  /// an explicit broadcast to it, which a manifest receiver accepts regardless
  /// of the action carried.
  static const String _receiver = 'com.quran2u.app.AdhanReceiver';

  // ── Settings ──────────────────────────────────────────────────────────

  static Future<bool> isEnabled() async {
    try {
      return await HomeWidget.getWidgetData<bool>(_enabledKey, defaultValue: false) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setEnabled(bool value) async {
    await HomeWidget.saveWidgetData<bool>(_enabledKey, value);
    await sync();
  }

  static Future<AdhanMode> modeFor(String prayer) async {
    try {
      final raw = await HomeWidget.getWidgetData<String>(
        'adhan_mode_$prayer',
        defaultValue: 'off',
      );
      return AdhanModeX.parse(raw);
    } catch (_) {
      return AdhanMode.off;
    }
  }

  static Future<Map<String, AdhanMode>> allModes() async {
    final out = <String, AdhanMode>{};
    for (final p in prayers) {
      out[p] = await modeFor(p);
    }
    return out;
  }

  static Future<void> setMode(String prayer, AdhanMode mode) async {
    await HomeWidget.saveWidgetData<String>(
        'adhan_mode_$prayer', mode.storageValue);
    await sync();
  }

  /// Turns the feature on with every prayer playing the full adhan — the
  /// sensible shape of "yes, I want the adhan" without making someone tap five
  /// more times to get there.
  static Future<void> enableAll() async {
    for (final p in prayers) {
      await HomeWidget.saveWidgetData<String>(
          'adhan_mode_$p', AdhanMode.full.storageValue);
    }
    await HomeWidget.saveWidgetData<bool>(_enabledKey, true);
    await sync();
  }

  // ── Publishing ────────────────────────────────────────────────────────

  /// Refreshes the prayer schedule and tells the native scheduler to re-arm.
  ///
  /// Call after any settings change, on app resume, and after a location
  /// change. Cheap, idempotent, and it never throws — a failure here leaves
  /// the previously armed alarms in place rather than cancelling them.
  static Future<void> sync() async {
    try {
      // Republish `sched_v2` first: the native side arms alarms straight out
      // of it, so it has to be current before the poke arrives.
      await WidgetService.refreshWidget();
      await HomeWidget.updateWidget(qualifiedAndroidName: _receiver);
    } catch (e) {
      debugPrint('[Adhan] sync failed: $e');
    }
  }

  // ── Diagnostics for Settings ──────────────────────────────────────────

  /// The next prayer that will actually sound, as (label, time), or null when
  /// the feature is off or nothing is scheduled.
  ///
  /// Derived from the same schedule the alarms are armed from, so what
  /// Settings promises is what the device will do.
  static Future<MapEntry<String, DateTime>?> nextAudible() async {
    if (!await isEnabled()) return null;

    final modes = await allModes();
    if (modes.values.every((m) => m == AdhanMode.off)) return null;

    final now = DateTime.now();
    final schedule = await WidgetService.upcomingSchedule();

    for (final day in schedule) {
      for (final prayer in prayers) {
        if (modes[prayer] == AdhanMode.off) continue;
        final at = day[prayer];
        if (at != null && at.isAfter(now)) {
          return MapEntry(prayerLabels[prayer] ?? prayer, at);
        }
      }
    }
    return null;
  }
}
