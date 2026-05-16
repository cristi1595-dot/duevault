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
    try {
      final dynamic zone = await FlutterTimezone.getLocalTimezone();
      String tzName = zone.toString();

      // Senior Fix: If it's a TimezoneInfo object string, extract just the ID
      // Example: "TimezoneInfo(Europe/London, ...)" -> "Europe/London"
      if (tzName.contains('TimezoneInfo(')) {
        final startIndex = tzName.indexOf('(') + 1;
        final endIndex = tzName.indexOf(',');
        if (startIndex > 0 && endIndex > startIndex) {
          tzName = tzName.substring(startIndex, endIndex).trim();
        }
      }

      // Final fallback if it still looks like an object description
      if (tzName.contains('Instance of')) {
        tzName = 'Etc/UTC';
      }

      try {
        tz.setLocalLocation(tz.getLocation(tzName));
        logger.i('NotificationService: Timezone initialized as $tzName');
      } catch (e) {
        logger.w('NotificationService: $tzName not found in DB, using Etc/UTC');
        tz.setLocalLocation(tz.getLocation('Etc/UTC'));
      }
    } catch (e, stack) {
      logger.e(
        'NotificationService: Timezone detection failed, using Etc/UTC fallback',
        error: e,
        stackTrace: stack,
      );
      try {
        tz.setLocalLocation(tz.getLocation('Etc/UTC'));
      } catch (_) {}
    }
  }

  static Future<bool> requestPermissions() async {
    // 1. Request Notification Permission (UI)
    // This works fine for POST_NOTIFICATIONS on Android 13+
    final status = await Permission.notification.request();

    // 2. Request Exact Alarm Permission (Required for Android 14+)
    // Senior Fix: Do NOT call .request() on scheduleExactAlarm as it's not a runtime permission
    // and causes "No requestable permission" error. Instead, we check and can guide to settings.
    if (status.isGranted) {
      final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
      if (exactAlarmStatus.isDenied || exactAlarmStatus.isPermanentlyDenied) {
        logger.i(
          'NotificationService: Exact Alarm permission is denied. User may need to enable it in settings.',
        );
        // We don't force open here to avoid jarring UX,
        // the "Fix Now" button in settings will handle the deep link.
      }
    }

    // 3. Fallback to plugin-specific request for compatibility
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      // requestExactAlarmsPermission() in the plugin handles the intent correctly
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
