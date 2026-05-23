import 'package:flutter/material.dart';
import '../../models/vault_item.dart';
import '../../providers/currency_provider.dart';
import '../../theme/app_theme.dart';
import '../global_components.dart';

class VaultListBuilder extends StatelessWidget {
  final List<VaultItem> items;
  final Currency currency;
  final Function(int id, bool isPaid, String title, String actionText) onPaidStatusToggle;

  const VaultListBuilder({
    super.key,
    required this.items,
    required this.currency,
    required this.onPaidStatusToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: AppTheme.primaryAction.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return VaultItemTile(
          item: item,
          currency: currency,
          onCheckPressed: item.isArchived
              ? null
              : () {
                  final nextStatus = !item.isPaid;
                  final actionText = nextStatus
                      ? (item.itemType == 'Bill' ? 'marked as paid' : 'marked as renewed')
                      : (item.itemType == 'Bill' ? 'marked as unpaid' : 'marked as not renewed');
                  onPaidStatusToggle(item.id, nextStatus, item.title.isEmpty ? item.category : item.title, actionText);
                },
        );
      },
    );
  }
}
