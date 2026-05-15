import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import '../theme/app_theme.dart';
import '../widgets/global_components.dart';
import '../providers/auth_provider.dart';
import '../providers/database_provider.dart';
import '../models/app_config.dart';
import '../providers/vault_provider.dart';
import '../services/auto_sync_service.dart';
import 'package:permission_handler/permission_handler.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeOnboarding() async {
    final isar = ref.read(isarProvider);
    await isar.writeTxn(() async {
      final config = await isar.appConfigs.get(0) ?? AppConfig();
      config.hasSeenOnboarding = true;
      await isar.appConfigs.put(config);
    });
    ref.read(hasSeenOnboardingProvider.notifier).state = true;
  }

  Future<void> _requestBatteryOptimization() async {
    final isDisabled = await DisableBatteryOptimization.isBatteryOptimizationDisabled;
    if (isDisabled == false) {
      await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Battery optimization is already disabled!')),
        );
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      if (mounted) {
        unawaited(_pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications are highly recommended for bill alerts!'),
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

  Widget _buildNotificationScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App Logo with rounded corners for premium look
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/full_logo.png',
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentPurple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              size: 48,
              color: AppTheme.accentPurple,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Never Miss a Due Date',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Enable notifications to receive timely alerts for your bills and important document renewals.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 64),
          PrimaryButton(
            label: 'Enable Notifications',
            icon: Icons.notifications_active,
            onPressed: _requestNotificationPermission,
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            ),
            child: Text(
              'Decide later',
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.safeGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.battery_charging_full_outlined,
              size: 80,
              color: AppTheme.safeGreen,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Reliable Background Sync',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'To ensure alerts work every time, DueVault needs to run in the background without being restricted by system battery savers.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 64),
          PrimaryButton(
            label: 'Optimize Performance',
            icon: Icons.bolt,
            onPressed: _requestBatteryOptimization,
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            ),
            child: Text(
              'Skip for now',
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryAction.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_sync_outlined,
              size: 80,
              color: AppTheme.primaryAction,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Secure Cloud Backup',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sync your vault with Google for extra security and seamless access across all your devices.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 64),
          _buildGoogleSignInButton(),
          const SizedBox(height: 20),
          SecondaryButton(
            label: 'Use Locally (Guest)',
            icon: Icons.no_accounts_outlined,
            onPressed: () async {
              await _completeOnboarding();
              ref.read(isGuestProvider.notifier).state = true;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return ElevatedButton(
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        unawaited(showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryAction),
          ),
        ));

        final userCredential = await ref.read(authServiceProvider).signInWithGoogle();
        if (!mounted) return;
        Navigator.pop(context);

        if (userCredential != null) {
          await ref.read(vaultProvider.notifier).migrateGuestData(userCredential.user!.uid);
          await _completeOnboarding();
          
          messenger.showSnackBar(const SnackBar(content: Text('Account secured. Syncing your vault...')));
          
          final syncResult = await ref.read(autoSyncServiceProvider).syncAfterLogin();
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
          
          messenger.showSnackBar(SnackBar(
            content: Text(syncMsg),
            backgroundColor: bgColor,
            behavior: SnackBarBehavior.floating,
          ));
        } else {
          messenger.showSnackBar(const SnackBar(content: Text('Sign in failed')));
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).cardTheme.color,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
            height: 24,
            errorBuilder: (ctx, err, st) => const Icon(Icons.account_circle, size: 24),
          ),
          const SizedBox(width: 12),
          const Text('Sign in with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
