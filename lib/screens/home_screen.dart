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

    final billCritical = overdueBills.isNotEmpty || items3Days.isNotEmpty;
    final billWarning = upcomingBills.isNotEmpty;
    final billSafe = items30Days.isNotEmpty;

    if (billCritical) {
      cardColor = AppTheme.urgentRed.withValues(
        alpha: 0.12,
      ); // Slightly more prominent red
      amountColor = AppTheme.urgentRed;
    } else if (billWarning) {
      cardColor = AppTheme.warningYellow.withValues(alpha: 0.08);
      amountColor = AppTheme.warningYellow;
    } else if (billSafe) {
      cardColor = AppTheme.safeGreen.withValues(alpha: 0.08);
      amountColor = AppTheme.safeGreen;
    } else {
      cardColor = AppTheme.safeGreen.withValues(alpha: 0.04);
      amountColor = AppTheme.safeGreen.withValues(alpha: 0.4);
    }

    // Independent Document Box Color
    late Color docBoxColor;
    final bool docCritical =
        expiredDocs.isNotEmpty || expiredDocs3Days.isNotEmpty;
    final bool docWarning = expiredDocs7Days.isNotEmpty;

    if (docCritical) {
      docBoxColor = AppTheme.urgentRed;
    } else if (docWarning) {
      docBoxColor = AppTheme.warningYellow;
    } else {
      // Darker/More saturated green for 0 docs as requested
      docBoxColor = const Color(0xFF059669);
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
                              size: 44,
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
                    color: cardColor,
                    padding: const EdgeInsets.all(2.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TOTAL DUE • NEXT 7 DAYS',
                                  style: AppTheme.labelCapsStyle(
                                    context,
                                  ).copyWith(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currency.formatAmount(totalDue7Days),
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(
                                        color: amountColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 40,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '30-day total: ${currency.formatAmount(totalDue30Days)}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(2.0),
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
                                      size: 32,
                                    ),
                                    Positioned(
                                      right: -8,
                                      bottom: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: docBoxColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppTheme.surface,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const Text(
                                          'D',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${expiredDocs.length + expiredDocs7Days.length}',
                                  style: TextStyle(
                                    color: docBoxColor,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                                if (expiredDocs30Days.isNotEmpty ||
                                    expiredDocs.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(
                                      '${expiredDocs.length + expiredDocs30Days.length}',
                                      style: TextStyle(
                                        color: docBoxColor.withValues(
                                          alpha: 0.7,
                                        ),
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
                ],
              ),
            ),

            // 2. SCROLLABLE UPCOMING SECTION
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 100),
                children: [
                  Text(
                    'Upcoming',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
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
                    ...allUpcoming
                        .take(10)
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: VaultItemTile(
                              item: item,
                              currency: currency,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ItemDetailScreen(item: item),
                                  ),
                                );
                              },
                              onCheckPressed: () {
                                final notifier = ref.read(
                                  vaultProvider.notifier,
                                );
                                notifier.updatePaidStatus(item.id, true);

                                final isExpired =
                                    item.dueDate != null &&
                                    item.dueDate!.isBefore(today);

                                final destination = isExpired
                                    ? 'Archive'
                                    : 'Vault';
                                final name = item.title.isEmpty
                                    ? item.category
                                    : item.title;
                                VaultSnackBar.show(
                                  message: '$name sent to $destination',
                                  actionLabel: 'UNDO',
                                  backgroundColor: AppTheme.safeGreen,
                                  onAction: () =>
                                      notifier.updatePaidStatus(item.id, false),
                                );
                              },
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
