import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/logger.dart';


class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {},
    );

    // 1. Initialize Timezone Database
    tz.initializeTimeZones();

    // 2. IMPORTANT: Set the local location based on the device's current timezone
    // This handles users traveling between countries
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      // If it's an object, get the name property. If it's already a string, use it.
      final String tzName = (zone is String) ? zone : (zone as dynamic).name;
      
      tz.setLocalLocation(tz.getLocation(tzName));
      logger.i('NotificationService: Timezone set to $tzName');
    } catch (e, stack) {
      logger.e(
        'NotificationService: Could not set local timezone, defaulting to UTC',
        error: e,
        stackTrace: stack,
      );
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  static Future<bool> requestPermissions() async {
    // 1. Request Notification Permission (UI)
    final status = await Permission.notification.request();

    // 2. Request Exact Alarm Permission (Required for Android 14+)
    if (status.isGranted) {
      // For Android 13+, exact alarms require special permission
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }

    // 3. Fallback to plugin-specific request
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }

    return status.isGranted;
  }

  static Future<void> scheduleVaultReminder({
    required int id,
    required String title,
    required DateTime dueDate,
    required int primaryDaysBefore,
    bool threeDayAlertEnabled = false,
    bool isDocument = false,
  }) async {
    final typeLabel = isDocument ? 'Document' : 'Bill';
    
    // 1. Primary Notification (from Slider)
    await _scheduleSingle(
      id: id, 
      title: '$typeLabel Due Soon: $title',
      body: 'This $typeLabel is due in $primaryDaysBefore days!',
      date: dueDate.subtract(Duration(days: primaryDaysBefore)),
    );

    // 2. Fixed 3-Day Alert (if enabled and different from primary)
    if (threeDayAlertEnabled && primaryDaysBefore != 3) {
      await _scheduleSingle(
        id: id + 10000, // Offset ID to avoid collision
        title: 'Early Reminder: $title',
        body: 'Upcoming $typeLabel due in 3 days.',
        date: dueDate.subtract(const Duration(days: 3)),
      );
    }

    // 3. MANDATORY Due-Day Alert (Day 0)
    await _scheduleSingle(
      id: id + 20000, // New Offset
      title: '$typeLabel Due Today: $title',
      body: 'Important: Your $typeLabel is due today!',
      date: dueDate,
    );
  }

  static Future<void> _scheduleSingle({
    required int id,
    required String title,
    required String body,
    required DateTime date,
  }) async {
    // Set reminder time to 09:00 AM
    final scheduleDate = DateTime(date.year, date.month, date.day, 9, 0);
    
    if (scheduleDate.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduleDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'bill_reminders',
          'Bill Reminders',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
    await _notificationsPlugin.cancel(id: id + 10000);
    await _notificationsPlugin.cancel(id: id + 20000);
  }
}
