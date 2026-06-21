import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../widgets/global_components.dart';
import 'onboarding_header.dart';
import 'onboarding_ripple_illustration.dart';
import '../../providers/premium_provider.dart';

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
              color: AppTheme.primaryAction,
              icon: Icons.cloud_done_rounded,
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
            _buildGoogleSignInButton(context, ref),
            const SizedBox(height: 16),
            // Outlined elegant Guest Button
            SecondaryButton(
              label: 'Use Locally (Guest)',
              icon: Icons.person_outline_rounded,
              onPressed: onGuestLoginPressed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: onGoogleSignInPressed,
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
          if (!ref.watch(isPremiumProvider)) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.safeGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.safeGreen.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 11,
                    color: AppTheme.safeGreen,
                  ),
                  SizedBox(width: 3),
                  Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.safeGreen,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
