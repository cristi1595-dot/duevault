import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum SortOption { date, name, amount }

class VaultSearchAndSort extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final SortOption sortBy;
  final bool sortAscending;
  final Function(SortOption) onSortSelected;

  const VaultSearchAndSort({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.sortBy,
    required this.sortAscending,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: TextField(
                controller: searchController,
                textCapitalization: TextCapitalization.sentences,
                onChanged: onSearchChanged,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(alpha: 0.3),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  suffixIcon: searchQuery.isNotEmpty
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
                            searchController.clear();
                            onSearchChanged('');
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
              color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
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
              onSelected: onSortSelected,
              itemBuilder: (context) => [
                _buildSortItem(
                  context,
                  SortOption.date,
                  'Date',
                  Icons.calendar_today,
                ),
                _buildSortItem(
                  context,
                  SortOption.name,
                  'Name',
                  Icons.sort_by_alpha,
                ),
                _buildSortItem(
                  context,
                  SortOption.amount,
                  'Amount',
                  Icons.payments_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<SortOption> _buildSortItem(
    BuildContext context,
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
            color: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.color
                ?.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const Spacer(),
          if (sortBy == value)
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: AppTheme.primaryAction,
            ),
        ],
      ),
    );
  }
}
