import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vault_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/currency_provider.dart';
import '../widgets/global_components.dart';
import '../widgets/vault/vault_tab_switcher.dart';
import '../widgets/vault/vault_search_and_sort.dart';
import '../widgets/vault/vault_list_builder.dart';
import '../theme/app_theme.dart';
import '../models/vault_item.dart';
import 'settings_screen.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  static const int _initialPageIndex = 4000;
  final PageController _pageController = PageController(initialPage: _initialPageIndex);
  final TextEditingController _searchController = TextEditingController();

  int _currentPageIndex = _initialPageIndex;
  String _searchQuery = '';
  SortOption _sortBy = SortOption.date;
  bool _sortAscending = true;
  final List<ScrollController> _scrollControllers = List.generate(4, (_) => ScrollController());

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  int get _activeTabIndex => _currentPageIndex % 4;

  void _onTabTap(int index) {
    final current = _currentPageIndex;
    final currentTab = current % 4;
    int offset = index - currentTab;

    if (offset > 2) offset -= 4;
    if (offset < -2) offset += 4;

    _pageController.animateToPage(
      current + offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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

  List<VaultItem> _getFilteredAndSortedItems(List<VaultItem> allItems, int tabIndex) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // 1. Search Filter
    final searchFiltered = allItems.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          (item.notes?.toLowerCase().contains(query) ?? false);
    }).toList();

    // 2. Tab Filter
    final tabFiltered = searchFiltered.where((item) {
      final isExpired = item.dueDate != null && item.dueDate!.isBefore(today);
      final shouldBeInHistory = item.isArchived || (item.isPaid && isExpired);

      if (tabIndex == 3) return shouldBeInHistory;
      if (shouldBeInHistory) return false;

      if (tabIndex == 1) return item.itemType == 'Bill';
      if (tabIndex == 2) return item.itemType == 'Document';
      return true;
    }).toList();

    // 3. Sort
    return tabFiltered..sort((a, b) {
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

  @override
  Widget build(BuildContext context) {
    final vaultItems = ref.watch(vaultProvider);
    final currency = ref.watch(currencyProvider);

    ref.listen(bottomNavIndexProvider, (previous, next) {
      if (next == 1) {
        for (final controller in _scrollControllers) {
          if (controller.hasClients) {
            controller.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
        ref.read(navBarVisibleProvider.notifier).state = true;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            DueVaultLogo(size: 34, showGlow: false),
            SizedBox(width: 12),
            Text('Vault', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            SizedBox(width: 8),
            SyncStatusIndicator(),
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
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).cardTheme.color,
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Icon(
                                Icons.person,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
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
          VaultTabSwitcher(
            activeTabIndex: _activeTabIndex,
            onTabTap: _onTabTap,
          ),
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
          const SizedBox(height: 4),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // Only react to vertical scroll, not horizontal page swipes
                if (notification.metrics.axis != Axis.vertical) return false;
                if (notification is ScrollUpdateNotification) {
                  final delta = notification.scrollDelta ?? 0;
                  if (delta > 2) {
                    // Scrolling down → hide
                    ref.read(navBarVisibleProvider.notifier).state = false;
                  } else if (delta < -2) {
                    // Scrolling up → show
                    ref.read(navBarVisibleProvider.notifier).state = true;
                  }
                }
                if (notification is ScrollEndNotification) {
                  if (notification.metrics.pixels <= 0) {
                    ref.read(navBarVisibleProvider.notifier).state = true;
                  }
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPageIndex = index),
                itemBuilder: (context, index) {
                  final tabIndex = index % 4;
                  final items = _getFilteredAndSortedItems(vaultItems, tabIndex);
                  return VaultListBuilder(
                    items: items,
                    currency: currency,
                    scrollController: _scrollControllers[tabIndex],
                    onPaidStatusToggle: _togglePaidStatus,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
