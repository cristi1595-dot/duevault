import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vault_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/global_components.dart';
import '../../widgets/vault/vault_search_and_sort.dart';
import '../../widgets/vault/vault_list_builder.dart';
import '../../theme/app_theme.dart';
import '../../models/vault_item.dart';

class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SortOption _sortBy = SortOption.date;
  bool _sortAscending = false; // newest first by default in history

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _togglePaidStatus(int id, bool isPaid, String title, String actionText) {
    final notifier = ref.read(vaultProvider.notifier);
    notifier.updatePaidStatus(id, isPaid);

    VaultSnackBar.show(
      message: '$title $actionText',
      actionLabel: 'UNDO',
      backgroundColor: AppTheme.safeGreen,
      onAction: () => notifier.updatePaidStatus(id, !isPaid),
    );
  }

  List<VaultItem> _getHistoryItems(List<VaultItem> allItems) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    var history = allItems.where((item) {
      if (item.isDeleted) return false;
      final isExpired = item.dueDate != null && item.dueDate!.isBefore(today);
      return item.isArchived || (item.isPaid && isExpired);
    }).toList();

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      history = history.where((item) {
        return item.title.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query) ||
            (item.notes?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    history.sort((a, b) {
      int result;
      switch (_sortBy) {
        case SortOption.date:
          if (a.dueDate == null && b.dueDate == null) {
            result = 0;
          } else if (a.dueDate == null) {
            result = 1;
          } else if (b.dueDate == null) {
            result = -1;
          } else {
            result = a.dueDate!.compareTo(b.dueDate!);
          }
          break;
        case SortOption.name:
          result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case SortOption.amount:
          result = (a.amount ?? 0).compareTo(b.amount ?? 0);
          break;
        case SortOption.category:
          result = a.category.toLowerCase().compareTo(b.category.toLowerCase());
          break;
      }
      return _sortAscending ? result : -result;
    });

    return history;
  }

  @override
  Widget build(BuildContext context) {
    final vaultItems = ref.watch(vaultProvider);
    final currency = ref.watch(currencyProvider);
    final historyItems = _getHistoryItems(vaultItems);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Arhivă & Istoric',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          VaultSearchAndSort(
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            sortBy: _sortBy,
            sortAscending: _sortAscending,
            onSortSelected: (option) {
              setState(() {
                if (_sortBy == option) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = option;
                  _sortAscending = false;
                }
              });
            },
          ),
          const SizedBox(height: 6),
          Expanded(
            child: VaultListBuilder(
              items: historyItems,
              currency: currency,
              onPaidStatusToggle: _togglePaidStatus,
            ),
          ),
        ],
      ),
    );
  }
}
