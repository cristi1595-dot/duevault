import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vault_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/currency_provider.dart';
import '../../widgets/global_components.dart';
import '../../widgets/vault/vault_search_and_sort.dart';
import '../../widgets/vault/vault_list_builder.dart';
import '../../theme/app_theme.dart';
import '../../models/vault_item.dart';
import '../../providers/category_provider.dart';
import '../../widgets/categories/category_filter_bar.dart';

enum BillFilterMode { unpaid, paid, all }

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  BillFilterMode _filterMode = BillFilterMode.unpaid;
  String _searchQuery = '';
  SortOption _sortBy = SortOption.date;
  bool _sortAscending = true;

  @override
  void dispose() {
    _scrollController.dispose();
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

  List<VaultItem> _getFilteredAndSortedBills(
    List<VaultItem> allItems,
    String? selectedCategory,
  ) {
    // 1. Only Bills & Not Archived
    var bills = allItems.where((item) {
      if (item.itemType != 'Bill' || item.isArchived || item.isDeleted) {
        return false;
      }
      return true;
    }).toList();

    // 2. Filter mode (unpaid, paid, all)
    if (_filterMode == BillFilterMode.unpaid) {
      bills = bills.where((item) => !item.isPaid).toList();
    } else if (_filterMode == BillFilterMode.paid) {
      bills = bills.where((item) => item.isPaid).toList();
    }

    // 3. Category Filter
    if (selectedCategory != null) {
      bills = bills
          .where(
            (item) =>
                item.category.toLowerCase() == selectedCategory.toLowerCase(),
          )
          .toList();
    }

    // 4. Search Filter
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      bills = bills.where((item) {
        final matchesTitle = item.title.toLowerCase().contains(query);
        final matchesCat = item.category.toLowerCase().contains(query);
        final matchesNotes = item.notes?.toLowerCase().contains(query) ?? false;
        final matchesAmount = item.amount != null &&
            item.amount.toString().contains(query);
        return matchesTitle || matchesCat || matchesNotes || matchesAmount;
      }).toList();
    }

    // 5. Sort
    bills.sort((a, b) {
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

    return bills;
  }

  @override
  Widget build(BuildContext context) {
    final vaultItems = ref.watch(vaultProvider);
    final currency = ref.watch(currencyProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to tab selection to scroll to top
    ref.listen(bottomNavIndexProvider, (previous, next) {
      if (next == 1 && _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        ref.read(navBarVisibleProvider.notifier).state = true;
      }
    });

    final filteredBills = _getFilteredAndSortedBills(
      vaultItems,
      selectedCategory,
    );

    // Compute bill summary stats
    final activeBills = vaultItems.where((i) => i.itemType == 'Bill' && !i.isArchived && !i.isDeleted).toList();
    final unpaidBills = activeBills.where((i) => !i.isPaid).toList();
    final totalUnpaidAmount = unpaidBills.fold(0.0, (sum, i) => sum + (i.amount ?? 0.0));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAction.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppTheme.primaryAction,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Facturi',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                letterSpacing: -0.4,
                              ),
                        ),
                        Text(
                          unpaidBills.isEmpty
                              ? 'Toate facturile sunt plătite'
                              : 'De plată: ${currency.formatAmount(totalUnpaidAmount)} (${unpaidBills.length})',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: unpaidBills.isEmpty
                                ? AppTheme.safeGreen
                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Segmented Filter Bar: De plată / Plătite / Toate
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B1F27) : const Color(0xFFE9EEF4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildSegmentButton(
                      label: 'De plată (${unpaidBills.length})',
                      mode: BillFilterMode.unpaid,
                      isDark: isDark,
                    ),
                    _buildSegmentButton(
                      label: 'Plătite',
                      mode: BillFilterMode.paid,
                      isDark: isDark,
                    ),
                    _buildSegmentButton(
                      label: 'Toate',
                      mode: BillFilterMode.all,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),

            // Search & Sort Bar
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
                    _sortAscending = true;
                  }
                });
              },
            ),

            // Category Filter Pills
            CategoryFilterBar(
              items: activeBills,
              itemTypeFilter: 'Bill',
            ),

            const SizedBox(height: 4),

            // Bills List
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    final delta = notification.scrollDelta ?? 0;
                    if (delta.abs() > 2) {
                      ref.read(navBarVisibleProvider.notifier).state = false;
                    }
                  }
                  if (notification is ScrollEndNotification) {
                    ref.read(navBarVisibleProvider.notifier).state = true;
                  }
                  return false;
                },
                child: VaultListBuilder(
                  items: filteredBills,
                  currency: currency,
                  scrollController: _scrollController,
                  onPaidStatusToggle: _togglePaidStatus,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required BillFilterMode mode,
    required bool isDark,
  }) {
    final isSelected = _filterMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterMode = mode),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF2B3240) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
          ),
        ),
      ),
    );
  }
}
