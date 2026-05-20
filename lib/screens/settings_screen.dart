import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:intl/intl.dart';
import '../models/app_config.dart';
import '../theme/app_theme.dart';
import '../widgets/global_components.dart';
import '../providers/currency_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/drive_service.dart';
import '../providers/vault_provider.dart';
import '../services/auto_sync_service.dart';
import '../providers/security_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/notification_provider.dart';
import '../services/notification_service.dart';
import '../providers/database_provider.dart';
import '../main.dart';
import '../utils/logger.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../services/analytics_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  bool? _isBatteryOptimizationDisabled;
  bool _isNotificationPermissionGranted = true;
  bool _isExactAlarmGranted = true;
  int _devModeTaps = 0;
  bool _isDevModeEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatusAndAutoEnable();
    }
  }

  Future<void> _checkStatusAndAutoEnable() async {
    await _checkStatus();
    if (!mounted) return;
    
    // Auto-enable notifications toggle if both permissions are now granted
    final isAndroid = Platform.isAndroid;
    final hasNotification = await Permission.notification.isGranted;
    final hasBattery = !isAndroid ||
        (await DisableBatteryOptimization.isAllBatteryOptimizationDisabled ?? false);
    final hasExactAlarm = !isAndroid || await Permission.scheduleExactAlarm.isGranted;
        
    if (hasNotification && hasBattery && hasExactAlarm) {
      final globalEnabled = ref.read(globalNotificationsProvider);
      if (!globalEnabled) {
        await ref.read(globalNotificationsProvider.notifier).toggle(true);
        await _checkStatus();
      }
    }
  }

  Future<void> _checkStatus() async {
    final isAndroid = Platform.isAndroid;
    final bool? batteryDisabled =
        await DisableBatteryOptimization.isAllBatteryOptimizationDisabled;
    final bool notificationsGranted = await Permission.notification.isGranted;
    final bool exactAlarmGranted = !isAndroid || await Permission.scheduleExactAlarm.isGranted;

    if (mounted) {
      setState(() {
        _isBatteryOptimizationDisabled = batteryDisabled;
        _isNotificationPermissionGranted = notificationsGranted;
        _isExactAlarmGranted = exactAlarmGranted;
      });
    }
  }

  Future<void> _showAppSettingsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Notifications Disabled'),
        content: const Text(
          'To enable global reminders, please allow notifications for DueVault in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final isAndroid = Theme.of(context).platform == TargetPlatform.android;
              Navigator.pop(ctx);
              await AppSettings.openAppSettings(type: AppSettingsType.notification);
              
              if (isAndroid) {
                final isBatteryOptimizationDisabled = 
                    await DisableBatteryOptimization.isAllBatteryOptimizationDisabled ?? false;
                if (!isBatteryOptimizationDisabled) {
                  await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAction,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _attemptActivation({required bool targetState}) async {
    if (!targetState) {
      await ref.read(globalNotificationsProvider.notifier).toggle(false);
      await _checkStatus();
      return;
    }

    final isAndroid = Platform.isAndroid;

    bool hasNotification = await Permission.notification.isGranted;
    bool hasBattery = !isAndroid ||
        (await DisableBatteryOptimization.isAllBatteryOptimizationDisabled ?? false);
    bool hasExactAlarm = !isAndroid || await Permission.scheduleExactAlarm.isGranted;

    // 1. If ALL are already granted, just enable and return
    if (hasNotification && hasBattery && hasExactAlarm) {
      await ref.read(globalNotificationsProvider.notifier).toggle(true);
      await _checkStatus();
      return;
    }

    // 2. Otherwise, direct the user to the missing settings one by one
    // Step A: Notifications
    if (!hasNotification) {
      final requestStatus = await Permission.notification.request();
      if (requestStatus.isPermanentlyDenied && mounted) {
        await _showAppSettingsDialog(context);
      }
      hasNotification = await Permission.notification.isGranted;
    }

    // Step B: Battery optimization (Android only)
    if (hasNotification && isAndroid && !hasBattery) {
      await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
      await Future.delayed(const Duration(seconds: 1));
      hasBattery = await DisableBatteryOptimization.isAllBatteryOptimizationDisabled ?? false;
    }

    // Step C: Exact Alarm permission (Android only)
    if (hasNotification && hasBattery && isAndroid && !hasExactAlarm) {
      await NotificationService.requestExactAlarmPermission();
      await Future.delayed(const Duration(seconds: 1));
      hasExactAlarm = await Permission.scheduleExactAlarm.isGranted;
    }

    // 3. Final Recheck after returning
    await _checkStatus();

    final finalNotification = await Permission.notification.isGranted;
    final finalBattery = !isAndroid ||
        (await DisableBatteryOptimization.isAllBatteryOptimizationDisabled ?? false);
    final finalExact = !isAndroid || await Permission.scheduleExactAlarm.isGranted;

    if (finalNotification && finalBattery && finalExact) {
      await ref.read(globalNotificationsProvider.notifier).toggle(true);
      await _checkStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCurrency = ref.watch(currencyProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Header
            _buildCompactProfile(context, ref),
            const SizedBox(height: 6),

            // 1.1 Sign In Option (Only for Guests) - Directly under Guest User
            Consumer(
              builder: (context, ref, child) {
                final authState = ref.watch(authStateProvider);
                final user = authState.valueOrNull;
                if (user == null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _buildGoogleSignInButton(context, ref),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // 1.5 Biometric Lock (Security)
            _buildSecuritySettings(context, ref),
            const SizedBox(height: 4),

            // 2. Sync Options (Only for Authenticated Users)
            Consumer(
              builder: (context, ref, child) {
                final authState = ref.watch(authStateProvider);
                final user = authState.valueOrNull;
                if (user != null) {
                  return BentoCard(
                    padding: EdgeInsets.zero,
                    child: _buildDriveSyncButtons(context, ref),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 4),

            // 3. Preferences Section
            _buildSectionHeader('INTERFACE CUSTOMIZATION'),
            const SizedBox(height: 2),
            BentoCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildCurrencyItem(context, ref, currentCurrency),
                  _buildSettingItem(
                    icon: themeMode == ThemeMode.dark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    title: 'Light & Dark Mode',
                    trailing: SizedBox(
                      height: 24,
                      child: Switch(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (v) {
                          ref.read(themeProvider.notifier).toggleTheme();
                          ref.read(analyticsServiceProvider).logSettingsChanged('theme_mode', themeMode == ThemeMode.dark ? 'light' : 'dark');
                        },
                        activeThumbColor: AppTheme.primaryAction,
                        activeTrackColor: AppTheme.primaryAction.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // 4. Alerts & Notifications Section
            _buildSectionHeader('SMART ALERTS'),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: BentoCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Consumer(
                  builder: (context, ref, child) {
                    final globalEnabled = ref.watch(
                      globalNotificationsProvider,
                    );
                    final alertDays = ref.watch(alertDaysProvider);

                    return Column(
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
                                        // Pad minute with 0 to prevent 9:0 becoming 9:00 etc (Wait, TimeOfDay.format(context) handles this!)
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
                                    await _attemptActivation(targetState: v);
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
                            
                            await _attemptActivation(targetState: true);
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
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
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
                                  color:
                                      (_isBatteryOptimizationDisabled == true &&
                                          _isNotificationPermissionGranted &&
                                          _isExactAlarmGranted)
                                      ? AppTheme.safeGreen.withValues(
                                          alpha: 0.1,
                                        )
                                      : AppTheme.urgentRed.withValues(
                                          alpha: 0.1,
                                        ),
                                  border: Border.all(
                                    color:
                                        (_isBatteryOptimizationDisabled ==
                                                true &&
                                            _isNotificationPermissionGranted &&
                                            _isExactAlarmGranted)
                                        ? AppTheme.safeGreen
                                        : AppTheme.urgentRed.withValues(
                                            alpha: 0.5,
                                          ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isBatteryOptimizationDisabled ==
                                            true &&
                                        _isNotificationPermissionGranted &&
                                        _isExactAlarmGranted)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppTheme.safeGreen,
                                        size: 16,
                                      ),
                                    if (_isBatteryOptimizationDisabled ==
                                            true &&
                                        _isNotificationPermissionGranted &&
                                        _isExactAlarmGranted)
                                      const SizedBox(width: 4),
                                    Text(
                                      (_isBatteryOptimizationDisabled == true &&
                                              _isNotificationPermissionGranted &&
                                              _isExactAlarmGranted)
                                          ? 'Active'
                                          : 'Fix Now',
                                      style: TextStyle(
                                        color:
                                            (_isBatteryOptimizationDisabled ==
                                                    true &&
                                                _isNotificationPermissionGranted &&
                                                _isExactAlarmGranted)
                                            ? AppTheme.safeGreen
                                            : AppTheme.urgentRed,
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
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 4),

            _buildDataManagement(context, ref),
            if (_isDevModeEnabled) ...[
              const SizedBox(height: 4),
              _buildBetaMonitoring(context, ref),
            ],
            const SizedBox(height: 16),
            _buildVersionFooter(context),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          ref.read(isProcessingAuthSyncProvider.notifier).state = true;
          final result = await ref.read(authServiceProvider).signInWithGoogle();
          if (result != null) {
            final uid = result.user!.uid;

            // Reset guest mode since user is now authenticated
            ref.read(isGuestProvider.notifier).state = false;
            final isar = ref.read(isarProvider);
            await isar.writeTxn(() async {
              final config = await isar.appConfigs.get(0) ?? AppConfig();
              config.isGuest = false;
              await isar.appConfigs.put(config);
            });

            // 1. Intelligent Migration Check
            final hasGuestData = await ref
                .read(vaultRepositoryProvider)
                .hasRealGuestData();

            if (hasGuestData && context.mounted) {
              final shouldMigrate = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Theme.of(context).cardTheme.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Migrate Local Data?'),
                  content: const Text(
                    'We found bills/documents saved in Guest mode. Would you like to move them to your Google account? If you choose \'No\', they will be permanently deleted.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('No, delete'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAction,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Yes, Migrate'),
                    ),
                  ],
                ),
              );

              if (shouldMigrate == true) {
                await ref.read(vaultProvider.notifier).migrateGuestData(uid);
                if (context.mounted) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('✓ Migration complete!')),
                  );
                }
              } else {
                await ref.read(vaultProvider.notifier).deleteGuestData();
                if (context.mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('✓ Local guest data deleted.'),
                    ),
                  );
                }
              }
            }

            messenger.showSnackBar(
              const SnackBar(
                content: Text('Account secured. Syncing your vault...'),
              ),
            );

            // Intelligent sync
            final syncResult = await ref
                .read(autoSyncServiceProvider)
                .syncAfterLogin();
            if (context.mounted) {
              messenger.clearSnackBars();
              String message;
              Color? bgColor;

              if (syncResult == 'restored') {
                message = '✓ Your vault data has been restored!';
                bgColor = AppTheme.safeGreen;
              } else if (syncResult == 'uploaded') {
                message = '✓ Local data synced with your account!';
                bgColor = AppTheme.primaryAction;
              } else {
                message = 'No backup found. Starting fresh.';
                bgColor = null;
              }

              messenger.showSnackBar(
                SnackBar(content: Text(message), backgroundColor: bgColor),
              );
            }
            if (context.mounted) {
              unawaited(
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigation()),
                  (route) => false,
                ),
              );
            }
          } else {
            messenger.showSnackBar(
              const SnackBar(content: Text('Sign in canceled.')),
            );
          }
        } catch (e) {
          logger.e('Sign in error', error: e);
          messenger.showSnackBar(
            SnackBar(
              content: Text('Sign in error: ${e.toString().split('\n').first}'),
              backgroundColor: AppTheme.urgentRed,
            ),
          );
        } finally {
          ref.read(isProcessingAuthSyncProvider.notifier).state = false;
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
              height: 18,
              errorBuilder: (ctx, err, st) => const Icon(
                Icons.account_circle_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sign in with Google',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriveSyncButtons(BuildContext context, WidgetRef ref) {
    final autoSync = ref.watch(autoSyncProvider);
    final wifiOnly = ref.watch(wifiOnlyProvider);
    final userEmail =
        FirebaseAuth.instance.currentUser?.email ?? 'your account';

    final syncTimestamp = ref.watch(lastSyncTimestampProvider);
    final syncState = ref.watch(syncProvider);

    String lastSyncText = 'Never';
    if (syncTimestamp.valueOrNull != null) {
      lastSyncText = DateFormat(
        'MMM dd, HH:mm',
      ).format(syncTimestamp.valueOrNull!.toLocal());
    }

    return Column(
      children: [
        // --- 1. Auto Sync Toggle ---
        _buildSettingItem(
          icon: Icons.sync,
          title: 'Automated Vault Backup',
          subtitle: autoSync
              ? 'Last sync: $lastSyncText'
              : 'Backup after changes',
          trailing: SizedBox(
            height: 24,
            child: (syncState.status == SyncStatus.syncing)
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch(
                    value: autoSync,
                    onChanged: (v) =>
                        ref.read(autoSyncProvider.notifier).toggleAutoSync(v),
                    activeThumbColor: AppTheme.primaryAction,
                    activeTrackColor: AppTheme.primaryAction.withValues(
                      alpha: 0.3,
                    ),
                  ),
          ),
        ),

        // --- 2. WiFi Only (Conditional) ---
        if (autoSync)
          _buildSettingItem(
            icon: Icons.wifi_outlined,
            title: 'Optimize Mobile Data',
            subtitle: 'Save mobile data',
            trailing: SizedBox(
              height: 24,
              child: Switch(
                value: wifiOnly,
                onChanged: (v) =>
                    ref.read(wifiOnlyProvider.notifier).toggleWifiOnly(v),
                activeThumbColor: AppTheme.primaryAction,
                activeTrackColor: AppTheme.primaryAction.withValues(alpha: 0.3),
              ),
            ),
          ),

        // --- 4. Manual Backup Trigger (if auto is off or forced) ---
        if (!autoSync)
          _buildSettingItem(
            icon: Icons.cloud_upload_outlined,
            title: 'Backup Now',
            subtitle: 'Manual push to cloud',
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Theme.of(context).cardTheme.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        color: AppTheme.primaryAction,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Backup Now',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This will upload a copy of your vault to:',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.folder_outlined,
                              color: AppTheme.primaryAction,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Google Drive › App Data',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    userEmail,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                      fontSize: 11,
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
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.cloud_upload, size: 16),
                      label: const Text('Backup Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAction,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              if (!context.mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('Backing up to Google Drive...')),
              );

              final authService = ref.read(authServiceProvider);
              final token = await authService.getFreshAccessToken();

              if (token != null) {
                final authHeaders = {'Authorization': 'Bearer $token'};
                final driveService = DriveService(
                  GoogleAuthClient(authHeaders),
                );
                try {
                  final success = await driveService.backupDatabase();

                  // Update local config timestamp manually for manual backup
                  if (success) {
                    final isar = ref.read(isarProvider);
                    await isar.writeTxn(() async {
                      final config =
                          await isar.collection<AppConfig>().get(0) ??
                          AppConfig();
                      config.lastCloudSync = DateTime.now();
                      await isar.collection<AppConfig>().put(config);
                    });
                  }

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? '✓ Backup saved to Google Drive!'
                            : 'Backup failed. Please try again.',
                      ),
                      backgroundColor: success
                          ? AppTheme.safeGreen
                          : AppTheme.urgentRed,
                    ),
                  );
                } finally {
                  driveService.dispose();
                }
              }
            },
          ),
      ],
    );
  }

  void _showStorageResetBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final isGuest = FirebaseAuth.instance.currentUser == null;
        
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).cardTheme.color ?? AppTheme.darkSurface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border.all(
              color: Theme.of(sheetContext).dividerColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.only(
            top: 10,
            left: 20,
            right: 20,
            bottom: 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Pull Indicator
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).textTheme.bodySmall?.color?.withValues(alpha: 0.3) ?? Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAction.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.storage_rounded,
                      color: AppTheme.primaryAction,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Storage & Reset',
                          style: Theme.of(sheetContext).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manage your database and cloud space',
                          style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 28),
              
              // Option 1: Clear Local Cache
              GestureDetector(
                onTap: () async {
                  Navigator.pop(sheetContext); // Close bottom sheet
                  
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Theme.of(ctx).cardTheme.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Clear Local Cache'),
                      content: Text(
                        isGuest
                            ? 'This will permanently delete all bills and documents from this phone. This action cannot be undone.'
                            : 'This will delete all bills and documents from this phone. Your settings and Google Drive backup will NOT be deleted.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Theme.of(ctx).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.urgentRed,
                          ),
                          child: const Text(
                            'CLEAR PHONE',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (!context.mounted) return;
                    unawaited(
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) =>
                            const Center(child: CircularProgressIndicator()),
                      ),
                    );

                    try {
                      await ref
                          .read(vaultProvider.notifier)
                          .clearAllData(alsoDeleteCloud: false);
                      if (context.mounted) {
                        Navigator.pop(context); // Close progress dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isGuest
                                  ? 'Local cache cleared.'
                                  : 'Local cache cleared. Settings and Cloud backup preserved.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context); // Close progress dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed: $e'),
                            backgroundColor: AppTheme.urgentRed,
                          ),
                        );
                      }
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(sheetContext).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(sheetContext).dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAction.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.phonelink_erase_rounded,
                          color: AppTheme.primaryAction,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clear Local Cache',
                              style: Theme.of(sheetContext).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Deletes local temporary items only. Cloud backup stays safe.',
                              style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(sheetContext).textTheme.bodySmall?.color,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Option 2: Erase All Data
              GestureDetector(
                onTap: () async {
                  Navigator.pop(sheetContext); // Close bottom sheet
                  
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Theme.of(ctx).cardTheme.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('WIPE EVERYTHING'),
                      content: const Text(
                        'WARNING: This will permanently delete ALL local data AND your Google Drive backup. This cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Theme.of(ctx).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.urgentRed,
                          ),
                          child: const Text(
                            'ERASE CLOUD & PHONE',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (!context.mounted) return;
                    unawaited(
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) =>
                            const Center(child: CircularProgressIndicator()),
                      ),
                    );

                    try {
                      await ref
                          .read(vaultProvider.notifier)
                          .clearAllData(alsoDeleteCloud: true);

                      if (context.mounted) {
                        Navigator.pop(context); // Close progress dialog
                        final isUserLoggedIn =
                            FirebaseAuth.instance.currentUser != null;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isUserLoggedIn
                                  ? 'All data has been wiped from device and cloud.'
                                  : 'All local data has been wiped.',
                            ),
                            backgroundColor: AppTheme.urgentRed,
                          ),
                        );
                        // Force navigation back to start
                        unawaited(
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MainNavigation(),
                            ),
                            (route) => false,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context); // Close progress dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Wipe failed: $e'),
                            backgroundColor: AppTheme.urgentRed,
                          ),
                        );
                      }
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.urgentRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.urgentRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.urgentRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          color: AppTheme.urgentRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Erase All Data',
                              style: Theme.of(sheetContext).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.urgentRed,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'WIPE EVERYTHING. Cloud and local data will be permanently deleted.',
                              style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                color: Theme.of(sheetContext).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.urgentRed,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isGuest) ...[
                const SizedBox(height: 16),
                
                // Option 3: Delete Account & Cloud Data
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(sheetContext); // Close bottom sheet
                    
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Theme.of(ctx).cardTheme.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('DELETE ACCOUNT'),
                        content: const Text(
                          'WARNING: This is permanent and irreversible. This will delete all your local data, your Google Drive backup, your Firestore database records, and permanently close your account registration. You will be logged out completely.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Theme.of(ctx).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.urgentRed,
                            ),
                            child: const Text(
                              'DELETE CONT & DATE',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      if (!context.mounted) return;
                      unawaited(
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) =>
                              const Center(child: CircularProgressIndicator()),
                        ),
                      );

                      try {
                        // 1. Reauthenticate first to refresh credentials and prevent stale-session errors
                        await ref.read(authServiceProvider).reauthenticate();

                        // 2. Wipe local and cloud database items (Firestore & Drive AppData folder)
                        await ref
                            .read(vaultProvider.notifier)
                            .clearAllData(alsoDeleteCloud: true);

                        // 3. Reset Local Security/PIN state
                        await ref.read(securityProvider.notifier).reset();

                        // 4. Delete actual authentication registration
                        await ref.read(authServiceProvider).deleteAccount();

                        // 5. Complete sign-out cleanly
                        await ref.read(authServiceProvider).signOut();

                        // 6. Switch the memory guest provider state to true
                        ref.read(isGuestProvider.notifier).state = true;

                        // 7. Reset Isar config to switch back to guest mode automatically on launch
                        final isar = ref.read(isarProvider);
                        await isar.writeTxn(() async {
                          final config = AppConfig()..isGuest = true;
                          await isar.appConfigs.put(config);
                        });

                        if (context.mounted) {
                          Navigator.pop(context); // Close progress dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account and all data deleted successfully.'),
                              backgroundColor: AppTheme.urgentRed,
                            ),
                          );
                          // Force reset app navigation state
                          unawaited(
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MainNavigation(),
                              ),
                              (route) => false,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context); // Close progress dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Account deletion failed: $e'),
                              backgroundColor: AppTheme.urgentRed,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.urgentRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.urgentRed.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.urgentRed.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.no_accounts_rounded,
                            color: AppTheme.urgentRed,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delete Account & Data',
                                style: Theme.of(sheetContext).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.urgentRed,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Wipes all local & cloud data and permanently deletes your account registration.',
                                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  color: Theme.of(sheetContext).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppTheme.urgentRed,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataManagement(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('STORAGE INTEGRITY'),
        const SizedBox(height: 2),
        BentoCard(
          padding: EdgeInsets.zero,
          child: _buildSettingItem(
            icon: Icons.storage_rounded,
            title: 'Storage Integrity',
            subtitle: 'Manage local database and cloud storage',
            onTap: () => _showStorageResetBottomSheet(context, ref),
          ),
        ),
      ],
    );
  }
  Widget _buildCompactProfile(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        final isGuest = user == null;

        // Log user type dynamically to Firebase Analytics
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(analyticsServiceProvider).logUserType(isGuest);
        });

        return BentoCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2), // Gradient ring gap
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryAction.withValues(alpha: 0.8),
                      AppTheme.primaryAction.withValues(alpha: 0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    shape: BoxShape.circle,
                    image: user?.photoURL != null
                        ? DecorationImage(
                            image: NetworkImage(user!.photoURL!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: user?.photoURL == null
                      ? Icon(
                          Icons.person_outline_rounded,
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.color
                              ?.withValues(alpha: 0.7),
                          size: 22,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (user?.displayName?.isNotEmpty == true)
                          ? user!.displayName!
                          : (user?.email?.split('@').first ?? 'Guest User'),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGuest ? 'Local mode active' : (user.email ?? ''),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isGuest)
                GestureDetector(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      useRootNavigator: true,
                      builder: (context) => AlertDialog(
                        backgroundColor: Theme.of(context).cardTheme.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Sign Out'),
                        content: const Text(
                          'Are you sure you want to sign out? Your encrypted data will remain safe on this device.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Sign Out',
                              style: TextStyle(
                                color: AppTheme.urgentRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      debugPrint(
                        'SettingsScreen: Sign Out confirmed. Clearing session flags.',
                      );

                      // 1. Reset Security (FaceID/PIN) - as requested
                      await ref.read(securityProvider.notifier).reset();

                      // 2. Reset Isar config (Persistence fix)
                      final isar = ref.read(isarProvider);
                      await isar.writeTxn(() async {
                        final config =
                            await isar.appConfigs.get(0) ?? AppConfig();
                        config.isGuest =
                            true; // Switch back to guest mode automatically
                        await isar.appConfigs.put(config);
                      });

                      // 3. Perform logout
                      await ref.read(authServiceProvider).signOut();
                      ref.read(isGuestProvider.notifier).state = true;

                      if (context.mounted) {
                        unawaited(
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MainNavigation(),
                            ),
                            (route) => false,
                          ),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Signed out. You are now in Guest mode.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.urgentRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.urgentRed.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            color: AppTheme.urgentRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.logout_rounded,
                          color: AppTheme.urgentRed,
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('Error loading profile'),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2, top: 2),
      child: Text(
        title,
        style: AppTheme.labelCapsStyle(context).copyWith(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontSize: 12,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Container(
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.primaryAction, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            )
          : null,
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).textTheme.bodySmall?.color,
            size: 14,
          ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildCurrencyItem(
    BuildContext context,
    WidgetRef ref,
    Currency current,
  ) {
    return _buildSettingItem(
      icon: Icons.currency_exchange_rounded,
      title: 'Primary Currency',
      subtitle: current.code == 'RON'
          ? current.code
          : '${current.code} (${current.symbol})',
      trailing: DropdownButton<Currency>(
        value: current,
        underline: const SizedBox(),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Theme.of(context).textTheme.bodySmall?.color,
          size: 16,
        ),
        onChanged: (Currency? newValue) {
          if (newValue != null) {
            ref.read(currencyProvider.notifier).setCurrency(newValue);
            ref.read(analyticsServiceProvider).logSettingsChanged('primary_currency', newValue.code);
          }
        },
        items: availableCurrencies.map<DropdownMenuItem<Currency>>((
          Currency value,
        ) {
          return DropdownMenuItem<Currency>(
            value: value,
            child: Text(
              value.code,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
        dropdownColor: Theme.of(context).cardTheme.color,
      ),
    );
  }

  Widget _buildSecuritySettings(BuildContext context, WidgetRef ref) {
    final security = ref.watch(securityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('BIOMETRIC LOCK'),
        const SizedBox(height: 2),
        BentoCard(
          padding: EdgeInsets.zero,
          child: _buildSettingItem(
            icon: Icons.fingerprint_rounded,
            title: 'Biometric Lock',
            subtitle: 'Secure entry with FaceID or Fingerprint',
            trailing: SizedBox(
              height: 24,
              child: Switch(
                value: security.isEnabled,
                onChanged: (value) {
                  if (value) {
                    if (!security.canAuthenticate) {
                      _showNoSecurityDialog(context);
                      return;
                    }
                    ref.read(securityProvider.notifier).toggleSecurity(true);
                    ref.read(analyticsServiceProvider).logSettingsChanged('biometric_lock_enabled', true);
                  } else {
                    ref.read(securityProvider.notifier).toggleSecurity(false);
                    ref.read(analyticsServiceProvider).logSettingsChanged('biometric_lock_enabled', false);
                  }
                },
                activeThumbColor: AppTheme.primaryAction,
                activeTrackColor: AppTheme.primaryAction.withValues(
                  alpha: 0.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showNoSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Security Required'),
        content: const Text(
          'To enable App Lock, your device must have a PIN, Pattern, or Biometric lock enabled. Would you like to set one up now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Later',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(securityProvider.notifier).openSecuritySettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAction,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Open Settings'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBetaMonitoring(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('BETA MONITORING'),
        const SizedBox(height: 2),
        BentoCard(
          padding: EdgeInsets.zero,
          child: _buildSettingItem(
            icon: Icons.bug_report_outlined,
            iconColor: AppTheme.urgentRed,
            title: 'Simulate Test Crash',
            subtitle: 'Forces an immediate crash for Crashlytics test',
            trailing: const Icon(
              Icons.chevron_right,
              size: 14,
              color: AppTheme.urgentRed,
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Theme.of(context).cardTheme.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Simulate Crash?'),
                  content: const Text(
                    'This will trigger an immediate hard crash of the application using FirebaseCrashlytics.instance.crash() to verify your integration online. Make sure you saved your changes.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.urgentRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('CRASH NOW'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                logger.i('Simulating app crash via Firebase Crashlytics...');
                await Future.delayed(const Duration(milliseconds: 500));
                FirebaseCrashlytics.instance.crash();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVersionFooter(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _devModeTaps++;
            if (_devModeTaps >= 7) {
              if (!_isDevModeEnabled) {
                _isDevModeEnabled = true;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Developer Options enabled! 🛠️'),
                    backgroundColor: AppTheme.safeGreen,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } else if (_devModeTaps > 2) {
              final remaining = 7 - _devModeTaps;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You are now $remaining steps away from being a developer!'),
                  duration: const Duration(milliseconds: 500),
                ),
              );
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            'Version 1.0.0 (Pre-Beta)',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
