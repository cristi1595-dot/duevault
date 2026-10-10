import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_typography.dart';
import '../../widgets/secondary_button.dart';
import 'onboarding_header.dart';
import 'onboarding_ripple_illustration.dart';

class OnboardingSyncPage extends ConsumerWidget {
  final VoidCallback onGoogleSignInPressed;
  final VoidCallback onGuestLoginPressed;

  const OnboardingSyncPage({
    super.key,
    required this.onGoogleSignInPressed,
    required this.onGuestLoginPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          children: [
            const OnboardingHeader(),
            const SizedBox(height: 24),

            // Ripple Illustration
            const OnboardingRippleIllustration(
              color: AppColors.emerald500,
              icon: Icons.cloud_done_rounded,
              size: 190,
            ),

            const SizedBox(height: 24),

            // Headline
            Text(
              'Secure Cloud Backup',
              textAlign: TextAlign.center,
              style: AppTypography.headlineLarge(AppColors.textPrimary(isDark)).copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Subtitle
            Text(
              'Sync your vault with Google for automatic backups across devices, or keep it 100% offline.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(AppColors.textSecondary(isDark)).copyWith(
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            // Trust Pills
            _buildTrustBadge(
              context,
              isDark,
              icon: Icons.sync_rounded,
              text: 'Automatic encrypted cloud backup',
            ),
            const SizedBox(height: 8),
            _buildTrustBadge(
              context,
              isDark,
              icon: Icons.lock_outline_rounded,
              text: 'Zero tracking • Your data stays yours',
            ),

            const SizedBox(height: 28),

            // Google Sign In Button
            _buildGoogleSignInButton(context, isDark),
            const SizedBox(height: 12),

            // Continue as Guest Button
            SecondaryButton(
              label: 'Continue as Guest (Offline Vault)',
              icon: Icons.lock_open_rounded,
              onPressed: onGuestLoginPressed,
            ),
            const SizedBox(height: 14),

            // Bottom Guarantee
            Text(
              'No account required to use offline • 100% Free',
              textAlign: TextAlign.center,
              style: AppTypography.caption(AppColors.textSecondary(isDark)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadge(
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
            color: AppColors.emerald500,
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

  Widget _buildGoogleSignInButton(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.border(isDark),
          width: 1.0,
        ),
        boxShadow: !isDark ? AppShadows.sm : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onGoogleSignInPressed,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                height: 20,
                cacheHeight: 40,
                errorBuilder: (ctx, err, st) => Icon(
                  Icons.account_circle,
                  size: 20,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sign in with Google',
                style: AppTypography.titleMedium(AppColors.textPrimary(isDark)).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
