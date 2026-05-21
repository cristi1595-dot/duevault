import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import '../../theme/app_theme.dart';
import '../../providers/notification_provider.dart';
import '../../providers/vault_provider.dart';
import '../../services/analytics_service.dart';
import '../../widgets/global_components.dart';

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 2, top: 2),
          child: Text(
            'SMART ALERTS',
            style: AppTheme.labelCapsStyle(context).copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: BentoCard(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Smart Reminder Service',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
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
                                        primary: AppTheme.primaryAction,
                                        onPrimary: Colors.white,
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
                            icon: const Icon(Icons.access_time, size: 18),
                            label: Consumer(
                              builder: (context, ref, _) {
                                final time = ref.watch(notificationTimeProvider);
                                return Text(
                                  time.format(context),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                );
                              },
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryAction,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              minimumSize: const Size(0, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        Switch(
                          value: globalEnabled,
                          onChanged: (v) async {
                            await onAttemptActivation(targetState: v);
                            await ref.read(vaultProvider.notifier).rescheduleAllNotifications();
                          },
                          activeThumbColor: AppTheme.primaryAction,
                        ),
                      ],
                    ),
                  ],
                ),

                if (globalEnabled) ...[
                  // --- 1. First Reminder (Avertizare Timpurie) ---
                  Consumer(
                    builder: (context, ref, _) {
                      final firstReminderEnabled = ref.watch(threeDayAlertEnabledProvider);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Early Alert',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      firstReminderEnabled 
                                        ? 'Early warning • $alertDays ${alertDays == 1 ? "day" : "days"} before'
                                        : 'Early warning for upcoming bills',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: firstReminderEnabled ? AppTheme.primaryAction : Colors.grey,
                                        fontWeight: firstReminderEnabled ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 30,
                                child: Switch(
                                  value: firstReminderEnabled,
                                  onChanged: (val) async {
                                    await ref.read(threeDayAlertEnabledProvider.notifier).toggle(val);
                                    await ref.read(vaultProvider.notifier).rescheduleAllNotifications();
                                    await ref.read(analyticsServiceProvider).logSettingsChanged('early_alert_enabled', val);
                                  },
                                  activeThumbColor: AppTheme.primaryAction,
                                  activeTrackColor: AppTheme.primaryAction.withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                          if (firstReminderEnabled)
                            SizedBox(
                              height: 36,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                  valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                                  valueIndicatorColor: AppTheme.primaryAction,
                                ),
                                child: Slider(
                                  value: alertDays.toDouble().clamp(3, 14),
                                  min: 3,
                                  max: 14,
                                  divisions: 11,
                                  label: '$alertDays Days',
                                  activeColor: AppTheme.primaryAction,
                                  inactiveColor: AppTheme.primaryAction.withValues(alpha: 0.1),
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
                        ],
                      );
                    },
                  ),
                  
                  // --- 2. Final Reminder (Avertizare de Ultim Moment) ---
                  Consumer(
                    builder: (context, ref, _) {
                      final finalEnabled = ref.watch(finalReminderEnabledProvider);
                      final finalDays = ref.watch(finalReminderDaysProvider);
                      final finalDaysText = finalDays == 0 ? 'Day of' : '$finalDays ${finalDays == 1 ? "day" : "days"} before';
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'SOS Urgent Alert',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      finalEnabled 
                                        ? 'Urgent alert • $finalDaysText'
                                        : 'Urgent alert right before due date',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: finalEnabled ? AppTheme.urgentRed : Colors.grey,
                                        fontWeight: finalEnabled ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 30,
                                child: Switch(
                                  value: finalEnabled,
                                  onChanged: (val) async {
                                    await ref.read(finalReminderEnabledProvider.notifier).toggle(val);
                                    await ref.read(vaultProvider.notifier).rescheduleAllNotifications();
                                    await ref.read(analyticsServiceProvider).logSettingsChanged('sos_urgent_alert_enabled', val);
                                  },
                                  activeThumbColor: AppTheme.urgentRed,
                                  activeTrackColor: AppTheme.urgentRed.withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                          if (finalEnabled)
                            SizedBox(
                              height: 36,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                  valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                                  valueIndicatorColor: AppTheme.urgentRed,
                                ),
                                child: Slider(
                                  value: finalDays.toDouble().clamp(0, 2),
                                  min: 0,
                                  max: 2,
                                  divisions: 2,
                                  label: finalDays == 0 ? 'Day of' : '$finalDays Days',
                                  activeColor: AppTheme.urgentRed,
                                  inactiveColor: AppTheme.urgentRed.withValues(alpha: 0.1),
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
                        ],
                      );
                    },
                  ),
                ],
                const SizedBox(height: 12),
                GestureDetector(
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
                                fontSize: 16,
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
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
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
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              isOptimizedActive ? 'Active' : 'Fix Now',
                              style: TextStyle(
                                color: isOptimizedActive ? AppTheme.safeGreen : AppTheme.urgentRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
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
