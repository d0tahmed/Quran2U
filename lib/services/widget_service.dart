import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:quran_recitation/services/hijri_date.dart';
import 'package:quran_recitation/services/time_format.dart';

/// Computes prayer times and pushes them to the native Android home-screen
/// widget via [HomeWidget] (a SharedPreferences bridge).
///
/// DIVISION OF LABOUR WITH THE NATIVE SIDE
/// ---------------------------------------
/// This service publishes *facts only*. It never decides which prayer is
/// "next" — PrayerTimesWidgetProvider recomputes that from the system clock on
/// every draw, so the highlight cannot get stuck when Android throttles our
/// background work.
///
/// WHY A MULTI-DAY SCHEDULE
/// ------------------------
/// The old version published a single day, and that is the bug where a widget
/// left alone for hours shows the wrong prayer. Two things were wrong with it:
/// the stored times belonged to the day the app was last opened, so after
/// midnight they were simply the wrong day's times; and there was nothing the
/// native side could do about it except wait to be launched.
///
/// It now publishes [scheduleDays] days at once as one compact string. The
/// widget selects the row matching the current date at draw time, so it stays
/// correct for a week with the app never opened — and the adhan scheduler
/// reads the same rows, which is what stops the call and the widget from ever
/// disagreeing with each other.
class WidgetService {
  WidgetService._();

  /// The Android widget provider class registered in AndroidManifest.xml.
  static const _androidWidgetName = 'PrayerTimesWidgetProvider';

  /// How many days of prayer times are published in one go.
  ///
  /// Seven days is about 250 bytes and covers any realistic gap between app
  /// launches. Past that the widget falls back to its single-day data and then
  /// to "Open app", which is the honest thing to show.
  static const int scheduleDays = 7;

  /// Key holding the multi-day schedule. Format:
  ///
  ///   `20260824:288,352,752,935,1122,1200;20260825:289,...`
  ///
  /// One row per day — `yyyyMMdd`, then the six prayer times as minutes since
  /// local midnight, in widget cell order. Minutes rather than formatted
  /// strings, because the native side has to do clock arithmetic on them and
  /// because a whole week this way is smaller than one formatted day.
  static const String scheduleKey = 'sched_v2';

  /// Cell order. MUST match prayer_times_widget.xml, the ROW_IDS array in
  /// PrayerTimesWidgetProvider.kt, and the order written into [scheduleKey].
  static const List<String> prayerKeys = <String>[
    'fajr',
    'sunrise',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  /// Refreshes prayer-time data and signals the native widget to redraw.
  ///
  /// Called from `main()`, from every app resume, and from the WorkManager
  /// periodic task. Cheap enough to call freely; never throws.
  static Future<void> refreshWidget() async {
    try {
      final coords = await _getCoordinates();
      final params = CalculationMethod.karachi.getParameters()
        ..madhab = Madhab.hanafi;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // ── 1. Multi-day schedule ────────────────────────────────────────
      final rows = <String>[];
      for (var offset = 0; offset < scheduleDays; offset++) {
        final day = today.add(Duration(days: offset));
        final times = _timesFor(coords, params, day);
        final minutes =
            prayerKeys.map((k) => TimeFormat.minutesSinceMidnight(times[k]!));
        rows.add('${DateFormat('yyyyMMdd').format(day)}:${minutes.join(',')}');
      }
      await HomeWidget.saveWidgetData<String>(scheduleKey, rows.join(';'));

      // ── 2. Today's values, still published individually ──────────────
      // The native side prefers the schedule; these keep a widget drawn by an
      // older APK rendering correctly until that APK is replaced.
      //   *_time -> "4:48 AM"   full string, for accessibility
      //   *_hm   -> "4:48"      numerals only — the widget's big line
      //   *_mer  -> "AM"        meridiem on its own line so nothing wraps
      //   *_min  -> 288         minutes since midnight, for clock math
      final todayTimes = _timesFor(coords, params, today);
      for (final key in prayerKeys) {
        final time = todayTimes[key]!;
        await HomeWidget.saveWidgetData<String>(
            '${key}_time', TimeFormat.clock(time));
        await HomeWidget.saveWidgetData<String>(
            '${key}_hm', TimeFormat.hourMinute(time));
        await HomeWidget.saveWidgetData<String>(
            '${key}_mer', TimeFormat.meridiem(time));
        await HomeWidget.saveWidgetData<int>(
            '${key}_min', TimeFormat.minutesSinceMidnight(time));
      }

      // ── 3. Dual calendar for the widget header ───────────────────────
      final hijri = HijriDate.fromDate(now);
      await HomeWidget.saveWidgetData<String>('hijri_date', hijri.short);
      await HomeWidget.saveWidgetData<String>(
          'greg_date', DateFormat('EEEE, d MMMM yyyy').format(now));
      await HomeWidget.saveWidgetData<String>(
          'data_date', DateFormat('yyyy-MM-dd').format(now));
      await HomeWidget.saveWidgetData<String>(
          'last_updated', TimeFormat.clock(now));

      // ── 4. Redraw ────────────────────────────────────────────────────
      await HomeWidget.updateWidget(androidName: _androidWidgetName);
    } catch (e) {
      // The widget keeps its last valid data rather than blanking.
      assert(() {
        // ignore: avoid_print
        print('[WidgetService] refreshWidget error: $e');
        return true;
      }());
    }
  }

  /// Prayer times for one specific calendar day.
  static Map<String, DateTime> _timesFor(
    Coordinates coords,
    CalculationParameters params,
    DateTime day,
  ) {
    final times = PrayerTimes(coords, DateComponents.from(day), params);
    return <String, DateTime>{
      'fajr': times.fajr,
      'sunrise': times.sunrise,
      'dhuhr': times.dhuhr,
      'asr': times.asr,
      'maghrib': times.maghrib,
      'isha': times.isha,
    };
  }

  /// The same schedule the widget reads, as Dart objects — so the adhan
  /// scheduler arms its alarms from exactly the data the widget displays.
  ///
  /// One entry per day, each mapping a prayer key to its local [DateTime].
  /// Sunrise is included because the widget shows it; a caller arming an adhan
  /// must skip it, since there is no call to prayer at sunrise.
  static Future<List<Map<String, DateTime>>> upcomingSchedule({
    int days = scheduleDays,
  }) async {
    final coords = await _getCoordinates();
    final params = CalculationMethod.karachi.getParameters()
      ..madhab = Madhab.hanafi;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return List<Map<String, DateTime>>.generate(
      days,
      (offset) => _timesFor(coords, params, today.add(Duration(days: offset))),
    );
  }

  /// The user's coordinates, falling back to Karachi when unavailable.
  static Future<Coordinates> _getCoordinates() async {
    final fallback = Coordinates(24.8607, 67.0011);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return fallback;

      LocationPermission perm = await Geolocator.checkPermission();
      // In background there is no way to show a permission dialog.
      if (perm == LocationPermission.denied) return fallback;
      if (perm == LocationPermission.deniedForever) return fallback;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      return Coordinates(pos.latitude, pos.longitude);
    } catch (_) {
      return fallback;
    }
  }
}
