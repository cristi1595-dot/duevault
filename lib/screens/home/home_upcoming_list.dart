import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vault_item.dart';
import '../../providers/vault_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/global_components.dart';
import '../../theme/app_theme.dart';
import '../item_detail_screen.dart';

class HomeUpcomingList extends ConsumerWidget {
  final ScrollController scrollController;

  const HomeUpcomingList({
    super.key,
    required this.scrollController,
  });

  Widget _buildGroupHeader({
    required BuildContext context,
    required String title,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary(isDark),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 0.75,
              ),
            ),
            child: Text(
              '$count ${count == 1 ? "item" : "items"}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSection({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required List<VaultItem> items,
    required Color color,
    required Currency currency,
    required bool isDark,
  }) {
    if (items.isEmpty) return const [];
    return [
      _buildGroupHeader(
        context: context,
        title: title,
        count: items.length,
        color: color,
        isDark: isDark,
      ),
      ...items.asMap().entries.map(
        (entry) {
          final index = entry.key;
          final item = entry.value;
          return VaultItemTile(
            item: item,
            currency: currency,
            isHomeScreen: true,
            isFirst: index == 0,
            isLast: index == items.length - 1,
            showDivider: index < items.length - 1,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
              );
            },
            onCheckPressed: () {
              HapticFeedback.mediumImpact();
              final notifier = ref.read(vaultProvider.notifier);
              final nextPaidState = !item.isPaid;
              notifier.updatePaidStatus(item.id, nextPaidState);
              final name = item.title.isEmpty
                  ? (item.itemType == 'Bill' ? 'Bill' : 'Document')
                  : item.title;
              final actionText = nextPaidState
                  ? (item.itemType == 'Bill' ? 'marked as paid' : 'marked as renewed')
                  : (item.itemType == 'Bill' ? 'marked as unpaid' : 'marked as not renewed');
              VaultSnackBar.show(
                message: '$name $actionText',
                actionLabel: 'UNDO',
                backgroundColor: AppColors.emerald500,
                onAction: () => notifier.updatePaidStatus(item.id, !nextPaidState),
              );
            },
          );
        },
      ),
      const SizedBox(height: AppSpacing.xs),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultItems = ref.watch(vaultProvider);
    final currency = ref.watch(currencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Upcoming list: sorted by dueDate (defensively deduplicated)
    final seenSignatures = <String>{};
    final allUpcoming = <VaultItem>[];
    final sortedCandidates = vaultItems
        .where(
          (item) => !item.isArchived && !item.isDeleted && item.dueDate != null,
        )
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    for (final item in sortedCandidates) {
      final normTitle = item.title.trim().toLowerCase();
      final type = item.itemType ?? 'Bill';
      final dueStr = '${item.dueDate!.year}-${item.dueDate!.month}-${item.dueDate!.day}';
      final amtStr = item.amount != null ? item.amount!.toStringAsFixed(2) : '';
      final sig = '$normTitle|$type|$dueStr|$amtStr';
      if (seenSignatures.add(sig)) {
        allUpcoming.add(item);
      }
    }

    int getDaysLeft(DateTime dueDate) {
      final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
      return due.difference(today).inDays;
    }

    final overdueItems = allUpcoming
        .where((item) => (item.isOverdue || getDaysLeft(item.dueDate!) < 0) && !item.isPaid)
        .toList();

    final nonOverdueItems = allUpcoming
        .where((item) => !overdueItems.contains(item))
        .toList();

    final thisWeekItems = nonOverdueItems
        .where((item) => getDaysLeft(item.dueDate!) <= 7)
        .toList();

    final upcomingItems = nonOverdueItems
        .where((item) => getDaysLeft(item.dueDate!) > 7)
        .toList();

    if (vaultItems.isEmpty) {
      return const EmptyState();
    }

    return ListView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.xxs,
        AppSpacing.base,
        140,
      ),
      children: [
        if (allUpcoming.isEmpty)
          BentoCard(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xxl,
              horizontal: AppSpacing.base,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.emerald500.withValues(alpha: isDark ? 0.08 : 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.emerald500.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        size: 36,
                        color: isDark ? AppColors.emerald400 : AppColors.emerald600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'All caught up! No items due.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You have no urgent bills or expiring documents.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else ...[
          if (overdueItems.isNotEmpty)
            ..._buildSection(
              context: context,
              ref: ref,
              title: 'Overdue',
              items: overdueItems,
              color: AppColors.statusUrgentText(isDark),
              currency: currency,
              isDark: isDark,
            ),
          if (thisWeekItems.isNotEmpty)
            ..._buildSection(
              context: context,
              ref: ref,
              title: 'This Week',
              items: thisWeekItems,
              color: AppColors.statusWarningText(isDark),
              currency: currency,
              isDark: isDark,
            ),
          if (upcomingItems.isNotEmpty)
            ..._buildSection(
              context: context,
              ref: ref,
              title: 'Upcoming',
              items: upcomingItems,
              color: isDark ? AppColors.slate300 : AppColors.slate700,
              currency: currency,
              isDark: isDark,
            ),
        ],
      ],
    );
  }
}
