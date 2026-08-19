import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:quran_recitation/services/hijri_date.dart';
import 'package:quran_recitation/services/time_format.dart';

/// Service that computes prayer times and pushes them to the native
/// Android home-screen widget via [HomeWidget] (SharedPreferences bridge).
///
/// IMPORTANT — division of labour with the native side:
/// this service publishes *facts* (each prayer's time, and its minutes since
/// midnight). It does NOT decide which prayer is "next" for the widget.
/// PrayerTimesWidgetProvider recomputes that from the system clock every time
/// it draws, so the widget can never get stuck on a stale prayer when Android
/// throttles our background work.
class WidgetService {
  WidgetService._();

  /// The Android widget provider class name registered in AndroidManifest.xml.
  static const _androidWidgetName = 'PrayerTimesWidgetProvider';

  /// Refreshes prayer-time data and signals the native widget to redraw.
  ///
  /// Called from:
  ///  1. `main()` on app startup
  ///  2. WorkManager periodic task every ~15 min
  static Future<void> refreshWidget() async {
    try {
      // ── 1. Get location ──────────────────────────────────────────────
      final coords = await _getCoordinates();

      // ── 2. Compute prayer times ──────────────────────────────────────
      final params = CalculationMethod.karachi.getParameters()
        ..madhab = Madhab.hanafi;
      final prayerTimes = PrayerTimes.today(coords, params);

      final now = DateTime.now();

      // Order MUST match the cell order in prayer_times_widget.xml and the
      // ROW_IDS array in PrayerTimesWidgetProvider.kt.
      final schedule = <String, DateTime>{
        'fajr': prayerTimes.fajr,
        'sunrise': prayerTimes.sunrise,
        'dhuhr': prayerTimes.dhuhr,
        'asr': prayerTimes.asr,
        'maghrib': prayerTimes.maghrib,
        'isha': prayerTimes.isha,
      };

      // ── 3. Publish each prayer three ways ────────────────────────────
      //   *_time -> "4:48 AM"  (full, for accessibility / legacy readers)
      //   *_hm   -> "4:48"     (numerals only — the widget's big line)
      //   *_mer  -> "AM"       (meridiem on its own line, so nothing wraps)
      //   *_min  -> 288        (minutes since midnight — the native clock math)
      for (final entry in schedule.entries) {
        final key = entry.key;
        final time = entry.value;
        await HomeWidget.saveWidgetData<String>(
            '${key}_time', TimeFormat.clock(time));
        await HomeWidget.saveWidgetData<String>(
            '${key}_hm', TimeFormat.hourMinute(time));
        await HomeWidget.saveWidgetData<String>(
            '${key}_mer', TimeFormat.meridiem(time));
        await HomeWidget.saveWidgetData<int>(
            '${key}_min', TimeFormat.minutesSinceMidnight(time));
      }

      // ── 4. Dual calendar for the widget header ───────────────────────
      final hijri = HijriDate.fromDate(now);
      await HomeWidget.saveWidgetData<String>('hijri_date', hijri.short);
      await HomeWidget.saveWidgetData<String>(
          'greg_date', DateFormat('EEEE, d MMMM yyyy').format(now));

      // Stamp the day these times belong to. The native side uses it only to
      // know whether the data is from today; the highlight itself is always
      // derived from the live clock.
      await HomeWidget.saveWidgetData<String>(
          'data_date', DateFormat('yyyy-MM-dd').format(now));

      await HomeWidget.saveWidgetData<String>(
        'last_updated',
        TimeFormat.clock(now),
      );

      // ── 5. Tell Android to redraw the widget ─────────────────────────
      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
      );
    } catch (e) {
      // Silently fail — the widget keeps showing the last valid data.
      // In debug builds, print for diagnostics.
      assert(() {
        // ignore: avoid_print
        print('[WidgetService] refreshWidget error: $e');
        return true;
      }());
    }
  }

  /// Returns the user's coordinates, falling back to Karachi if unavailable.
  static Future<Coordinates> _getCoordinates() async {
    final fallback = Coordinates(24.8607, 67.0011);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return fallback;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        // In background mode we can't show a permission dialog,
        // so just use the fallback.
        return fallback;
      }
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
