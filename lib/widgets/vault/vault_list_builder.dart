import 'package:flutter/material.dart';
import '../../models/vault_item.dart';
import '../../providers/currency_provider.dart';
import '../global_components.dart';

class VaultListBuilder extends StatelessWidget {
  final List<VaultItem> items;
  final Currency currency;
  final ScrollController? scrollController;
  final Function(int id, bool isPaid, String title, String actionText) onPaidStatusToggle;

  const VaultListBuilder({
    super.key,
    required this.items,
    required this.currency,
    this.scrollController,
    required this.onPaidStatusToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState();
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 140),
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
