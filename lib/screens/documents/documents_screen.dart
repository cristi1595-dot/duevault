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

enum DocFilterMode { all, expiring, expired, permanent }

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  DocFilterMode _filterMode = DocFilterMode.all;
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

  List<VaultItem> _getFilteredAndSortedDocs(
    List<VaultItem> allItems,
    String? selectedCategory,
  ) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final in30Days = today.add(const Duration(days: 30));

    // 1. Only Documents & Not Archived/Deleted
    var docs = allItems.where((item) {
      if (item.itemType != 'Document' || item.isArchived || item.isDeleted) {
        return false;
      }
      return true;
    }).toList();

    // 2. Filter mode
    if (_filterMode == DocFilterMode.expiring) {
      docs = docs.where((item) {
        if (item.dueDate == null || item.isPaid) return false;
        final due = DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day);
        return (due.isBefore(in30Days) || due.isAtSameMomentAs(in30Days)) &&
            (due.isAfter(today) || due.isAtSameMomentAs(today));
      }).toList();
    } else if (_filterMode == DocFilterMode.expired) {
      docs = docs.where((item) {
        if (item.dueDate == null) return false;
        final due = DateTime(item.dueDate!.year, item.dueDate!.month, item.dueDate!.day);
        return due.isBefore(today);
      }).toList();
    } else if (_filterMode == DocFilterMode.permanent) {
      docs = docs.where((item) => item.dueDate == null).toList();
    }

    // 3. Category Filter
    if (selectedCategory != null) {
      docs = docs
          .where(
            (item) =>
                item.category.toLowerCase() == selectedCategory.toLowerCase(),
          )
          .toList();
    }

    // 4. Search Filter
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      docs = docs.where((item) {
        final matchesTitle = item.title.toLowerCase().contains(query);
        final matchesCat = item.category.toLowerCase().contains(query);
        final matchesNotes = item.notes?.toLowerCase().contains(query) ?? false;
        return matchesTitle || matchesCat || matchesNotes;
      }).toList();
    }

    // 5. Sort
    docs.sort((a, b) {
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
          result = 0;
          break;
        case SortOption.category:
          result = a.category.toLowerCase().compareTo(b.category.toLowerCase());
          break;
      }
      return _sortAscending ? result : -result;
    });

    return docs;
  }

  @override
  Widget build(BuildContext context) {
    final vaultItems = ref.watch(vaultProvider);
    final currency = ref.watch(currencyProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to tab selection to scroll to top
    ref.listen(bottomNavIndexProvider, (previous, next) {
      if (next == 2 && _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        ref.read(navBarVisibleProvider.notifier).state = true;
      }
    });

    final filteredDocs = _getFilteredAndSortedDocs(
      vaultItems,
      selectedCategory,
    );

    // Compute document summary stats
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final in30Days = today.add(const Duration(days: 30));

    final activeDocs = vaultItems.where((i) => i.itemType == 'Document' && !i.isArchived && !i.isDeleted).toList();
    final expiringCount = activeDocs.where((i) {
      if (i.dueDate == null || i.isPaid) return false;
      final due = DateTime(i.dueDate!.year, i.dueDate!.month, i.dueDate!.day);
      return (due.isBefore(in30Days) || due.isAtSameMomentAs(in30Days)) &&
          (due.isAfter(today) || due.isAtSameMomentAs(today));
    }).length;
    final expiredCount = activeDocs.where((i) {
      if (i.dueDate == null) return false;
      final due = DateTime(i.dueDate!.year, i.dueDate!.month, i.dueDate!.day);
      return due.isBefore(today);
    }).length;

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
                      color: AppTheme.accentPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.folder_shared_rounded,
                      color: AppTheme.accentPurple,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Documente',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                letterSpacing: -0.4,
                              ),
                        ),
                        Text(
                          expiringCount > 0
                              ? '$expiringCount ${expiringCount == 1 ? "document expiră" : "documente expiră"} în 30 de zile'
                              : (expiredCount > 0
                                  ? '$expiredCount documente expirate'
                                  : '${activeDocs.length} ${activeDocs.length == 1 ? "document activ" : "documente active"}'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: expiringCount > 0
                                ? AppTheme.warningYellow
                                : (expiredCount > 0
                                    ? AppTheme.urgentRed
                                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Segmented Filter Bar: Toate / Expiră curând / Expirate / Permanente
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
                      label: 'Toate (${activeDocs.length})',
                      mode: DocFilterMode.all,
                      isDark: isDark,
                    ),
                    _buildSegmentButton(
                      label: 'Expiră ($expiringCount)',
                      mode: DocFilterMode.expiring,
                      isDark: isDark,
                    ),
                    _buildSegmentButton(
                      label: 'Expirate',
                      mode: DocFilterMode.expired,
                      isDark: isDark,
                    ),
                    _buildSegmentButton(
                      label: 'Permanente',
                      mode: DocFilterMode.permanent,
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
              items: activeDocs,
              itemTypeFilter: 'Document',
            ),

            const SizedBox(height: 4),

            // Documents List
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
                  items: filteredDocs,
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
    required DocFilterMode mode,
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
              fontSize: 11.5,
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
