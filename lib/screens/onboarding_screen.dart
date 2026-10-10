import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../providers/notification_provider.dart';
import '../services/auth_flow_helper.dart';
import 'onboarding/onboarding_notifications_page.dart';
import 'onboarding/onboarding_sync_page.dart';
import 'onboarding/onboarding_tutorial_page.dart';
import 'onboarding/onboarding_permission_dialog.dart';
import '../utils/logger.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _didOpenSettings = false;
  bool _isRequestingPermission = false;

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
    if (_currentPage == 1 && _didOpenSettings) {
      _didOpenSettings = false;
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
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (_isRequestingPermission) return;
    setState(() => _isRequestingPermission = true);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
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
          final opened = await OnboardingPermissionDialog.show(context, isDark);
          if (mounted) setState(() => _didOpenSettings = opened);
        }
        return;
      }

      PermissionStatus requestStatus;
      try {
        requestStatus = await Permission.notification.request();
      } catch (e) {
        logger.w('OnboardingScreen: Permission request threw exception: $e');
        requestStatus = await Permission.notification.status;
      }

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
          final opened = await OnboardingPermissionDialog.show(context, isDark);
          if (mounted) setState(() => _didOpenSettings = opened);
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
    } finally {
      if (mounted) {
        setState(() => _isRequestingPermission = false);
      }
    }
  }

  void _goToNextPage() {
    HapticFeedback.lightImpact();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _skipToFinalPage() {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: SizedBox(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_currentPage < 2)
                      TextButton(
                        onPressed: _skipToFinalPage,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          'Skip',
                          style: AppTypography.labelMedium(AppColors.textSecondary(isDark)).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Main Page Content
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
                    isLoading: _isRequestingPermission,
                    onEnableNotifications: _requestNotificationPermission,
                    onDecideLater: _goToNextPage,
                  ),
                  OnboardingSyncPage(
                    onGoogleSignInPressed: () =>
                        AuthFlowHelper.handleGoogleSignIn(context, ref, isDark),
                    onGuestLoginPressed: () async {
                      await HapticFeedback.mediumImpact();
                      await AuthFlowHelper.completeOnboarding(ref, isGuest: true);
                    },
                  ),
                ],
              ),
            ),

            // Fluid Animated Page Indicator
            _buildPageIndicator(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final isSelected = _currentPage == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isSelected ? 26 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.emerald500
                  : (isDark ? AppColors.slate700 : AppColors.slate300),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
