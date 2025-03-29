import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationLogic {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static final onNotifications = BehaviorSubject<String?>();

  static Future<void> init({Function(String?)? onNotificationTap}) async {
    try {
      tz.initializeTimeZones();
      const androidSettings = AndroidInitializationSettings('app_icon');
      final settings = InitializationSettings(android: androidSettings);

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          onNotifications.add(payload);
          if (onNotificationTap != null && payload != null) {
            onNotificationTap(payload);
          }
        },
      );

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notification initialization failed: $e');
      rethrow;
    }
  }

  static Future<NotificationDetails> _notificationDetails() async {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_channel',
        'Medication Reminders',
        channelDescription: 'Reminders for taking your medication',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
    );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    required DateTime dateTime,
  }) async {
    try {
      final scheduledTime = dateTime.isBefore(DateTime.now())
          ? dateTime.add(const Duration(days: 1))
          : dateTime;

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        await _notificationDetails(),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  // Schedule recurring notifications
  static Future<void> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    required DateTime startTime,
    required String frequency, // 'Daily' or 'Weekly'
    required int intervalHours,
  }) async {
    try {
      final scheduledTime = startTime.isBefore(DateTime.now())
          ? startTime.add(const Duration(days: 1))
          : startTime;

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        await _notificationDetails(),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: frequency == 'Daily'
            ? DateTimeComponents.time
            : DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint('Failed to schedule recurring notification: $e');
    }
  }

  // Cancel a notification by ID
  static Future<void> cancelSpecificNotifications(List<int> notificationIds) async {
    try {
      for (int id in notificationIds) {
        await _notifications.cancel(id);
      }
    } catch (e) {
      debugPrint('Failed to cancel specific notifications: $e');
    }
  }
}