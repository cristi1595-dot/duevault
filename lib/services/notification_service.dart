import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/logger.dart';
import '../utils/amount_formatter.dart';

class NotificationService {
  static const int _firstReminderOffset = 100000;
  static const int _finalReminderOffset = 200000;

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

  static Future<void> requestExactAlarmPermission() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  static Future<void> scheduleDualAlerts({
    required int billId,
    required String billTitle,
    required DateTime dueDate,
    required int firstReminderDays,
    required int finalReminderDays,
    required bool isFirstReminderEnabled,
    required bool isFinalReminderEnabled,
    required int notificationHour,
    required int notificationMinute,
    required String itemType,
    double? amount,
  }) async {
    // Convert Isar's retrieved UTC dueDate to local device timezone before extracting components
    final localDueDate = dueDate.toLocal();

    // 1. Curățăm notificările vechi în caz că factura a fost editată
    await cancelBillNotifications(billId);

    // 2. Programăm Avertizarea Timpurie (First Reminder)
    if (isFirstReminderEnabled) {
      final firstReminderDate = localDueDate.subtract(
        Duration(days: firstReminderDays),
      );
      final scheduledDate = DateTime(
        firstReminderDate.year,
        firstReminderDate.month,
        firstReminderDate.day,
        notificationHour,
        notificationMinute,
      );

      final now = DateTime.now();
      if (scheduledDate.isAfter(now)) {
        final amountText = amount != null ? ' (${amount.formatAmount()})' : '';
        await _scheduleSingle(
          id: billId + _firstReminderOffset,
          title: 'Upcoming $itemType: $billTitle$amountText',
          body: 'Your $itemType is due in $firstReminderDays days.',
          date: scheduledDate,
        );
        logger.i(
          'Scheduled First Reminder pt ID: ${billId + _firstReminderOffset}',
        );
      }
    }

    // 3. Programăm Avertizarea Finală (Final Reminder)
    if (isFinalReminderEnabled) {
      final finalReminderDate = localDueDate.subtract(
        Duration(days: finalReminderDays),
      );
      final scheduledDate = DateTime(
        finalReminderDate.year,
        finalReminderDate.month,
        finalReminderDate.day,
        notificationHour,
        notificationMinute,
      );

      final now = DateTime.now();
      if (scheduledDate.isAfter(now)) {
        final amountText = amount != null ? ' (${amount.formatAmount()})' : '';
        await _scheduleSingle(
          id: billId + _finalReminderOffset,
          title: 'URGENT: $itemType Due!$amountText',
          body: finalReminderDays == 0
              ? 'Your $itemType "$billTitle" is due TODAY!'
              : 'Your $itemType "$billTitle" is due in $finalReminderDays day(s)!',
          date: scheduledDate,
        );
        logger.i(
          'Scheduled Final Reminder pt ID: ${billId + _finalReminderOffset}',
        );
      }
    }
  }

  static Future<void> _scheduleSingle({
    required int id,
    required String title,
    required String body,
    required DateTime date,
  }) async {
    // We already calculated the exact hour and minute, so we just use 'date'.
    final scheduleDate = date;

    final scheduledTZ = tz.TZDateTime.from(scheduleDate, tz.local);
    final nowTZ = tz.TZDateTime.now(tz.local);

    if (scheduledTZ.isBefore(nowTZ)) return;

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledTZ,
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
      logger.i('Successfully scheduled notification ID $id for $scheduledTZ');
    } catch (e, stack) {
      logger.e(
        'Failed to schedule notification ID $id',
        error: e,
        stackTrace: stack,
      );
    }
  }

  static Future<void> cancelBillNotifications(int billId) async {
    await _notificationsPlugin.cancel(id: billId + _firstReminderOffset);
    await _notificationsPlugin.cancel(id: billId + _finalReminderOffset);
    logger.i('Cancelled all reminders for bill ID: $billId');
  }
}
