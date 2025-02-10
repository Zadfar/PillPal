import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mm_project/screens/home_screen.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationLogic {
    static final _notifications = FlutterLocalNotificationsPlugin();
    static final onNotifications = BehaviorSubject<String?>();

    static Future _notificationsDetails() async{
        return NotificationDetails(
            android: AndroidNotificationDetails("Schedule Reminder","Don't forget to take your medication",
            importance: Importance.max, priority: Priority.max));
    }

    static Future init(BuildContext context, String uid) async{
        tz.initializeTimeZones();
        final android = AndroidInitializationSettings("time");
        final settings = InitializationSettings(android: android);
        await _notifications.initialize(settings,
            onDidReceiveNotificationResponse: (payload){
                Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => HomeScreen(),));
            onNotifications.add(payload as String?);
        });
    }

    static Future showNotifications({
        int id = 0,
        String? title,
        String? body,
        String? payload,
        required DateTime dateTime,
    }) async {
        if(dateTime.isBefore(DateTime.now())){
            dateTime = dateTime.add(Duration(days: 1));
        }

        _notifications.zonedSchedule(
            id,
            title,
            body,
            tz.TZDateTime.from(dateTime, tz.local),
            await _notificationsDetails(),
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
        );
    }
}