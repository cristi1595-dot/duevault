import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vault_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/currency_provider.dart';
import '../widgets/global_components.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

enum SortOption { date, name, amount }

class _VaultScreenState extends ConsumerState<VaultScreen> {
  // Use PageController for infinite looping
  static const int _initialPageIndex = 4000;
  final PageController _pageController = PageController(
    initialPage: _initialPageIndex,
  );
  final TextEditingController _searchController = TextEditingController();

  int _currentPageIndex = _initialPageIndex;

  String _searchQuery = '';
  SortOption _sortBy = SortOption.date;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int get _activeTabIndex => _currentPageIndex % 4;

  Widget buildList(List<dynamic> items, Currency currency) {
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
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return VaultItemTile(
          item: item,
          currency: currency,
          onCheckPressed: item.isPaid || item.isArchived
              ? null
              : () {
                  final notifier = ref.read(vaultProvider.notifier);
                  notifier.updatePaidStatus(item.id, true);
                  final actionText = item.itemType == 'Bill'
                      ? 'Paid'
                      : 'Renewed';
                  VaultSnackBar.show(
                    message:
                        '${item.title.isEmpty ? item.category : item.title} $actionText',
                    actionLabel: 'UNDO',
                    backgroundColor: AppTheme.safeGreen,
                    onAction: () => notifier.updatePaidStatus(item.id, false),
                  );
                },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaultItems = ref.watch(vaultProvider);
    final currency = ref.watch(currencyProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final searchFiltered = vaultItems.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          (item.notes?.toLowerCase().contains(query) ?? false);
    }).toList();

    List<dynamic> getItemsForTab(int tabIndex) {
      return searchFiltered
          .where((item) {
            final isExpired =
                item.dueDate != null && item.dueDate!.isBefore(today);
            final shouldBeInHistory =
                item.isArchived || (item.isPaid && isExpired);

            if (tabIndex == 3) return shouldBeInHistory;
            if (shouldBeInHistory) return false;

            if (tabIndex == 1) return item.itemType == 'Bill';
            if (tabIndex == 2) return item.itemType == 'Document';
            return true;
          })
          .toList()
        ..sort((a, b) {
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
          }
          return _sortAscending ? result : -result;
        });
    }



    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            DueVaultLogo(
              size: 34,
              showGlow: false,
            ),
            SizedBox(width: 12),
            Text(
              'Vault',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final authState = ref.watch(authStateProvider);
                  final user = authState.valueOrNull;
                  final photoUrl = user?.photoURL;
                  return Row(
                    children: [
                      if (user == null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            'Guest',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).cardTheme.color,
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null
                            ? Icon(
                                Icons.person,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                                size: 18,
                              )
                            : null,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Tab Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Container(
              height: 42,
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  _buildTabPill(0, 'ALL'),
                  _buildTabPill(1, 'BILLS'),
                  _buildTabPill(2, 'DOCS'),
                  _buildTabPill(3, 'HISTORY'),
                ],
              ),
            ),
          ),

          // 2. Search & Sort
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withValues(alpha: 0.3),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withValues(alpha: 0.4),
                                  size: 16,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: PopupMenuButton<SortOption>(
                    icon: const Icon(
                      Icons.sort,
                      color: AppTheme.primaryAction,
                      size: 20,
                    ),
                    offset: const Offset(0, 50),
                    color: AppTheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (option) {
                      if (_sortBy == option) {
                        setState(() => _sortAscending = !_sortAscending);
                      } else {
                        setState(() {
                          _sortBy = option;
                          _sortAscending = true;
                        });
                      }
                    },
                    itemBuilder: (context) => [
                      _buildSortItem(
                        SortOption.date,
                        'Date',
                        Icons.calendar_today,
                      ),
                      _buildSortItem(
                        SortOption.name,
                        'Name',
                        Icons.sort_by_alpha,
                      ),
                      _buildSortItem(
                        SortOption.amount,
                        'Amount',
                        Icons.payments_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),



          const SizedBox(height: 4),

          // 4. INFINITE SWIPE View
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final tabIndex = index % 4;
                return buildList(getItemsForTab(tabIndex), currency);
              },
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<SortOption> _buildSortItem(
    SortOption value,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const Spacer(),
          if (_sortBy == value)
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: AppTheme.primaryAction,
            ),
        ],
      ),
    );
  }



  Widget _buildTabPill(int index, String label) {
    final isSelected = _activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Use our tracked index instead of controller.page for stability
          final current = _currentPageIndex;
          final currentTab = current % 4;
          int offset = index - currentTab;

          // Ensure we take the shortest path in the infinite loop
          if (offset > 2) offset -= 4;
          if (offset < -2) offset += 4;

          _pageController.animateToPage(
            current + offset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryAction : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryAction.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.black
                  : Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
