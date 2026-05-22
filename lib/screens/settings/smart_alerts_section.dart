import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import '../../theme/app_theme.dart';
import '../../providers/notification_provider.dart';
import '../../providers/vault_provider.dart';
import '../../services/analytics_service.dart';

/// A self-contained widget representing the "SMART ALERTS" section in the settings.
///
/// It displays controls for global reminders, time picking, early alert configuration,
/// SOS urgent alerts, and background restrictions status checking/fixing.
class SmartAlertsSection extends ConsumerWidget {
  final bool? isBatteryOptimizationDisabled;
  final bool isNotificationPermissionGranted;
  final bool isExactAlarmGranted;
  final Future<void> Function({required bool targetState}) onAttemptActivation;

  const SmartAlertsSection({
    super.key,
    required this.isBatteryOptimizationDisabled,
    required this.isNotificationPermissionGranted,
    required this.isExactAlarmGranted,
    required this.onAttemptActivation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalEnabled = ref.watch(globalNotificationsProvider);
    final alertDays = ref.watch(alertDaysProvider);

    final isOptimizedActive = (isBatteryOptimizationDisabled == true &&
        isNotificationPermissionGranted &&
        isExactAlarmGranted);

    return Column(
      children: [
        // 1. Smart Reminder Service Toggle Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Reminder Service',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Receive reminders for due bills',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (globalEnabled)
                    TextButton.icon(
                      onPressed: () async {
                        final initialTime = ref.read(notificationTimeProvider);
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: initialTime,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                timePickerTheme: const TimePickerThemeData(
                                  backgroundColor: AppTheme.background,
                                  hourMinuteTextColor: Colors.white,
                                  dialBackgroundColor: AppTheme.surface,
                                  dialTextColor: Colors.white,
                                  dayPeriodTextColor: Colors.white,
                                ),
                                colorScheme: const ColorScheme.dark(
                                  primary: Colors.greenAccent,
                                  onPrimary: Colors.black,
                                  surface: AppTheme.background,
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (pickedTime != null) {
                          await ref.read(notificationTimeProvider.notifier).setTime(pickedTime);
                          await ref.read(vaultProvider.notifier).rescheduleAllNotifications();
                        }
                      },
                      icon: const Icon(Icons.access_time_rounded, size: 16, color: Colors.greenAccent),
                      label: Consumer(
                        builder: (context, ref, _) {
                          final time = ref.watch(notificationTimeProvider);
                          return Text(
                            time.format(context),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.greenAccent,
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.greenAccent.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 24,
                    child: Switch(
                      value: globalEnabled,
                      onChanged: (v) async {
                        await onAttemptActivation(targetState: v);
                        await ref.read(vaultProvider.notifier).rescheduleAllNotifications();
                      },
                      activeThumbColor: Colors.greenAccent,
                      activeTrackColor: Colors.greenAccent.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (globalEnabled) ...[
          Divider(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            height: 1,
            indent: 16,
          ),
          // 2. Early Alert Row
          Consumer(
            builder: (context, ref, _) {
              final firstReminderEnabled = ref.watch(threeDayAlertEnabledProvider);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                    'Early Alert',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                firstReminderEnabled
                                    ? 'Early warning • $alertDays ${alertDays == 1 ? "day" : "days"} before'
                                    : 'Early warning for upcoming bills',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: firstReminderEnabled ? Colors.greenAccent : Colors.grey,
                                  fontWeight: firstReminderEnabled ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 24,
                          child: Switch(
                            value: firstReminderEnabled,
                            onChanged: (val) async {
                              await ref.read(threeDayAlertEnabledProvider.notifier).toggle(val);
                              await ref.read(vaultProvider.notifier).rescheduleAllNotifications();
                              await ref.read(analyticsServiceProvider).logSettingsChanged('early_alert_enabled', val);
                            },
                            activeThumbColor: Colors.greenAccent,
                            activeTrackColor: Colors.greenAccent.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (firstReminderEnabled)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                      child: SizedBox(
                        height: 28,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            valueIndicatorTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            valueIndicatorColor: Colors.greenAccent,
                            activeTrackColor: Colors.greenAccent,
                            inactiveTrackColor: Colors.greenAccent.withValues(alpha: 0.1),
                            thumbColor: Colors.greenAccent,
                          ),
                          child: Slider(
                            value: alertDays.toDouble().clamp(3, 14),
                            min: 3,
                            max: 14,
                            divisions: 11,
                            label: '$alertDays Days',
                            onChanged: (val) {
                              ref.read(alertDaysProvider.notifier).setAlertDays(val.toInt());
                            },
                            onChangeEnd: (val) async {
                              await ref.read(vaultProvider.notifier).rescheduleAllNotifications();
                              await ref.read(analyticsServiceProvider).logSettingsChanged('early_alert_days', val.toInt());
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          Divider(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            height: 1,
            indent: 16,
          ),
          // 3. SOS Urgent Alert Row
          Consumer(
            builder: (context, ref, _) {
              final finalEnabled = ref.watch(finalReminderEnabledProvider);
              final finalDays = ref.watch(finalReminderDaysProvider);
              final finalDaysText = finalDays == 0 ? 'Day of' : '$finalDays ${finalDays == 1 ? "day" : "days"} before';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                    'SOS Urgent Alert',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                finalEnabled
                                    ? 'Urgent alert • $finalDaysText'
                                    : 'Urgent alert right before due date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: finalEnabled ? Colors.greenAccent : Colors.grey,
                                  fontWeight: finalEnabled ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 24,
                          child: Switch(
                            value: finalEnabled,
                            onChanged: (val) async {
                              await ref.read(finalReminderEnabledProvider.notifier).toggle(val);
                              await ref.read(vaultProvider.notifier).rescheduleAllNotifications();
                              await ref.read(analyticsServiceProvider).logSettingsChanged('sos_urgent_alert_enabled', val);
                            },
                            activeThumbColor: Colors.greenAccent,
                            activeTrackColor: Colors.greenAccent.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (finalEnabled)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                      child: SizedBox(
                        height: 28,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            valueIndicatorTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            valueIndicatorColor: Colors.greenAccent,
                            activeTrackColor: Colors.greenAccent,
                            inactiveTrackColor: Colors.greenAccent.withValues(alpha: 0.1),
                            thumbColor: Colors.greenAccent,
                          ),
                          child: Slider(
                            value: finalDays.toDouble().clamp(0, 2),
                            min: 0,
                            max: 2,
                            divisions: 2,
                            label: finalDays == 0 ? 'Day of' : '$finalDays Days',
                            onChanged: (val) {
                              ref.read(finalReminderDaysProvider.notifier).setFinalReminderDays(val.toInt());
                            },
                            onChangeEnd: (val) async {
                              await ref.read(vaultProvider.notifier).rescheduleAllNotifications();
                              await ref.read(analyticsServiceProvider).logSettingsChanged('sos_urgent_alert_days', val.toInt());
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],

        Divider(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          height: 1,
          indent: 16,
        ),
        // 4. Background Restrictions Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: GestureDetector(
            onTap: () async {
              final isAndroid = Platform.isAndroid;
              final hasNotification = await Permission.notification.isGranted;
              final hasBattery = !isAndroid ||
                  (await DisableBatteryOptimization.isAllBatteryOptimizationDisabled ?? false);
              final hasExactAlarm = !isAndroid || await Permission.scheduleExactAlarm.isGranted;

              if (hasNotification && hasBattery && hasExactAlarm) {
                return;
              }

              await onAttemptActivation(targetState: true);
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Background Restrictions',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Allow app to run in background for alerts.',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: isOptimizedActive
                        ? AppTheme.safeGreen.withValues(alpha: 0.1)
                        : AppTheme.urgentRed.withValues(alpha: 0.1),
                    border: Border.all(
                      color: isOptimizedActive
                          ? AppTheme.safeGreen
                          : AppTheme.urgentRed.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOptimizedActive) ...[
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.safeGreen,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        isOptimizedActive ? 'Active' : 'Fix Now',
                        style: TextStyle(
                          color: isOptimizedActive ? AppTheme.safeGreen : AppTheme.urgentRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
