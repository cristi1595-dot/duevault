import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Text(
              '$count ${count == 1 ? "item" : "items"}',
              style: TextStyle(
                fontSize: 12,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultItems = ref.watch(vaultProvider);
    final currency = ref.watch(currencyProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Upcoming list: Both paid and unpaid items sorted by dueDate
    final allUpcoming = vaultItems
        .where(
          (item) => !item.isArchived && item.dueDate != null,
        )
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    int getDaysLeft(DateTime dueDate) {
      final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
      return due.difference(today).inDays;
    }

    final upcoming7Days =
        allUpcoming.where((item) => getDaysLeft(item.dueDate!) <= 7).toList();
    final upcoming30Days = allUpcoming.where((item) {
      final days = getDaysLeft(item.dueDate!);
      return days > 7 && days <= 30;
    }).toList();
    final upcomingLater =
        allUpcoming.where((item) => getDaysLeft(item.dueDate!) > 30).toList();

    if (vaultItems.isEmpty) {
      return const EmptyState();
    }

    return ListView(
      controller: scrollController,
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
            _buildGroupHeader(
              'Next 7 Days',
              upcoming7Days.length,
              upcoming7Days.any((item) => getDaysLeft(item.dueDate!) <= 3)
                  ? AppTheme.urgentRed
                  : AppTheme.warningYellow,
            ),
            ...upcoming7Days.map(
              (item) => VaultItemTile(
                item: item,
                currency: currency,
                isHomeScreen: true,
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
          ],
          if (upcoming30Days.isNotEmpty) ...[
            _buildGroupHeader(
              'Next 30 Days',
              upcoming30Days.length,
              AppTheme.safeGreen,
            ),
            ...upcoming30Days.map(
              (item) => VaultItemTile(
                item: item,
                currency: currency,
                isHomeScreen: true,
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
          ],
          if (upcomingLater.isNotEmpty) ...[
            _buildGroupHeader(
              'Later',
              upcomingLater.length,
              AppTheme.safeGreen,
            ),
            ...upcomingLater.map(
              (item) => VaultItemTile(
                item: item,
                currency: currency,
                isHomeScreen: true,
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
          ],
        ]
      ],
    );
  }
}
