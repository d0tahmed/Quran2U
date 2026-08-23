// lib/services/notification_service.dart
//
// Daily Ayah & Hadith reminder.
//
// WHY THE OLD VERSION FIRED "VERY RARELY"
// ---------------------------------------
// It scheduled ONE alarm with `matchDateTimeComponents: DateTimeComponents.time`
// and `AndroidScheduleMode.exactAllowWhileIdle`, then trusted Android to keep
// repeating it forever. Three things break that on a real phone:
//
//  1. EXACT-ALARM PERMISSION. On Android 12+ an app needs SCHEDULE_EXACT_ALARM,
//     which the user grants on a Settings page most people never visit. Without
//     it `zonedSchedule` THROWS — and the old code caught the exception, logged
//     it, and returned. Every schedule silently failed and nothing ever fired.
//     Now: try exact, and on failure fall back to inexact. A reminder that
//     lands at 6:20 is infinitely better than one that never lands.
//
//  2. THE REPEAT CHAIN IS FRAGILE. `matchDateTimeComponents` does not create a
//     truly repeating OS alarm. The plugin fires once, and its broadcast
//     receiver arms the next one. Break the chain — force-stop, "clear all" in
//     recents, an aggressive OEM battery cleaner — and it never re-arms. This
//     phone is an Infinix; XOS is among the most aggressive there is.
//     Now: arm the next 14 days as INDEPENDENT one-shot alarms. Losing one no
//     longer loses the rest, and any single app launch re-fills the window.
//
//  3. IT ONLY RE-ARMED ON A COLD START, inside MainShell.initState. Now it also
//     re-arms on resume (see main.dart), so opening the app once a fortnight is
//     enough to stay covered indefinitely.
//
// The notification also now carries the actual ayah for that day, pulled from
// the same shared pool the Daily screen renders, instead of a generic
// "tap to read" line.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:quran_recitation/data/daily_inspiration_data.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final onNotifications = StreamController<String?>.broadcast();

  /// Hour of the day, local time, for the reminder.
  static const int reminderHour = 6;
  static const int reminderMinute = 0;

  /// How many days are armed ahead. Each day is its own alarm, so the user is
  /// covered for this long even if the app is never opened again.
  static const int _daysAhead = 14;

  /// Notification IDs 1000..1000+_daysAhead are reserved for the daily series.
  static const int _dailyIdBase = 1000;

  // Plain strings rather than a shared const AndroidNotificationDetails: the
  // body text differs per notification, so the details object has to be built
  // per call anyway, and this avoids depending on whether every field of that
  // class happens to be const-constructible in the current plugin version.
  static const String _channelId = 'daily_inspiration_channel';
  static const String _channelName = 'Daily Inspiration';
  static const String _channelDescription =
      'One ayah and one hadith, every morning';

  static bool _ready = false;

  /// True when the last scheduling pass had to fall back to inexact alarms
  /// because the OS withheld the exact-alarm permission. Settings can surface
  /// this so the user understands why the reminder drifts.
  static bool lastScheduleWasInexact = false;

  // ── Boot ──────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    try {
      tz.initializeTimeZones();
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null) {
            onNotifications.add(response.payload);
          }
        },
      );

      _ready = true;
      debugPrint('[Notify] initialised, tz=${tz.local.name}');
    } catch (e) {
      // A notification failure must never brick the app.
      debugPrint('[Notify] init failed: $e');
    }
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  // ── Permissions ───────────────────────────────────────────────────────────

  /// Asks for the POST_NOTIFICATIONS runtime permission (Android 13+).
  ///
  /// Deliberately does NOT ask for exact alarms here. That request throws the
  /// user out to a full-screen system settings page, which is a hostile thing
  /// to do during first launch — and the reminder works without it. Offer it
  /// from Settings instead, via [requestExactAlarmPermission].
  static Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return true;
    try {
      final granted = await _android?.requestNotificationsPermission();
      debugPrint('[Notify] POST_NOTIFICATIONS granted=$granted');
      return granted ?? false;
    } catch (e) {
      debugPrint('[Notify] permission request failed: $e');
      return false;
    }
  }

  /// Sends the user to the system page where exact alarms are granted.
  /// Call this from a Settings row, not on launch.
  static Future<void> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('[Notify] exact-alarm request failed: $e');
    }
  }

  static Future<bool> areNotificationsEnabled() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _android?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  // ── Scheduling ────────────────────────────────────────────────────────────

  /// Arms the daily reminder for the next [_daysAhead] days.
  ///
  /// Safe to call as often as you like — it cancels the whole series first, so
  /// repeated calls re-arm rather than pile up. Never throws.
  static Future<void> scheduleDailyReminders() async {
    if (!_ready) {
      debugPrint('[Notify] skipped: engine not initialised');
      return;
    }

    try {
      // Clear the whole reserved range, plus id 0 from the previous
      // implementation so upgrading users do not get a duplicate.
      await _notifications.cancel(0);
      for (var i = 0; i < _daysAhead; i++) {
        await _notifications.cancel(_dailyIdBase + i);
      }

      final now = tz.TZDateTime.now(tz.local);
      var armed = 0;
      var usedInexact = false;

      for (var offset = 0; offset <= _daysAhead; offset++) {
        final day = now.add(Duration(days: offset));
        final when = tz.TZDateTime(
            tz.local, day.year, day.month, day.day, reminderHour, reminderMinute);

        // Today's slot has usually already passed by the time the app opens.
        if (!when.isAfter(now)) continue;
        if (armed >= _daysAhead) break;

        final content = kDailyInspirations[dailyIndexFor(when)];
        final body = '${content.translationAyah}\n— ${content.referenceAyah}';

        final inexact = !await _scheduleOne(
          id: _dailyIdBase + armed,
          when: when,
          title: 'Ayah of the Day',
          body: body,
        );
        usedInexact = usedInexact || inexact;
        armed++;
      }

      lastScheduleWasInexact = usedInexact;
      debugPrint('[Notify] armed $armed day(s) from ${now.toLocal()}'
          '${usedInexact ? " (inexact — exact-alarm permission withheld)" : ""}');
    } catch (e) {
      debugPrint('[Notify] scheduling failed: $e');
    }
  }

  /// Schedules one alarm. Returns true if it went out as an EXACT alarm.
  ///
  /// The exact path needs a permission the user may never have granted, and
  /// when it is missing the plugin throws rather than degrading. So: attempt
  /// exact, and on any failure retry inexact, which needs no permission and
  /// still fires — Android just reserves the right to batch it into a window.
  static Future<bool> _scheduleOne({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(body),
      ),
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // Required by flutter_local_notifications 17.x. absoluteTime means
        // "fire at this wall-clock instant", which is what a 6 AM reminder is.
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'daily_tab',
      );
      return true;
    } catch (e) {
      debugPrint('[Notify] exact schedule for id=$id failed ($e) — '
          'retrying inexact');
    }

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'daily_tab',
      );
    } catch (e) {
      debugPrint('[Notify] inexact schedule for id=$id also failed: $e');
    }
    return false;
  }

  /// Kept for callers written against the old name.
  @Deprecated('Use scheduleDailyReminders()')
  static Future<void> scheduleDaily6AM() => scheduleDailyReminders();

  static Future<void> cancelDailyReminders() async {
    try {
      await _notifications.cancel(0);
      for (var i = 0; i < _daysAhead; i++) {
        await _notifications.cancel(_dailyIdBase + i);
      }
    } catch (e) {
      debugPrint('[Notify] cancel failed: $e');
    }
  }

  // ── Diagnostics ───────────────────────────────────────────────────────────

  /// How many reminders are currently armed. A Settings row showing "next
  /// reminder: tomorrow 06:00" turns an invisible failure into a visible one.
  static Future<List<PendingNotificationRequest>> pendingReminders() async {
    try {
      final all = await _notifications.pendingNotificationRequests();
      return all
          .where((r) => r.id >= _dailyIdBase && r.id < _dailyIdBase + _daysAhead)
          .toList(growable: false);
    } catch (e) {
      debugPrint('[Notify] pending lookup failed: $e');
      return const <PendingNotificationRequest>[];
    }
  }

  /// Fires immediately, with today's real content — so "test notification"
  /// proves the whole path, not just that the plugin is loaded.
  static Future<void> showInstantNotification() async {
    try {
      final content = todayInspiration;
      final body = '${content.translationAyah}\n— ${content.referenceAyah}';
      await _notifications.show(
        88,
        'Ayah of the Day',
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(body),
          ),
        ),
        payload: 'daily_tab',
      );
    } catch (e) {
      debugPrint('[Notify] instant notification failed: $e');
    }
  }
}
