import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/global_components.dart';
import '../../providers/vault_provider.dart';
import '../../models/vault_item.dart';
import '../../screens/home/financial_bento_card.dart';
import '../../theme/app_theme.dart';
import 'onboarding_header.dart';

class MockOnboardingVaultNotifier extends VaultNotifier {
  @override
  List<VaultItem> build() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return [
      VaultItem()
        ..itemType = 'Bill'
        ..isPaid = false
        ..dueDate = today.add(const Duration(days: 5))
        ..amount = 45.20
        ..category = 'Utilities'
        ..title = 'Electricity Bill',
      VaultItem()
        ..itemType = 'Document'
        ..isPaid = false
        ..dueDate = today.add(const Duration(days: 4))
        ..category = 'Personal'
        ..title = 'Driver License',
    ];
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          children: [
            const OnboardingHeader(),
            const SizedBox(height: 12),
            
            // Live Interactive Dashboard Mockup
            ProviderScope(
              overrides: [
                vaultProvider.overrideWith(() => MockOnboardingVaultNotifier()),
              ],
              child: Container(
                height: 380,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMockHeader(context),
                      const FinancialBentoCard(),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'UPCOMING ITEMS',
                          style: AppTheme.labelCapsStyle(context).copyWith(
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildMockListItem(
                              context,
                              title: 'Electricity Bill',
                              category: 'Utilities',
                              daysLeft: 'Due in 5 days',
                              amount: '£45.20',
                              icon: Icons.power_rounded,
                              iconColor: Colors.amber,
                            ),
                            _buildMockListItem(
                              context,
                              title: 'Driver License',
                              category: 'Personal',
                              daysLeft: 'Expiring in 4 days',
                              amount: null,
                              icon: Icons.badge_rounded,
                              iconColor: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
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

  Widget _buildMockHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const DueVaultLogo(
                size: 40, // scaled down to prevent overflows
                showGlow: false,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DueVault',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 19,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Smart Bill Manager',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Profile Avatar Mockup
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Guest',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF2D333D) : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 12, // scaled down
                  backgroundColor: isDark ? const Color(0xFF1B1F26) : const Color(0xFFF1F5F9),
                  child: Icon(
                    Icons.person_outline,
                    size: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMockListItem(
    BuildContext context, {
    required String title,
    required String category,
    required String daysLeft,
    required String? amount,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1F26) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2D333D) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$category • $daysLeft',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (amount != null)
            Text(
              amount,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
