import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vault_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/currency_provider.dart';
import '../widgets/global_components.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

import '../constants/app_categories.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

enum SortOption { date, name, amount }

class _VaultScreenState extends ConsumerState<VaultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  SortOption _sortBy = SortOption.date;
  bool _sortAscending = true;

  final List<CategoryData> _billCategories = AppCategories.billCategories;
  final List<CategoryData> _docCategories = AppCategories.docCategories;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget buildList(List<dynamic> items, Currency currency) {
    if (items.isEmpty) {
      return const Center(child: Text('Nothing to show.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return VaultItemTile(
          item: item,
          currency: currency,
          onCheckPressed: !item.isPaid
              ? () {
                  final notifier = ref.read(vaultProvider.notifier);
                  notifier.updatePaidStatus(item.id, true);

                  final actionText = item.itemType == 'Bill' ? 'Paid' : 'Renewed';
                  VaultSnackBar.show(
                    message: '${item.title.isEmpty ? item.category : item.title} $actionText',
                    actionLabel: 'UNDO',
                    onAction: () => notifier.updatePaidStatus(item.id, false),
                  );
                }
              : null,
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

    // 1. Determine tab context
    final bool isBillsTab = _tabController.index == 1;
    final bool isDocsTab = _tabController.index == 2;
    final bool isHistoryTab = _tabController.index == 3;

    // 2. Filter items by Search
    final searchFiltered = vaultItems.where((item) {
      return item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();

    // 3. Filter items by Tab (for category calculation)
    final filteredItems = searchFiltered.where((item) {
      final isExpired = item.dueDate != null && item.dueDate!.isBefore(today);
      
      // History logic: Manually archived OR (Paid AND Expired)
      final shouldBeInHistory = item.isArchived || (item.isPaid && isExpired);
      
      if (isHistoryTab) return shouldBeInHistory;
      
      // Other tabs show everything that is NOT archived and NOT "past its prime" (History)
      if (shouldBeInHistory) return false;
      
      if (isBillsTab) return item.itemType == 'Bill';
      if (isDocsTab) return item.itemType == 'Document';
      return true; // All tab
    }).toList();

    // 4. Calculate existing categories in this tab (deduplicated)
    final existingCategoryNames = filteredItems.map((e) => e.category).toSet();
    final Set<String> seenNames = {};
    final List<Map<String, dynamic>> displayedCategories = [];
    for (var cat in _billCategories) {
      final name = cat.name;
      if (existingCategoryNames.contains(name)) {
        displayedCategories.add({'name': cat.name, 'icon': cat.icon, 'color': cat.color, 'type': 'B'});
        seenNames.add('$name-B');
      }
    }
    for (var cat in _docCategories) {
      final name = cat.name;
      if (existingCategoryNames.contains(name)) {
        displayedCategories.add({'name': cat.name, 'icon': cat.icon, 'color': cat.color, 'type': 'D'});
        seenNames.add('$name-D');
      }
    }


    // 5. Final Filter by selected category
    final finalItems = filteredItems.where((item) {
      return _selectedCategory == null || item.category == _selectedCategory;
    }).toList();

    // 6. Apply Sorting
    finalItems.sort((a, b) {
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

    // Split for TabBarView
    final allItems = finalItems;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Text('Vault', style: Theme.of(context).textTheme.headlineLarge),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
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
                            ? Icon(Icons.person, color: Theme.of(context).textTheme.bodyMedium?.color, size: 18)
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
          // 1. Premium Pill-Shaped Tab Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 42,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
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

          // 2. Search Bar (Smaller) & Sort
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
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
                // Sort Button on the right
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                  ),
                  child: PopupMenuButton<SortOption>(
                    icon: const Icon(
                      Icons.sort,
                      color: AppTheme.primaryAction,
                      size: 20,
                    ),
                    offset: const Offset(0, 50),
                    color: AppTheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      PopupMenuItem(
                        value: SortOption.date,
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Date',
                              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                            const Spacer(),
                            if (_sortBy == SortOption.date)
                              Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: AppTheme.primaryAction),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: SortOption.name,
                        child: Row(
                          children: [
                            Icon(
                              Icons.sort_by_alpha,
                              size: 18,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Name',
                              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                            const Spacer(),
                            if (_sortBy == SortOption.name)
                              Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: AppTheme.primaryAction),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: SortOption.amount,
                        child: Row(
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              size: 18,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Amount',
                              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                            const Spacer(),
                            if (_sortBy == SortOption.amount)
                              Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: AppTheme.primaryAction),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Compact Categories Section
          if (displayedCategories.isNotEmpty || _selectedCategory != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ALL Category (Premium Bento Tile)
                  GestureDetector(
                    onTap: () => setState(() => _selectedCategory = null),
                    child: Container(
                      width: 76,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: _selectedCategory == null
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primaryAction,
                                  AppTheme.primaryAction.withValues(alpha: 0.8),
                                ],
                              )
                            : null,
                        color: _selectedCategory == null
                            ? null
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedCategory == null
                              ? AppTheme.primaryAction
                              : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                        ),
                        boxShadow: _selectedCategory == null
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryAction.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.grid_view_rounded,
                            color: _selectedCategory == null
                                ? Colors.black
                                : AppTheme.primaryAction,
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'ALL',
                            style: TextStyle(
                              color: _selectedCategory == null
                                  ? Colors.black
                                  : Theme.of(context).textTheme.bodySmall?.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Other categories in a scrollable grid-like area
                  Expanded(
                    child: SizedBox(
                      height: 72,
                      child: GridView.builder(
                        scrollDirection: Axis.horizontal,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 110,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: displayedCategories.length,
                        itemBuilder: (context, index) {
                          final cat = displayedCategories[index];
                          final isSelected = _selectedCategory == cat['name'];
                          final Color catColor = cat['color'];

                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = isSelected ? null : cat['name']),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? catColor.withValues(alpha: 0.15)
                                    : Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected 
                                      ? catColor 
                                      : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: catColor.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ] : null,
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            cat['icon'],
                                            color: isSelected ? catColor : catColor.withValues(alpha: 0.5),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              cat['name'].toString().toUpperCase(),
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Theme.of(context).textTheme.bodyLarge?.color
                                                    : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                                fontSize: 11,
                                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                                letterSpacing: 0.3,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: -1,
                                    bottom: -1,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: cat['type'] == 'B' ? AppTheme.primaryAction : AppTheme.safeGreen,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(6),
                                          bottomRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        cat['type'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 4),

          // 4. List View
          Expanded(
            child: buildList(allItems, currency),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(int index, String label) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tabController.index = index;
            _selectedCategory = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryAction : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppTheme.primaryAction.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
