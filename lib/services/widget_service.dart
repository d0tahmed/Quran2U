import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

/// Service that computes prayer times and pushes them to the native
/// Android home-screen widget via [HomeWidget] (SharedPreferences bridge).
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
      final fmt = DateFormat.jm(); // e.g. "5:23 AM"

      // ── 3. Determine next prayer ─────────────────────────────────────
      final nextPrayer = prayerTimes.nextPrayer();
      final highlight = nextPrayer == Prayer.none ? Prayer.fajr : nextPrayer;

      DateTime nextTime;
      String nextName;
      switch (highlight) {
        case Prayer.fajr:
          nextTime = prayerTimes.fajr;
          nextName = 'Fajr';
        case Prayer.sunrise:
          nextTime = prayerTimes.sunrise;
          nextName = 'Sunrise';
        case Prayer.dhuhr:
          nextTime = prayerTimes.dhuhr;
          nextName = 'Dhuhr';
        case Prayer.asr:
          nextTime = prayerTimes.asr;
          nextName = 'Asr';
        case Prayer.maghrib:
          nextTime = prayerTimes.maghrib;
          nextName = 'Maghrib';
        case Prayer.isha:
          nextTime = prayerTimes.isha;
          nextName = 'Isha';
        default:
          nextTime = prayerTimes.fajr;
          nextName = 'Fajr';
      }

      // If the next prayer is actually tomorrow's Fajr (all prayers passed)
      if (nextPrayer == Prayer.none) {
        final tomorrow = now.add(const Duration(days: 1));
        final tomorrowCoords = coords;
        final tomorrowTimes = PrayerTimes(
          tomorrowCoords,
          DateComponents(tomorrow.year, tomorrow.month, tomorrow.day),
          params,
        );
        nextTime = tomorrowTimes.fajr;
      }

      final remaining = nextTime.difference(now);
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes % 60;
      final remainingStr = hours > 0
          ? '${hours}h ${minutes}m remaining'
          : '${minutes}m remaining';

      // ── 4. Save to SharedPreferences ─────────────────────────────────
      await HomeWidget.saveWidgetData<String>('fajr_time', fmt.format(prayerTimes.fajr));
      await HomeWidget.saveWidgetData<String>('sunrise_time', fmt.format(prayerTimes.sunrise));
      await HomeWidget.saveWidgetData<String>('dhuhr_time', fmt.format(prayerTimes.dhuhr));
      await HomeWidget.saveWidgetData<String>('asr_time', fmt.format(prayerTimes.asr));
      await HomeWidget.saveWidgetData<String>('maghrib_time', fmt.format(prayerTimes.maghrib));
      await HomeWidget.saveWidgetData<String>('isha_time', fmt.format(prayerTimes.isha));

      await HomeWidget.saveWidgetData<String>('next_prayer_name', nextName);
      await HomeWidget.saveWidgetData<String>('next_prayer_time', fmt.format(nextTime));
      await HomeWidget.saveWidgetData<String>('next_prayer_remaining', remainingStr);

      // Which row index (0-5) to highlight: fajr=0, sunrise=1, ..., isha=5
      final highlightIndex = _prayerIndex(highlight);
      await HomeWidget.saveWidgetData<int>('highlight_index', highlightIndex);

      await HomeWidget.saveWidgetData<String>(
        'last_updated',
        DateFormat('hh:mm a').format(now),
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

  static int _prayerIndex(Prayer p) {
    switch (p) {
      case Prayer.fajr:    return 0;
      case Prayer.sunrise: return 1;
      case Prayer.dhuhr:   return 2;
      case Prayer.asr:     return 3;
      case Prayer.maghrib: return 4;
      case Prayer.isha:    return 5;
      default:             return 0;
    }
  }
}
