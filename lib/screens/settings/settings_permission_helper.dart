import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';
import 'settings_dialogs.dart';

class SettingsPermissionHelper {
  /// Checks status of required permissions.
  static Future<Map<String, bool>> checkStatus() async {
    final isAndroid = Platform.isAndroid;
    final bool notificationsGranted = await Permission.notification.isGranted;
    final bool exactAlarmGranted = !isAndroid || await Permission.scheduleExactAlarm.isGranted;

    return {
      'notificationsGranted': notificationsGranted,
      'exactAlarmGranted': exactAlarmGranted,
    };
  }

  /// Automatically enables global notifications if all required permissions are met.
  static Future<void> checkStatusAndAutoEnable(WidgetRef ref) async {
    final status = await checkStatus();
    final hasNotification = status['notificationsGranted']!;
    final hasExactAlarm = status['exactAlarmGranted']!;

    if (hasNotification && hasExactAlarm) {
      final globalEnabled = ref.read(globalNotificationsProvider);
      if (!globalEnabled) {
        await ref.read(globalNotificationsProvider.notifier).toggle(true);
      }
    }
  }

  /// Attempts to activate notifications step-by-step by requesting missing permissions.
  static Future<void> attemptActivation({
    required bool targetState,
    required WidgetRef ref,
    required BuildContext context,
    required Function(Map<String, bool> status) onStatusUpdated,
  }) async {
    if (!targetState) {
      await ref.read(globalNotificationsProvider.notifier).toggle(false);
      final status = await checkStatus();
      onStatusUpdated(status);
      return;
    }

    final isAndroid = Platform.isAndroid;

    bool hasNotification = await Permission.notification.isGranted;
    bool hasExactAlarm = !isAndroid || await Permission.scheduleExactAlarm.isGranted;

    // 1. If notifications and exact alarm are already granted, just enable and return
    if (hasNotification && hasExactAlarm) {
      await ref.read(globalNotificationsProvider.notifier).toggle(true);
      final status = await checkStatus();
      onStatusUpdated(status);
      return;
    }

    // 2. Otherwise, direct the user to the missing settings one by one
    // Step A: Notifications
    if (!hasNotification) {
      final requestStatus = await Permission.notification.request();
      if (requestStatus.isPermanentlyDenied && context.mounted) {
        await SettingsDialogs.showAppSettingsDialog(context);
      }
      hasNotification = await Permission.notification.isGranted;
    }

    // Step B: Exact Alarm permission (Android only)
    if (hasNotification && isAndroid && !hasExactAlarm) {
      await NotificationService.requestExactAlarmPermission();
      await Future.delayed(const Duration(seconds: 1));
      hasExactAlarm = await Permission.scheduleExactAlarm.isGranted;
    }

    // 3. Final Recheck after returning
    final status = await checkStatus();
    onStatusUpdated(status);

    final finalNotification = status['notificationsGranted']!;
    final finalExact = status['exactAlarmGranted']!;

    if (finalNotification && finalExact) {
      await ref.read(globalNotificationsProvider.notifier).toggle(true);
      final finalStatus = await checkStatus();
      onStatusUpdated(finalStatus);
    }
  }
}
