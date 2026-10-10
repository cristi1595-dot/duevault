import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_typography.dart';
import '../../widgets/primary_button.dart';
import 'onboarding_header.dart';

class OnboardingTutorialPage extends StatelessWidget {
  final VoidCallback onContinue;

  const OnboardingTutorialPage({
    super.key,
    required this.onContinue,
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
            const SizedBox(height: 28),

            // Living Interactive Bento Preview Widget
            _buildBentoPreview(context, isDark),

            const SizedBox(height: 28),

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
              'Track bills, invoices and vital documents in your private, encrypted vault.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(AppColors.textSecondary(isDark)).copyWith(
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // Primary Call to Action
            PrimaryButton(
              label: 'Get Started',
              icon: Icons.arrow_forward_rounded,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoPreview(BuildContext context, bool isDark) {
    final cardBg = AppColors.surface(isDark);
    final borderColor = AppColors.border(isDark);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: !isDark ? AppShadows.md : null,
      ),
      child: Column(
        children: [
          // Row 1: Sample Bill Item
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFFF59E0B),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Titles & Due badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Utility bill',
                        style: AppTypography.titleMedium(AppColors.textPrimary(isDark)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Due in 2 days',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount
                Text(
                  '€84.50',
                  style: AppTypography.titleMedium(AppColors.textPrimary(isDark)).copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          // Indented Divider
          Container(
            margin: const EdgeInsets.only(left: 72, right: 16),
            height: 0.8,
            color: isDark ? const Color(0xFF1E2838) : AppColors.slate200,
          ),

          // Row 2: Sample Document Item
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.emerald500.withValues(alpha: isDark ? 0.15 : 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.badge_outlined,
                      color: AppColors.emerald500,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Titles & status badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Passport',
                        style: AppTypography.titleMedium(AppColors.textPrimary(isDark)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.emerald500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.emerald500.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.emerald400 : AppColors.emerald700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Shield status indicator
                Icon(
                  Icons.verified_user_rounded,
                  size: 20,
                  color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                ),
              ],
            ),
          ),

          // Bottom Trust Strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated(isDark),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.xl),
                bottomRight: Radius.circular(AppRadius.xl),
              ),
              border: Border(
                top: BorderSide(color: borderColor, width: 0.8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 13,
                  color: AppColors.textSecondary(isDark),
                ),
                const SizedBox(width: 6),
                Text(
                  'On-Device AES-256 Encryption',
                  style: AppTypography.caption(AppColors.textSecondary(isDark)).copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
