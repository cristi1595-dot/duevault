import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vault_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/global_components.dart';
import '../../widgets/duevault_logo.dart';
import '../../theme/app_theme.dart';
import '../settings_screen.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultItems = ref.watch(vaultProvider);
    final currency = ref.watch(currencyProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final overdueBills = vaultItems.where((item) {
      if (item.itemType != 'Bill' || item.isPaid || item.dueDate == null) {
        return false;
      }
      return item.dueDate!.isBefore(today);
    }).toList();

    final expiredDocs = vaultItems.where((item) {
      if (item.itemType != 'Document' ||
          item.isArchived ||
          item.dueDate == null) {
        return false;
      }
      return item.dueDate!.isBefore(today);
    }).toList();

    final totalDueOverdue = overdueBills.fold(
      0.0,
      (sum, item) => sum + (item.amount ?? 0),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DueVaultLogo(
                      size: 53,
                      showGlow: false,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DueVault',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                                letterSpacing: -0.5,
                                fontSize: 24,
                              ),
                        ),
                        Text(
                          'Smart Bill Manager',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodySmall?.color,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Flexible(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                  child: Consumer(
                    builder: (context, ref, child) {
                      final authState = ref.watch(authStateProvider);
                      final user = authState.valueOrNull;
                      final photoUrl = user?.photoURL;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (user == null)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 8.0,
                              ),
                              child: Text(
                                'Guest',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: user != null
                                    ? AppTheme.primaryAction
                                    : Theme.of(context).dividerColor
                                          .withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.1),
                              backgroundImage: photoUrl != null
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl == null
                                  ? Icon(
                                      Icons.person_outline,
                                      size: 20,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Alerts
          if (overdueBills.isNotEmpty) ...[
            CriticalAlertCard(
              message:
                  '${overdueBills.length} Overdue Payment: ${currency.formatAmount(totalDueOverdue)}',
              onTap: () {},
            ),
            const SizedBox(height: 8),
          ],
          if (expiredDocs.isNotEmpty) ...[
            CriticalAlertCard(
              message:
                  '${expiredDocs.length} Expired Document${expiredDocs.length > 1 ? 's' : ''}: Needs Attention',
              onTap: () {},
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
