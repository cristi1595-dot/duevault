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

  Widget _buildGroupHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
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
            HapticFeedback.mediumImpact();
            final notifier = ref.read(vaultProvider.notifier);
            final nextPaidState = !item.isPaid;
            notifier.updatePaidStatus(item.id, nextPaidState);
            final name = item.title.isEmpty ? (item.itemType == 'Bill' ? 'Bill' : 'Document') : item.title;
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
                      const SizedBox(height: 8),
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
          if (overdueItems.isNotEmpty)
            ..._buildSection(
              context: context,
              ref: ref,
              title: 'Overdue',
              items: overdueItems,
              color: AppTheme.urgentRed,
              currency: currency,
            ),
          if (thisWeekItems.isNotEmpty)
            ..._buildSection(
              context: context,
              ref: ref,
              title: 'This Week',
              items: thisWeekItems,
              color: const Color(0xFFF59E0B),
              currency: currency,
            ),
          if (upcomingItems.isNotEmpty)
            ..._buildSection(
              context: context,
              ref: ref,
              title: 'Upcoming',
              items: upcomingItems,
              color: isDark ? Colors.white : const Color(0xFF475569),
              currency: currency,
            ),
        ],
      ],
    );
  }
}
