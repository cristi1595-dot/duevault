import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/duevault_logo.dart';
import '../widgets/secondary_button.dart';
import '../services/auth_flow_helper.dart';
import 'login/login_trust_badges.dart';
import 'login/google_sign_in_button.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Ambient Hero Logo Section
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DueVaultLogo(size: 96, showGlow: true),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'Due',
                          style: AppTypography.displayLarge(AppColors.textPrimary(isDark)).copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        Text(
                          'Vault',
                          style: AppTypography.displayLarge(AppColors.emerald500).copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Smart, private tracking for your\nbills and vital documents.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium(AppColors.textSecondary(isDark)).copyWith(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Trust Badges
              LoginTrustBadges(isDark: isDark),

              const Spacer(),

              // Google Sign In Button
              GoogleSignInButton(
                isDark: isDark,
                onTap: () => AuthFlowHelper.handleGoogleSignIn(context, ref, isDark),
              ),
              const SizedBox(height: 12),

              // Continue as Guest Button
              SecondaryButton(
                label: 'Continue as Guest (Offline Vault)',
                icon: Icons.lock_open_rounded,
                onPressed: () async {
                  await HapticFeedback.mediumImpact();
                  await AuthFlowHelper.completeOnboarding(ref, isGuest: true);
                },
              ),

              const SizedBox(height: 16),

              // Subtext Guarantee
              Text(
                'No account required to use offline • 100% Free',
                textAlign: TextAlign.center,
                style: AppTypography.caption(AppColors.textSecondary(isDark)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
