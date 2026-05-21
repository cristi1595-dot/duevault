import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:permission_handler/permission_handler.dart';
import 'settings/settings_dialogs.dart';
import 'settings/smart_alerts_section.dart';
import 'settings/storage_reset_sheet.dart';
import 'settings/google_sign_in_section.dart';
import 'settings/compact_profile_card.dart';
import 'settings/drive_sync_section.dart';
import 'settings/developer_options_section.dart';
import '../theme/app_theme.dart';
import '../widgets/global_components.dart';
import '../providers/currency_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/security_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/sync_provider.dart';
import '../services/notification_service.dart';
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
        await SettingsDialogs.showAppSettingsDialog(context);
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
            const CompactProfileCard(),
            const SizedBox(height: 6),

            // 1.1 Sign In Option (Only for Guests) - Directly under Guest User
             Consumer(
              builder: (context, ref, child) {
                final authState = ref.watch(authStateProvider);
                final user = authState.valueOrNull;
                final isProcessing = ref.watch(isProcessingAuthSyncProvider);
                if (user == null || isProcessing) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: GoogleSignInSection(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // 1.5 Biometric Lock (Security)
            _buildSecuritySettings(context, ref),
            const SizedBox(height: 4),

            // 2. Sync Options (Only for Authenticated Users)
            const DriveSyncSection(),
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
            SmartAlertsSection(
              isBatteryOptimizationDisabled: _isBatteryOptimizationDisabled,
              isNotificationPermissionGranted: _isNotificationPermissionGranted,
              isExactAlarmGranted: _isExactAlarmGranted,
              onAttemptActivation: _attemptActivation,
            ),
            const SizedBox(height: 4),

            _buildDataManagement(context, ref),
            if (_isDevModeEnabled) ...[
              const SizedBox(height: 4),
              const DeveloperOptionsSection(),
            ],
            const SizedBox(height: 16),
            _buildVersionFooter(context),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
            onTap: () => showStorageResetBottomSheet(context, ref),
          ),
        ),
      ],
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
                      SettingsDialogs.showNoSecurityDialog(context);
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
