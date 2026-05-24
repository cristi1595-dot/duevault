import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/database_provider.dart';
import '../models/app_config.dart';
import '../services/auto_sync_service.dart';
import '../services/firebase_sync_service.dart';
import '../providers/notification_provider.dart';
import '../providers/vault_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'onboarding/onboarding_notifications_page.dart';
import 'onboarding/onboarding_battery_page.dart';
import 'onboarding/onboarding_sync_page.dart';
import 'onboarding/onboarding_tutorial_page.dart';
import 'paywall_screen.dart';
import '../providers/premium_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsOnResume();
    }
  }

  Future<void> _checkPermissionsOnResume() async {
    if (_currentPage == 1) {
      final isGranted = await Permission.notification.isGranted;
      if (isGranted && mounted) {
        await ref.read(globalNotificationsProvider.notifier).toggle(true);
        unawaited(
          _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          ),
        );
      }
    } else if (_currentPage == 2) {
      final isBatteryDisabled =
          await DisableBatteryOptimization.isBatteryOptimizationDisabled ?? false;
      if (isBatteryDisabled && mounted) {
        unawaited(
          _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          ),
        );
      }
    }
  }

  Future<void> _completeOnboarding({bool isGuest = false}) async {
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      final config = await isar.appConfigs.get(0) ?? AppConfig();
      config.hasSeenOnboarding = true;
      config.isGuest = isGuest;
      await isar.appConfigs.put(config);
    });
    if (isGuest) {
      ref.read(isGuestProvider.notifier).state = true;
    }
    ref.read(hasSeenOnboardingProvider.notifier).state = true;
  }

  Future<void> _requestBatteryOptimization() async {
    final isDisabledBefore =
        await DisableBatteryOptimization.isBatteryOptimizationDisabled;
    if (isDisabledBefore == false) {
      await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
      // Așteptăm scurt timp pentru ca sistemul să actualizeze starea la întoarcerea în aplicație
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final isNowDisabled =
        await DisableBatteryOptimization.isBatteryOptimizationDisabled;
    if (isNowDisabled == true) {
      if (mounted) {
        unawaited(
          _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please disable battery optimization to proceed, or click "Skip for now".',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showAppSettingsDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Notifications Disabled'),
        content: const Text(
          'To enable notifications, please allow them for DueVault in your device settings.',
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
              Navigator.pop(ctx);
              await AppSettings.openAppSettings(type: AppSettingsType.notification);
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

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    
    if (status.isGranted) {
      await ref.read(globalNotificationsProvider.notifier).toggle(true);
      if (mounted) {
        unawaited(
          _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          ),
        );
      }
      return;
    }

    if (status.isPermanentlyDenied) {
      if (mounted) {
        await _showAppSettingsDialog();
      }
      return;
    }

    final requestStatus = await Permission.notification.request();
    if (requestStatus.isGranted) {
      await ref.read(globalNotificationsProvider.notifier).toggle(true);
      if (mounted) {
        unawaited(
          _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          ),
        );
      }
    } else if (requestStatus.isPermanentlyDenied) {
      if (mounted) {
        await _showAppSettingsDialog();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notifications are highly recommended for bill alerts!',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleGoogleSignIn() async {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryAction),
        ),
      ),
    );

    final userCredential = await ref
        .read(authServiceProvider)
        .signInWithGoogle();
    if (!mounted) return;
    Navigator.pop(context);

    if (userCredential != null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Account secured. Syncing your vault...'),
        ),
      );

      final syncResult = await ref
          .read(autoSyncServiceProvider)
          .syncAfterLogin();
      
      // Also trigger Firebase Firestore sync immediately after onboarding login to pull user items
      await ref.read(firebaseSyncServiceProvider).sync();

      // Refresh UI state to load the newly downloaded items from Isar
      await ref.read(vaultProvider.notifier).refreshVault();
      
      if (!mounted) return;

      messenger.clearSnackBars();
      String syncMsg;
      Color? bgColor;

      if (syncResult == 'restored') {
        syncMsg = '✓ Vault restored successfully!';
        bgColor = AppTheme.safeGreen;
      } else if (syncResult == 'uploaded') {
        syncMsg = '✓ Local data secured in your cloud!';
        bgColor = AppTheme.primaryAction;
      } else {
        syncMsg = '✓ Vault ready!';
        bgColor = null;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(syncMsg),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Complete onboarding last so navigation triggers after all sync operations are done
      await _completeOnboarding();
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Google Sign-in failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('DueVault: Building OnboardingScreen (Page: $_currentPage)');
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  OnboardingTutorialPage(
                    onContinue: _goToNextPage,
                  ),
                  OnboardingNotificationsPage(
                    onEnableNotifications: _requestNotificationPermission,
                    onDecideLater: _goToNextPage,
                  ),
                  OnboardingBatteryPage(
                    onGuaranteeAlerts: _requestBatteryOptimization,
                    onSkipForNow: _goToNextPage,
                  ),
                  OnboardingSyncPage(
                    onGoogleSignInPressed: _handleGoogleSignIn,
                    onGuestLoginPressed: () async {
                      await _completeOnboarding(isGuest: true);
                    },
                  ),
                ],
              ),
            ),
            _buildPageIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: _currentPage == index ? 32 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? AppTheme.primaryAction
                  : AppTheme.textSecondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(5),
            ),
          );
        }),
      ),
    );
  }
}
