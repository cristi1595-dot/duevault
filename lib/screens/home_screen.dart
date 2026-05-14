import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vault_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/currency_provider.dart';
import '../widgets/global_components.dart';
import '../theme/app_theme.dart';
import 'item_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultItems = ref.watch(vaultProvider);
    final currency = ref.watch(currencyProvider);

    // Calculate Stats
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next7Days = today.add(const Duration(days: 7));
    final next30Days = today.add(const Duration(days: 30));

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

    final upcomingBills = vaultItems.where((item) {
      if (item.itemType != 'Bill' || item.isPaid || item.dueDate == null) {
        return false;
      }
      final due = DateTime(
        item.dueDate!.year,
        item.dueDate!.month,
        item.dueDate!.day,
      );
      return (due.isBefore(next7Days) || due.isAtSameMomentAs(next7Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final totalDue7Days = upcomingBills.fold(
      0.0,
      (sum, item) => sum + (item.amount ?? 0),
    );

    final items30Days = vaultItems.where((item) {
      if (item.itemType != 'Bill' || item.isPaid || item.dueDate == null) {
        return false;
      }
      final due = DateTime(
        item.dueDate!.year,
        item.dueDate!.month,
        item.dueDate!.day,
      );
      return (due.isBefore(next30Days) || due.isAtSameMomentAs(next30Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final totalDue30Days = items30Days.fold(
      0.0,
      (sum, item) => sum + (item.amount ?? 0),
    );

    final totalDueOverdue = overdueBills.fold(
      0.0,
      (sum, item) => sum + (item.amount ?? 0),
    );

    // Upcoming list: ONLY UNPAID items sorted by dueDate
    final allUpcoming =
        vaultItems
            .where(
              (item) =>
                  !item.isArchived && !item.isPaid && item.dueDate != null,
            )
            .toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    final next3Days = today.add(const Duration(days: 3));

    final items3Days = vaultItems.where((item) {
      if (item.itemType != 'Bill' || item.isPaid || item.dueDate == null) {
        return false;
      }
      final due = DateTime(
        item.dueDate!.year,
        item.dueDate!.month,
        item.dueDate!.day,
      );
      return (due.isBefore(next3Days) || due.isAtSameMomentAs(next3Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    // Calculate Document Urgency (excluding already renewed/paid ones)
    final expiredDocs7Days = vaultItems.where((item) {
      if (item.itemType != 'Document' ||
          item.isArchived ||
          item.isPaid ||
          item.dueDate == null) {
        return false;
      }
      final due = DateTime(
        item.dueDate!.year,
        item.dueDate!.month,
        item.dueDate!.day,
      );
      return (due.isBefore(next7Days) || due.isAtSameMomentAs(next7Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final expiredDocs3Days = vaultItems.where((item) {
      if (item.itemType != 'Document' ||
          item.isArchived ||
          item.isPaid ||
          item.dueDate == null) {
        return false;
      }
      final due = DateTime(
        item.dueDate!.year,
        item.dueDate!.month,
        item.dueDate!.day,
      );
      return (due.isBefore(next3Days) || due.isAtSameMomentAs(next3Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    final expiredDocs30Days = vaultItems.where((item) {
      if (item.itemType != 'Document' ||
          item.isArchived ||
          item.isPaid ||
          item.dueDate == null) {
        return false;
      }
      final due = DateTime(
        item.dueDate!.year,
        item.dueDate!.month,
        item.dueDate!.day,
      );
      return (due.isBefore(next30Days) || due.isAtSameMomentAs(next30Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).toList();

    // Determine card color based on COMBINED urgency
    late Color cardColor;
    late Color amountColor;

    final hasCritical = items3Days.isNotEmpty || expiredDocs3Days.isNotEmpty;
    final hasWarning = upcomingBills.isNotEmpty || expiredDocs7Days.isNotEmpty;
    final hasSafe = items30Days.isNotEmpty || expiredDocs30Days.isNotEmpty;

    if (hasCritical) {
      cardColor = AppTheme.urgentRed.withValues(
        alpha: 0.08,
      ); // Lighter, more pleasant
      amountColor = AppTheme.urgentRed;
    } else if (hasWarning) {
      cardColor = AppTheme.warningYellow.withValues(alpha: 0.08); // Lighter
      amountColor = AppTheme.warningYellow;
    } else if (hasSafe) {
      cardColor = AppTheme.safeGreen.withValues(alpha: 0.08); // Lighter
      amountColor = AppTheme.safeGreen;
    } else {
      cardColor = AppTheme.safeGreen.withValues(
        alpha: 0.04,
      ); // Very subtle for zero state
      amountColor = AppTheme.safeGreen.withValues(alpha: 0.4);
    }

    // Independent Document Box Color
    late Color docBoxColor;
    if (expiredDocs3Days.isNotEmpty) {
      docBoxColor = AppTheme.urgentRed;
    } else if (expiredDocs7Days.isNotEmpty) {
      docBoxColor = AppTheme.warningYellow;
    } else {
      // Darker/More saturated green for 0 docs as requested
      docBoxColor = const Color(
        0xFF059669,
      ); // Emerald-ish, darker than safeGreen
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Custom AppBar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAction.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryAction.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 28, // Slightly larger for better legibility
                            height: 28,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DueVault',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          Text(
                            'Smart Bill Manager',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
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
                          children: [
                            if (user == null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
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
                                      : Theme.of(
                                          context,
                                        ).dividerColor.withValues(alpha: 0.2),
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
                ],
              ),
              const SizedBox(height: 24),

              // 2. Critical Alert Card (if overdue or expired)
              if (overdueBills.isNotEmpty) ...[
                CriticalAlertCard(
                  message:
                      '${overdueBills.length} Overdue Payment: ${currency.formatAmount(totalDueOverdue)}',
                  onTap: () {
                    // Navigate to filter or detail
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (expiredDocs.isNotEmpty) ...[
                CriticalAlertCard(
                  message:
                      '${expiredDocs.length} Expired Document${expiredDocs.length > 1 ? 's' : ''}: Needs Attention',
                  onTap: () {
                    // Navigate to filter or detail
                  },
                ),
                const SizedBox(height: 16),
              ],

              // 3. Financial Bento Card
              BentoCard(
                color: cardColor,
                padding: const EdgeInsets.all(12.0), // Reduced from default 16
                child: SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BILLS • NEXT 7 DAYS',
                              style: AppTheme.labelCapsStyle(context).copyWith(fontSize: 9), // Slightly smaller label
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currency.formatAmount(totalDue7Days),
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    color: amountColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 40,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '30-day total: ${currency.formatAmount(totalDue30Days)}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14, // Increased by 2px
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ), // Reduced padding
                        decoration: BoxDecoration(
                          color: docBoxColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  color: docBoxColor.withValues(alpha: 0.8),
                                  size: 32, // Decreased from 34
                                ),
                                Positioned(
                                  right: -8,
                                  top: -8,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF059669),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.surface,
                                        width: 1.5, // Thinner border to match smaller icon
                                      ),
                                    ),
                                    child: const Text(
                                      'D',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11, // Slightly smaller
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${expiredDocs7Days.length}',
                              style: TextStyle(
                                color: docBoxColor,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                            if (expiredDocs30Days.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  '${expiredDocs30Days.length}',
                                  style: TextStyle(
                                    color: docBoxColor.withValues(alpha: 0.7),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Upcoming',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),

              // 5. List
              if (allUpcoming.isEmpty)
                const BentoCard(
                  child: SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('All caught up! No bills due.'),
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allUpcoming.length > 10 ? 10 : allUpcoming.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final item = allUpcoming[index];
                    return VaultItemTile(
                      item: item,
                      currency: currency,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemDetailScreen(item: item),
                          ),
                        );
                      },
                      onCheckPressed: () {
                        final notifier = ref.read(vaultProvider.notifier);
                        notifier.updatePaidStatus(item.id, true);

                        final isExpired = item.dueDate != null &&
                            item.dueDate!.isBefore(
                              DateTime(
                                DateTime.now().year,
                                DateTime.now().month,
                                DateTime.now().day,
                              ),
                            );

                        final destination =
                            isExpired ? 'Archive' : 'Vault';

                        final name = item.title.isEmpty ? item.category : item.title;
                        VaultSnackBar.show(
                          message: '$name sent to $destination',
                          actionLabel: 'UNDO',
                          backgroundColor: AppTheme.safeGreen,
                          onAction: () =>
                              notifier.updatePaidStatus(item.id, false),
                        );
                      },
                    );
                  },
                ),
              const SizedBox(height: 100), // Padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }
}
