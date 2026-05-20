import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vault_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/currency_provider.dart';
import '../widgets/global_components.dart';
import '../widgets/duevault_logo.dart';
import '../theme/app_theme.dart';
import 'item_detail_screen.dart';
import 'settings_screen.dart';

import '../providers/navigation_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for tab changes to reset scroll position
    ref.listen(bottomNavIndexProvider, (previous, next) {
      if (next == 0 && _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

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

    final totalDueOverdue = overdueBills.fold(
      0.0,
      (sum, item) => sum + (item.amount ?? 0),
    );

    final totalDue7Days =
        (upcomingBills.fold(0.0, (sum, item) => sum + (item.amount ?? 0))) +
        totalDueOverdue;

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

    final totalDue30Days =
        (items30Days.fold(0.0, (sum, item) => sum + (item.amount ?? 0))) +
        totalDueOverdue;

    // Upcoming list: ONLY UNPAID items sorted by dueDate
    final allUpcoming =
        vaultItems
            .where(
              (item) =>
                  !item.isArchived && !item.isPaid && item.dueDate != null,
            )
            .toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    // Calculate Document Expirations
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

    // Check urgency states
    final totalDocs7Days = expiredDocs.length + expiredDocs7Days.length;
    final totalDocs30Days = expiredDocs.length + expiredDocs30Days.length;

    final has7DaysIssues = totalDue7Days > 0 || totalDocs7Days > 0;
    final has30DaysIssues = totalDue30Days > 0 || totalDocs30Days > 0;

    final Color bentoBgColor;
    final Color bentoBorderColor;

    if (has7DaysIssues) {
      bentoBgColor = AppTheme.urgentRed.withValues(alpha: 0.04);
      bentoBorderColor = AppTheme.urgentRed.withValues(alpha: 0.35);
    } else if (has30DaysIssues) {
      bentoBgColor = AppTheme.warningYellow.withValues(alpha: 0.04);
      bentoBorderColor = AppTheme.warningYellow.withValues(alpha: 0.35);
    } else {
      bentoBgColor = AppTheme.safeGreen.withValues(alpha: 0.04);
      bentoBorderColor = AppTheme.safeGreen.withValues(alpha: 0.35);
    }

    int getDaysLeft(DateTime dueDate) {
      final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
      return due.difference(today).inDays;
    }

    final upcoming7Days = allUpcoming.where((item) => getDaysLeft(item.dueDate!) <= 7).toList();
    final upcoming30Days = allUpcoming.where((item) {
      final days = getDaysLeft(item.dueDate!);
      return days > 7 && days <= 30;
    }).toList();
    final upcomingLater = allUpcoming.where((item) => getDaysLeft(item.dueDate!) > 30).toList();

    Widget buildGroupHeader(String title, int count, Color color) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 1.2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: color.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Text(
                '$count ${count == 1 ? "item" : "items"}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. FIXED HEADER SECTION
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
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

                  // Alerts & Bento Card (Fixed)
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

                  // Financial Bento Card
                  BentoCard(
                    color: bentoBgColor,
                    borderColor: bentoBorderColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    borderRadius: 14.0,
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ROW 1: 7 DAYS
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'BILLS • NEXT 7 DAYS',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currency.formatAmount(totalDue7Days),
                                      style: TextStyle(
                                        color: totalDue7Days > 0 ? AppTheme.urgentRed : AppTheme.safeGreen,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 24,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DOCS • NEXT 7 DAYS',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$totalDocs7Days',
                                      style: TextStyle(
                                        color: totalDocs7Days > 0 ? AppTheme.urgentRed : AppTheme.safeGreen,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 24,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Divider(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                              height: 1,
                            ),
                          ),
                          // ROW 2: 30 DAYS
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'BILLS • NEXT 30 DAYS',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currency.formatAmount(totalDue30Days),
                                      style: TextStyle(
                                        color: totalDue30Days > 0 ? AppTheme.warningYellow : AppTheme.safeGreen,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 19,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DOCS • NEXT 30 DAYS',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$totalDocs30Days',
                                      style: TextStyle(
                                        color: totalDocs30Days > 0 ? AppTheme.warningYellow : AppTheme.safeGreen,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 19,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. SCROLLABLE UPCOMING SECTION
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 100),
                children: [
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
                  else ...[
                    if (upcoming7Days.isNotEmpty) ...[
                      buildGroupHeader('Next 7 Days', upcoming7Days.length, AppTheme.urgentRed),
                      ...upcoming7Days.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: VaultItemTile(
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
                              final isExpired = item.dueDate != null && item.dueDate!.isBefore(today);
                              final destination = isExpired ? 'Archive' : 'Vault';
                              final name = item.title.isEmpty ? item.category : item.title;
                              VaultSnackBar.show(
                                message: '$name sent to $destination',
                                actionLabel: 'UNDO',
                                backgroundColor: AppTheme.safeGreen,
                                onAction: () => notifier.updatePaidStatus(item.id, false),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    if (upcoming30Days.isNotEmpty) ...[
                      buildGroupHeader('Next 30 Days', upcoming30Days.length, AppTheme.warningYellow),
                      ...upcoming30Days.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: VaultItemTile(
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
                              final isExpired = item.dueDate != null && item.dueDate!.isBefore(today);
                              final destination = isExpired ? 'Archive' : 'Vault';
                              final name = item.title.isEmpty ? item.category : item.title;
                              VaultSnackBar.show(
                                message: '$name sent to $destination',
                                actionLabel: 'UNDO',
                                backgroundColor: AppTheme.safeGreen,
                                onAction: () => notifier.updatePaidStatus(item.id, false),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    if (upcomingLater.isNotEmpty) ...[
                      buildGroupHeader('Later', upcomingLater.length, Colors.grey.shade500),
                      ...upcomingLater.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: VaultItemTile(
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
                              final isExpired = item.dueDate != null && item.dueDate!.isBefore(today);
                              final destination = isExpired ? 'Archive' : 'Vault';
                              final name = item.title.isEmpty ? item.category : item.title;
                              VaultSnackBar.show(
                                message: '$name sent to $destination',
                                actionLabel: 'UNDO',
                                backgroundColor: AppTheme.safeGreen,
                                onAction: () => notifier.updatePaidStatus(item.id, false),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
