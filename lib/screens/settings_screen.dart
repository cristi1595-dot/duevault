import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../models/app_config.dart';
import '../services/notification_service.dart';
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
import '../providers/database_provider.dart';
import '../main.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _isBatteryOptimizationDisabled;
  bool _isNotificationPermissionGranted = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    bool? batteryDisabled =
        await DisableBatteryOptimization.isAllBatteryOptimizationDisabled;
    bool notificationsGranted = await Permission.notification.isGranted;

    if (mounted) {
      setState(() {
        _isBatteryOptimizationDisabled = batteryDisabled;
        _isNotificationPermissionGranted = notificationsGranted;
      });
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
            fontSize: 18,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Header
            _buildCompactProfile(context, ref),
            const SizedBox(height: 12),

            // 2. Sign In or Sync Options
            Consumer(
              builder: (context, ref, child) {
                final authState = ref.watch(authStateProvider);
                final user = authState.valueOrNull;
                if (user == null) {
                  return _buildGoogleSignInButton(context, ref);
                } else {
                  return BentoCard(
                    padding: EdgeInsets.zero,
                    child: _buildDriveSyncButtons(context, ref),
                  );
                }
              },
            ),
            const SizedBox(height: 10),

            // 3. Preferences Section
            _buildSectionHeader('PREFERENCES'),
            const SizedBox(height: 4),
            BentoCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildCurrencyItem(context, ref, currentCurrency),
                  _buildSettingItem(
                    icon: themeMode == ThemeMode.dark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    title: 'Dark / Light Mode',
                    trailing: SizedBox(
                      height: 24,
                      child: Switch(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (v) {
                          ref.read(themeProvider.notifier).toggleTheme();
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
            const SizedBox(height: 10),

            // 4. Alerts & Notifications Section
            _buildSectionHeader('ALERTS & NOTIFICATIONS'),
            const SizedBox(height: 4),
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
                              'Enable Global Reminders',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Switch(
                              value: globalEnabled,
                              onChanged: (v) => ref
                                  .read(globalNotificationsProvider.notifier)
                                  .toggle(v),
                              activeThumbColor: AppTheme.primaryAction,
                            ),
                          ],
                        ),

                        if (globalEnabled) ...[
                          // 1. Fixed 3-Day Alert Row
                          Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Early 3-Day Alert',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Fixed early reminder for bills',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Consumer(
                                builder: (context, ref, _) {
                                  final threeDayEnabled = ref.watch(
                                    threeDayAlertEnabledProvider,
                                  );
                                  return Tooltip(
                                    message:
                                        'Get a fixed reminder exactly 3 days before the due date.',
                                    child: Checkbox(
                                      value: threeDayEnabled,
                                      activeColor: AppTheme.primaryAction,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (val) {
                                        ref
                                            .read(
                                              threeDayAlertEnabledProvider
                                                  .notifier,
                                            )
                                            .toggle(val ?? false);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 2. Variable Slider Alert Row
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Tooltip(
                                    message:
                                        'Adjust how many days in advance you want to be notified.',
                                    child: Text(
                                      'Custom Reminder',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$alertDays ${alertDays == 1 ? "Day" : "Days"} before',
                                    style: const TextStyle(
                                      color: AppTheme.primaryAction,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 16,
                                  ),
                                  valueIndicatorTextStyle: const TextStyle(
                                    color: Colors.white,
                                  ),
                                  valueIndicatorColor: AppTheme.primaryAction,
                                ),
                                child: Slider(
                                  value: alertDays.toDouble(),
                                  min: 1,
                                  max: 7,
                                  divisions: 6,
                                  label: '$alertDays Days',
                                  activeColor: AppTheme.primaryAction,
                                  inactiveColor: AppTheme.primaryAction
                                      .withValues(alpha: 0.1),
                                  onChanged: (val) {
                                    ref
                                        .read(alertDaysProvider.notifier)
                                        .setAlertDays(val.toInt());
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Background Restrictions',
                                    style: TextStyle(
                                      fontSize: 14,
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
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () async {
                                // 1. Request Notification Permissions first
                                await NotificationService.requestPermissions();

                                // 2. Then Battery Optimization
                                if (_isBatteryOptimizationDisabled != true) {
                                  await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
                                }

                                // Small delay to allow system to update before we re-check
                                await Future.delayed(
                                  const Duration(seconds: 1),
                                );
                                _checkStatus();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color:
                                      (_isBatteryOptimizationDisabled == true &&
                                          _isNotificationPermissionGranted)
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
                                            _isNotificationPermissionGranted)
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
                                        _isNotificationPermissionGranted)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppTheme.safeGreen,
                                        size: 16,
                                      ),
                                    if (_isBatteryOptimizationDisabled ==
                                            true &&
                                        _isNotificationPermissionGranted)
                                      const SizedBox(width: 4),
                                    Text(
                                      (_isBatteryOptimizationDisabled == true &&
                                              _isNotificationPermissionGranted)
                                          ? 'Active'
                                          : 'Fix Now',
                                      style: TextStyle(
                                        color:
                                            (_isBatteryOptimizationDisabled ==
                                                    true &&
                                                _isNotificationPermissionGranted)
                                            ? AppTheme.safeGreen
                                            : AppTheme.urgentRed,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSecuritySettings(context, ref),
            const SizedBox(height: 10),
            _buildDataManagement(context, ref),
            const SizedBox(height: 12),
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
          final result = await ref.read(authServiceProvider).signInWithGoogle();
          if (result != null) {
            // Migrate guest data to the new user ID
            await ref
                .read(vaultProvider.notifier)
                .migrateGuestData(result.user!.uid);

            // Reset guest mode since user is now authenticated
            ref.read(isGuestProvider.notifier).state = false;

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
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainNavigation()),
                (route) => false,
              );
            }
          } else {
            messenger.showSnackBar(
              const SnackBar(content: Text('Sign in canceled.')),
            );
          }
        } catch (e) {
          debugPrint('Sign in error: $e');
          messenger.showSnackBar(
            SnackBar(
              content: Text('Sign in error: ${e.toString().split('\n').first}'),
              backgroundColor: AppTheme.urgentRed,
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
              height: 20,
              errorBuilder: (ctx, err, st) => const Icon(
                Icons.account_circle_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sign in with Google',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 15,
                fontWeight: FontWeight.bold,
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
          title: 'Auto-Sync Changes',
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
            title: 'WiFi Only',
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

        // --- 5. Cloud Recovery (Manual Pull) ---
        _buildSettingItem(
          icon: Icons.cloud_download_outlined,
          title: 'Sync from Cloud',
          subtitle: 'Merge data from your Google Drive',
          onTap: () async {
            final scaffold = ScaffoldMessenger.of(context);
            scaffold.showSnackBar(
              const SnackBar(
                content: Text('⏳ Checking cloud for updates...'),
                duration: Duration(seconds: 2),
              ),
            );

            try {
              final result =
                  await ref.read(autoSyncServiceProvider).syncAfterLogin();

              String message;
              Color? color;

              if (result == 'restored') {
                message = '✓ Vault updated with cloud data!';
                color = AppTheme.safeGreen;
              } else if (result == 'uploaded') {
                message = '✓ Local data backed up to cloud!';
                color = AppTheme.primaryAction;
              } else {
                message = 'Your vault is already up to date.';
                color = null;
              }

              scaffold.showSnackBar(
                SnackBar(content: Text(message), backgroundColor: color),
              );
            } catch (e) {
              scaffold.showSnackBar(
                SnackBar(
                  content: Text('Sync error: ${e.toString()}'),
                  backgroundColor: AppTheme.urgentRed,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildDataManagement(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('DATA MANAGEMENT'),
        const SizedBox(height: 8),
        BentoCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildSettingItem(
                icon: Icons.phonelink_erase,
                title: 'Clear Local Data',
                subtitle: 'Deletes local items only. Cloud backup stays safe.',
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    useRootNavigator: true,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Theme.of(context).cardTheme.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Clear Local Data'),
                      content: const Text(
                        'This will delete all bills and documents from this phone. Your settings and Google Drive backup will NOT be deleted.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
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
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      await ref
                          .read(vaultProvider.notifier)
                          .clearAllData(alsoDeleteCloud: false);
                      if (context.mounted) {
                        Navigator.pop(context); // Close progress
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Local data cleared. Settings and Cloud backup preserved.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context); // Close progress
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
              ),
            ],
          ),
        ),
        if (FirebaseAuth.instance.currentUser != null) ...[
          const SizedBox(height: 12),
          BentoCard(
            padding: EdgeInsets.zero,
            color: AppTheme.urgentRed.withValues(alpha: 0.1),
            borderColor: AppTheme.urgentRed.withValues(alpha: 0.5),
            child: _buildSettingItem(
              icon: Icons.delete_forever,
              iconColor: AppTheme.urgentRed,
              title: 'Erase All Data',
              titleColor: AppTheme.urgentRed,
              subtitle: 'WIPE EVERYTHING (cannot be undone)',
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Theme.of(context).cardTheme.color,
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
                        child: const Text('Cancel'),
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
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    await ref
                        .read(vaultProvider.notifier)
                        .clearAllData(alsoDeleteCloud: true);

                    if (context.mounted) {
                      Navigator.pop(context); // Close progress
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
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MainNavigation(),
                        ),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Close progress
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
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactProfile(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        final isGuest = user == null;
        return BentoCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1.5,
                  ),
                  image: user?.photoURL != null
                      ? DecorationImage(
                          image: NetworkImage(user!.photoURL!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: user?.photoURL == null
                    ? Icon(
                        Icons.person,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        size: 24,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isGuest ? 'Local mode active' : (user.email ?? ''),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isGuest)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.urgentRed,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  onPressed: () async {
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
                          'Are you sure you want to sign out? Your encrypted data will remain safe on this device for a faster experience when you return.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
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
                        'SettingsScreen: Sign Out confirmed. Preserving local encrypted data.',
                      );

                      await ref.read(authServiceProvider).signOut();
                      ref.read(isGuestProvider.notifier).state = true;

                      // Trigger a refresh (will stay empty)
                      await ref.read(vaultProvider.notifier).refreshVault();

                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainNavigation(),
                          ),
                          (route) => false,
                        );
                      }
                    }
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.logout, size: 20),
                    ],
                  ),
                )
              else
                Icon(
                  Icons.verified_user_outlined,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  size: 18,
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
      padding: const EdgeInsets.only(left: 4, bottom: 4, top: 12),
      child: Text(
        title,
        style: AppTheme.labelCapsStyle(context).copyWith(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontSize: 10,
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
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.primaryAction, size: 16),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 10,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
    );
  }

  Widget _buildCurrencyItem(
    BuildContext context,
    WidgetRef ref,
    Currency current,
  ) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.currency_exchange,
          color: AppTheme.primaryAction,
          size: 18,
        ),
      ),
      title: Text(
        'Currency',
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        current.code == 'RON'
            ? current.code
            : '${current.code} (${current.symbol})',
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
          fontSize: 11,
        ),
      ),
      trailing: DropdownButton<Currency>(
        value: current,
        underline: const SizedBox(),
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: Theme.of(context).textTheme.bodyMedium?.color,
          size: 18,
        ),
        onChanged: (Currency? newValue) {
          if (newValue != null) {
            ref.read(currencyProvider.notifier).setCurrency(newValue);
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
                fontSize: 13,
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
        _buildSectionHeader('SECURITY'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAction.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    color: AppTheme.primaryAction,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'FaceID / Fingerprint / PIN',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                trailing: Switch(
                  value: security.isEnabled,
                  onChanged: (value) {
                    if (value) {
                      if (!security.canAuthenticate) {
                        _showNoSecurityDialog(context);
                        return;
                      }
                      ref.read(securityProvider.notifier).toggleSecurity(true);
                    } else {
                      ref.read(securityProvider.notifier).toggleSecurity(false);
                    }
                  },
                  activeThumbColor: AppTheme.primaryAction,
                  activeTrackColor: AppTheme.primaryAction.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              if (security.isEnabled) ...[
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 0,
                  ),
                  title: const Text(
                    'Lock when minimized',
                    style: TextStyle(fontSize: 13),
                  ),
                  trailing: Switch(
                    value: security.lockOnBackground,
                    onChanged: (value) {
                      ref
                          .read(securityProvider.notifier)
                          .toggleLockOnBackground(value);
                    },
                    activeThumbColor: AppTheme.primaryAction,
                    activeTrackColor: AppTheme.primaryAction.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
              ],
            ],
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
}
