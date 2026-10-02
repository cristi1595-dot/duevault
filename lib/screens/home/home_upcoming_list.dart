import 'package:flutter/material.dart';
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

  Widget _buildGroupHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
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
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              '$count ${count == 1 ? "item" : "items"}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
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
  }) {
    if (items.isEmpty) return const [];
    return [
      _buildGroupHeader(title, items.length, color),
      ...items.map(
        (item) => VaultItemTile(
          item: item,
          currency: currency,
          isHomeScreen: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
            );
          },
          onCheckPressed: () {
            final notifier = ref.read(vaultProvider.notifier);
            final nextPaidState = !item.isPaid;
            notifier.updatePaidStatus(item.id, nextPaidState);
            final name = item.title.isEmpty ? item.category : item.title;
            final actionText = nextPaidState
                ? (item.itemType == 'Bill' ? 'marked as paid' : 'marked as renewed')
                : (item.itemType == 'Bill' ? 'marked as unpaid' : 'marked as not renewed');
            VaultSnackBar.show(
              message: '$name $actionText',
              actionLabel: 'UNDO',
              backgroundColor: AppTheme.safeGreen,
              onAction: () => notifier.updatePaidStatus(item.id, !nextPaidState),
            );
          },
        ),
      ),
      const SizedBox(height: 6),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultItems = ref.watch(vaultProvider);
    final currency = ref.watch(currencyProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Upcoming list: Both paid and unpaid items sorted by dueDate (defensively deduplicated)
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

    final urgentItems = allUpcoming
        .where((item) => item.isOverdue || getDaysLeft(item.dueDate!) <= 0)
        .toList();
    final thisWeekItems = allUpcoming
        .where((item) =>
            !urgentItems.contains(item) && getDaysLeft(item.dueDate!) <= 7)
        .toList();
    final thisMonthItems = allUpcoming.where((item) {
      final days = getDaysLeft(item.dueDate!);
      return days > 7 && days <= 30;
    }).toList();
    final laterItems =
        allUpcoming.where((item) => getDaysLeft(item.dueDate!) > 30).toList();

    if (vaultItems.isEmpty) {
      return const EmptyState();
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 140),
      children: [
        if (allUpcoming.isEmpty)
          BentoCard(
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 38,
                        color: AppTheme.safeGreen.withValues(alpha: 0.8),
                      ),
                      const Text(
                        'All caught up! No items due.',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else ...[
          ..._buildSection(
            context: context,
            ref: ref,
            title: 'Urgent / Due Today',
            items: urgentItems,
            color: AppTheme.urgentRed,
            currency: currency,
          ),
          ..._buildSection(
            context: context,
            ref: ref,
            title: 'This Week',
            items: thisWeekItems,
            color: const Color(0xFFF59E0B),
            currency: currency,
          ),
          ..._buildSection(
            context: context,
            ref: ref,
            title: 'Later This Month',
            items: thisMonthItems,
            color: AppTheme.safeGreen,
            currency: currency,
          ),
          ..._buildSection(
            context: context,
            ref: ref,
            title: 'Upcoming',
            items: laterItems,
            color: const Color(0xFF6366F1),
            currency: currency,
          ),
        ],
      ],
    );
  }
}
