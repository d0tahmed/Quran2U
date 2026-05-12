import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final onNotifications = StreamController<String?>.broadcast();

  static Future<void> init() async {
    // SENIOR FIX: Wrap the entire boot sequence in a try-catch.
    // If notifications fail, it will NOT brick the app anymore!
    try {
      tz.initializeTimeZones();
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
      
      // RESTORED: Must include @mipmap/ for default Flutter apps!
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

      debugPrint('✅ Notification Engine Initialized Safely');
    } catch (e) {
      debugPrint('🔥 Notification Engine Boot Failed: $e');
    }
  }

  static Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }
    }
  }

  static Future<void> scheduleDaily6AM() async {
    try {
      // Cancel any existing scheduled notification with id 0 first.
      // This ensures a clean reschedule and prevents Android from
      // replacing a recurring alarm with a one-shot one on app restart.
      await _notifications.cancel(0);

      final now = tz.TZDateTime.now(tz.local);
      
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 6, 0);
      
      // If it's already past 6 AM today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      await _notifications.zonedSchedule(
        0, // Notification ID
        '🌅 Daily Ayah & Hadith',
        'Tap to read today\'s Ayah of the Day',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_inspiration_channel',
            'Daily Inspiration',
            channelDescription: 'Reminders for daily Ayah and Hadith',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        // ✅ KEY FIX: Use exactAllowWhileIdle so Android fires at the
        // EXACT scheduled time, even when the device is in Doze mode.
        // 'inexact' allows Android to delay by hours to save battery.
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        // This makes it repeat daily at the same time automatically.
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_tab',
      );
      debugPrint('✅ Daily 6:00 AM notification scheduled for: $scheduledDate');
    } catch (e) {
      debugPrint('🔥 Daily Notification Scheduling Failed: $e');
    }
  }

  // ⚡ INSTANT FIRE TEST
  static Future<void> showInstantNotification() async {
    try {
      await _notifications.show(
        88,
        '⚡ INSTANT TEST',
        'Your notification engine is alive and working!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'instant_channel',
            'Instant Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher', // RESTORED
          ),
        ),
      );
      debugPrint('✅ Instant notification triggered!');
    } catch (e) {
      debugPrint('🔥 Instant Notification Failed: $e');
    }
  }
}