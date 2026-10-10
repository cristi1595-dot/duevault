import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../providers/notification_provider.dart';
import '../../providers/vault_provider.dart';
import '../../services/analytics_service.dart';
import 'settings_divider.dart';

/// A self-contained widget representing the "SMART ALERTS" section in the settings.
///
/// It displays controls for global reminders, time picking, early alert configuration,
/// SOS urgent alerts, and background restrictions status checking/fixing.
class SmartAlertsSection extends ConsumerWidget {
  final Future<void> Function({required bool targetState}) onAttemptActivation;

  const SmartAlertsSection({
    super.key,
    required this.onAttemptActivation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalEnabled = ref.watch(globalNotificationsProvider);
    final alertDays = ref.watch(alertDaysProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.emerald400 : AppColors.emerald600;

    return Column(
      children: [
        // 1. Smart Reminder Service Toggle Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Reminder Service',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary(isDark),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Receive reminders for due bills',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary(isDark),
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
                        await HapticFeedback.lightImpact();
                        if (!context.mounted) return;
                        final initialTime = ref.read(notificationTimeProvider);
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: initialTime,
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                timePickerTheme: TimePickerThemeData(
                                  backgroundColor: AppColors.surface(isDark),
                                  hourMinuteTextColor: AppColors.textPrimary(isDark),
                                  dialBackgroundColor: AppColors.surfaceElevated(isDark),
                                  dialTextColor: AppColors.textPrimary(isDark),
                                  dayPeriodTextColor: AppColors.textPrimary(isDark),
                                ),
                                colorScheme: isDark
                                    ? ColorScheme.dark(
                                        primary: AppColors.emerald400,
                                        onPrimary: Colors.black,
                                        surface: AppColors.surface(isDark),
                                        onSurface: AppColors.slate50,
                                      )
                                    : ColorScheme.light(
                                        primary: accentColor,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: AppColors.slate900,
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
                      icon: Icon(Icons.access_time_rounded, size: 16, color: accentColor),
                      label: Consumer(
                        builder: (BuildContext context, WidgetRef ref, Widget? child) {
                          final time = ref.watch(notificationTimeProvider);
                          return Text(
                            time.format(context),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: accentColor.withValues(alpha: 0.12),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 24,
                    child: Switch(
                      value: globalEnabled,
                      onChanged: (bool v) async {
                        await HapticFeedback.lightImpact();
                        await onAttemptActivation(targetState: v);
                        await ref.read(vaultProvider.notifier).rescheduleAllNotifications();
                      },
                      activeThumbColor: accentColor,
                      activeTrackColor: accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (globalEnabled) ...[
          const SettingsDivider(),
          // 2. Early Alert Row
          Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              final firstReminderEnabled = ref.watch(threeDayAlertEnabledProvider);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Early Alert',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary(isDark),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                firstReminderEnabled
                                    ? 'Early warning • $alertDays ${alertDays == 1 ? "day" : "days"} before'
                                    : 'Early warning for upcoming bills',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: firstReminderEnabled ? accentColor : AppColors.textSecondary(isDark),
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
                            onChanged: (bool val) async {
                              await HapticFeedback.lightImpact();
                              await ref.read(threeDayAlertEnabledProvider.notifier).toggle(val);
                              await ref.read(vaultProvider.notifier).rescheduleAllNotifications();
                              await ref.read(analyticsServiceProvider).logSettingsChanged('early_alert_enabled', val);
                            },
                            activeThumbColor: accentColor,
                            activeTrackColor: accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (firstReminderEnabled)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.base, right: AppSpacing.base, bottom: 6),
                      child: SizedBox(
                        height: 28,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            valueIndicatorTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            valueIndicatorColor: accentColor,
                            activeTrackColor: accentColor,
                            inactiveTrackColor: accentColor.withValues(alpha: 0.15),
                            thumbColor: accentColor,
                          ),
                          child: Slider(
                            value: alertDays.toDouble().clamp(3, 14),
                            min: 3,
                            max: 14,
                            divisions: 11,
                            label: '$alertDays Days',
                            onChanged: (double val) {
                              ref.read(alertDaysProvider.notifier).setAlertDays(val.toInt());
                            },
                            onChangeEnd: (double val) async {
                              await HapticFeedback.lightImpact();
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
          const SettingsDivider(),
          // 3. SOS Urgent Alert Row
          Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              final finalEnabled = ref.watch(finalReminderEnabledProvider);
              final finalDays = ref.watch(finalReminderDaysProvider);
              final finalDaysText = finalDays == 0 ? 'Day of' : '$finalDays ${finalDays == 1 ? "day" : "days"} before';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SOS Urgent Alert',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary(isDark),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                finalEnabled
                                    ? 'Urgent alert • $finalDaysText'
                                    : 'Urgent alert right before due date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: finalEnabled ? accentColor : AppColors.textSecondary(isDark),
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
                            onChanged: (bool val) async {
                              await HapticFeedback.lightImpact();
                              await ref.read(finalReminderEnabledProvider.notifier).toggle(val);
                              await ref.read(vaultProvider.notifier).rescheduleAllNotifications();
                              await ref.read(analyticsServiceProvider).logSettingsChanged('sos_urgent_alert_enabled', val);
                            },
                            activeThumbColor: accentColor,
                            activeTrackColor: accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (finalEnabled)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.base, right: AppSpacing.base, bottom: 6),
                      child: SizedBox(
                        height: 28,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            valueIndicatorTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            valueIndicatorColor: accentColor,
                            activeTrackColor: accentColor,
                            inactiveTrackColor: accentColor.withValues(alpha: 0.15),
                            thumbColor: accentColor,
                          ),
                          child: Slider(
                            value: finalDays.toDouble().clamp(0, 2),
                            min: 0,
                            max: 2,
                            divisions: 2,
                            label: finalDays == 0 ? 'Day of' : '$finalDays Days',
                            onChanged: (double val) {
                              ref.read(finalReminderDaysProvider.notifier).setFinalReminderDays(val.toInt());
                            },
                            onChangeEnd: (double val) async {
                              await HapticFeedback.lightImpact();
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
      ],
    );
  }
}
