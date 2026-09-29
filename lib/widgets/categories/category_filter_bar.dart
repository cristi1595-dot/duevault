import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vault_item.dart';
import '../../providers/category_provider.dart';
import 'create_category_sheet.dart';

class CategoryFilterBar extends ConsumerWidget {
  final List<VaultItem> items;
  final String? itemTypeFilter; // null = all, 'Bill', 'Document'

  const CategoryFilterBar({
    super.key,
    required this.items,
    this.itemTypeFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCategories = ref.watch(categoryProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);

    // Filter categories relevant to the current screen / itemType
    final visibleCategories = allCategories.where((cat) {
      if (itemTypeFilter == null) return true;
      return cat.itemType == 'Both' || cat.itemType == itemTypeFilter;
    }).toList();

    // Calculate count per category
    final countMap = <String, int>{};
    for (final item in items) {
      final cat = item.category.toLowerCase();
      countMap[cat] = (countMap[cat] ?? 0) + 1;
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        scrollDirection: Axis.horizontal,
        itemCount: visibleCategories.length + 2, // 1 for 'All', 1 for '+'
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selectedCategory == null;
            return _buildChip(
              context: context,
              label: 'All',
              count: items.length,
              isSelected: isSelected,
              activeColor: const Color(0xFF6366F1),
              onTap: () => ref.read(selectedCategoryFilterProvider.notifier).state = null,
            );
          }

          if (index == visibleCategories.length + 1) {
            return _buildAddButton(context);
          }

          final cat = visibleCategories[index - 1];
          final isSelected = selectedCategory?.toLowerCase() == cat.name.toLowerCase();
          final count = countMap[cat.name.toLowerCase()] ?? 0;

          return _buildChip(
            context: context,
            label: cat.name,
            icon: cat.icon,
            count: count,
            isSelected: isSelected,
            activeColor: cat.color,
            onTap: () {
              final notifier = ref.read(selectedCategoryFilterProvider.notifier);
              notifier.state = isSelected ? null : cat.name;
            },
          );
        },
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    IconData? icon,
    required int count,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isSelected
        ? activeColor.withValues(alpha: isDark ? 0.25 : 0.15)
        : Theme.of(context).dividerColor.withValues(alpha: isDark ? 0.08 : 0.05);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Theme.of(context).dividerColor.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: isSelected ? activeColor : Colors.grey),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.25)
                      : Theme.of(context).dividerColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? activeColor : Colors.grey,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return InkWell(
      onTap: () => CreateCategorySheet.show(
        context,
        defaultType: itemTypeFilter ?? 'Both',
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 16, color: Colors.grey),
            SizedBox(width: 2),
            Text(
              'New',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
