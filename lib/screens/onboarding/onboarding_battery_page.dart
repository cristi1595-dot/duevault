import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/global_components.dart';
import 'onboarding_header.dart';
import 'onboarding_ripple_illustration.dart';

class OnboardingBatteryPage extends StatelessWidget {
  final VoidCallback onGuaranteeAlerts;
  final VoidCallback onSkipForNow;

  const OnboardingBatteryPage({
    super.key,
    required this.onGuaranteeAlerts,
    required this.onSkipForNow,
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
              color: AppTheme.safeGreen,
              icon: Icons.battery_charging_full_rounded,
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
              onPressed: onGuaranteeAlerts,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onSkipForNow,
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
}
