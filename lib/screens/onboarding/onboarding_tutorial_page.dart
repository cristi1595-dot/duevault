import 'package:flutter/material.dart';
import '../../widgets/global_components.dart';

import 'onboarding_header.dart';

class OnboardingTutorialPage extends StatelessWidget {
  final VoidCallback onContinue;

  const OnboardingTutorialPage({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          children: [
            const OnboardingHeader(),
            const SizedBox(height: 8),
            // Large Full-Width Image
            Image.asset(
              'assets/images/dashboard_tutorial.png',
              height: 520,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Continue',
              icon: Icons.arrow_forward,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
