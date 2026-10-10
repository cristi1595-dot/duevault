import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';
import '../../widgets/primary_button.dart';
import 'onboarding_header.dart';
import 'onboarding_ripple_illustration.dart';

class OnboardingNotificationsPage extends StatelessWidget {
  final VoidCallback onEnableNotifications;
  final VoidCallback onDecideLater;
  final bool isLoading;

  const OnboardingNotificationsPage({
    super.key,
    required this.onEnableNotifications,
    required this.onDecideLater,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          children: [
            const OnboardingHeader(),
            const SizedBox(height: 24),

            // Concentric Ripple Illustration
            const OnboardingRippleIllustration(
              color: AppColors.violet500,
              icon: Icons.notifications_active_rounded,
              size: 190,
            ),

            const SizedBox(height: 24),

            // Headline
            Text(
              'Never miss a due date',
              textAlign: TextAlign.center,
              style: AppTypography.headlineLarge(AppColors.textPrimary(isDark)).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Subtitle
            Text(
              'Get smart, timely alerts before bills or documents expire. No penalties, no stress.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(AppColors.textSecondary(isDark)).copyWith(
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            // Feature Highlights Mini-Tiles
            _buildFeaturePill(
              context,
              isDark,
              icon: Icons.schedule_rounded,
              text: 'Alerts at 3 days, 1 day, and on due date',
            ),
            const SizedBox(height: 8),
            _buildFeaturePill(
              context,
              isDark,
              icon: Icons.mark_email_read_outlined,
              text: 'Zero spam — strictly your personal vault',
            ),

            const SizedBox(height: 28),

            // Call to Action
            PrimaryButton(
              label: 'Enable Notifications',
              icon: Icons.notifications_active_rounded,
              isLoading: isLoading,
              onPressed: isLoading ? null : onEnableNotifications,
            ),
            const SizedBox(height: 12),

            // Decide later
            TextButton(
              onPressed: onDecideLater,
              child: Text(
                'Decide later',
                style: AppTypography.labelMedium(AppColors.textSecondary(isDark)).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturePill(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.border(isDark),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.violet500,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall(AppColors.textPrimary(isDark)).copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
