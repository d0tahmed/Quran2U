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
      final now = tz.TZDateTime.now(tz.local);
      
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 6, 0); 
      
      // If it's already past 6 AM today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      await _notifications.zonedSchedule(
        0, 
        '🌅 Daily Ayah & Hadith',
        'Click here to see the ayah of the day',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_inspiration_channel',
            'Daily Inspiration',
            channelDescription: 'Reminders for daily Ayah and Hadith',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher', // RESTORED
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, 
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, 
        payload: 'daily_tab',
      );
      debugPrint('✅ 6:00 AM Daily Notification Successfully Scheduled!');
    } catch (e) {
      debugPrint('🔥 Scheduling Failed: $e');
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