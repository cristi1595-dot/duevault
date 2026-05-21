import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import '../theme/app_theme.dart';
import '../widgets/global_components.dart';
import '../providers/auth_provider.dart';
import '../providers/database_provider.dart';
import '../models/app_config.dart';
import '../services/auto_sync_service.dart';
import '../providers/notification_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

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
    if (_currentPage == 0) {
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
    } else if (_currentPage == 1) {
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
                  _buildNotificationScreen(),
                  _buildBatteryScreen(),
                  _buildLoginScreen(),
                ],
              ),
            ),
            _buildPageIndicator(),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE PREMIUM UI COMPONENTS ---

  Widget _buildBackgroundGlow(Color color) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
    );
  }

  // Premium header utilizing the winning brand identity
  Widget _buildHeader() {
    return Column(
      children: [
        const DueVaultLogo(size: 96),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Due',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
            ),
            Text(
              'Vault',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: AppTheme.safeGreen,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  // --- SCREEN 1: NOTIFICATIONS ---

  Widget _buildNotificationScreen() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHeader(),
            const SizedBox(height: 40),
            // Glowing, pulsing-style concentric ripples around a large active bell
            Stack(
              alignment: Alignment.center,
              children: [
                _buildBackgroundGlow(AppTheme.accentPurple),
                // Outer Ripple Ring
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.accentPurple.withValues(alpha: 0.15),
                      width: 1.0,
                    ),
                  ),
                ),
                // Inner Ripple Ring
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.accentPurple.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                ),
                // Core Icon Cap
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1F26), // AppTheme.darkSurface
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.accentPurple.withValues(alpha: 0.4),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentPurple.withValues(alpha: 0.15),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    size: 48,
                    color: AppTheme.accentPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              'Never miss a due date',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Get smart, timely alerts right on your screen before your bills or important documents expire. No penalties, no stress.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: 40),
            PrimaryButton(
              label: 'Enable Notifications',
              icon: Icons.notifications_active,
              onPressed: _requestNotificationPermission,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
              child: Text(
                'Decide later',
                style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SCREEN 2: BATTERY OPTIMIZATION ---

  Widget _buildBatteryScreen() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHeader(),
            const SizedBox(height: 40),
            // Glowing energy ripples around charging battery shield
            Stack(
              alignment: Alignment.center,
              children: [
                _buildBackgroundGlow(AppTheme.safeGreen),
                // Outer Ripple Ring
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.safeGreen.withValues(alpha: 0.15),
                      width: 1.0,
                    ),
                  ),
                ),
                // Inner Ripple Ring
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.safeGreen.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                ),
                // Core Icon Cap
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1F26), // AppTheme.darkSurface
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.safeGreen.withValues(alpha: 0.4),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.safeGreen.withValues(alpha: 0.15),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.battery_charging_full_rounded, // Upgraded to modern battery with bolt icon
                    size: 48,
                    color: AppTheme.safeGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              'Reliable background alerts',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              "Your phone's system often puts inactive apps to sleep. Grant permission to run discreetly in the background so you always receive alerts on time.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: 40),
            PrimaryButton(
              label: 'Guarantee Alerts',
              icon: Icons.bolt,
              onPressed: _requestBatteryOptimization,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
              child: Text(
                'Skip for now',
                style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SCREEN 3: SECURE CLOUD BACKUP & AUTH ---

  Widget _buildLoginScreen() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHeader(),
            const SizedBox(height: 40),
            // Glowing sync rings around cloud indicator
            Stack(
              alignment: Alignment.center,
              children: [
                _buildBackgroundGlow(AppTheme.primaryAction),
                // Outer Ripple Ring
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryAction.withValues(alpha: 0.15),
                      width: 1.0,
                    ),
                  ),
                ),
                // Inner Ripple Ring
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryAction.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                ),
                // Core Icon Cap
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1F26), // AppTheme.darkSurface
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryAction.withValues(alpha: 0.4),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryAction.withValues(alpha: 0.15),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.cloud_done_rounded,
                    size: 48,
                    color: AppTheme.primaryAction,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              'Secure Cloud Backup',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sync your vault with Google for automatic, secure backups and seamless access across all your devices.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: 40),
            _buildGoogleSignInButton(),
            const SizedBox(height: 16),
            // Outlined elegant Guest Button
            SecondaryButton(
              label: 'Use Locally (Guest)',
              icon: Icons.person_outline_rounded,
              onPressed: () async {
                await _completeOnboarding(isGuest: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return ElevatedButton(
      onPressed: () async {
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
          await _completeOnboarding();

          messenger.showSnackBar(
            const SnackBar(
              content: Text('Account secured. Syncing your vault...'),
            ),
          );

          final syncResult = await ref
              .read(autoSyncServiceProvider)
              .syncAfterLogin();
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
        } else {
          messenger.showSnackBar(
            const SnackBar(content: Text('Google Sign-in failed')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1B1F26), // AppTheme.darkSurface
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // Pill style to align with PrimaryButton
          side: const BorderSide(
            color: Color(0xFF2D333D), // AppTheme.darkBorder
            width: 1.5,
          ),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
            height: 24,
            errorBuilder: (ctx, err, st) =>
                const Icon(Icons.account_circle, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'Sync with Google',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
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
