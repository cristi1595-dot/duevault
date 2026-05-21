import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/global_components.dart';
import 'onboarding_header.dart';
import 'onboarding_ripple_illustration.dart';

class OnboardingNotificationsPage extends StatelessWidget {
  final VoidCallback onEnableNotifications;
  final VoidCallback onDecideLater;

  const OnboardingNotificationsPage({
    super.key,
    required this.onEnableNotifications,
    required this.onDecideLater,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const OnboardingHeader(),
            const SizedBox(height: 40),
            const OnboardingRippleIllustration(
              color: AppTheme.accentPurple,
              icon: Icons.notifications_active_rounded,
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
              onPressed: onEnableNotifications,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onDecideLater,
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
}
