import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_categories.dart';
import '../../providers/category_provider.dart';
import '../../widgets/categories/create_category_sheet.dart';

class CategorySelector extends ConsumerWidget {
  final String selectedCategory;
  final List<CategoryData>? categories;
  final ValueChanged<String> onCategorySelected;
  final String itemType; // 'Bill' or 'Document'

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    this.categories,
    required this.onCategorySelected,
    this.itemType = 'Bill',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCats = ref.watch(categoryProvider);
    final visibleCats = allCats.where((c) {
      return c.itemType == 'Both' || c.itemType == itemType;
    }).toList();

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleCats.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == visibleCats.length) {
            return InkWell(
              onTap: () async {
                final newCat = await CreateCategorySheet.show(
                  context,
                  defaultType: itemType,
                );
                if (newCat != null) {
                  onCategorySelected(newCat.name);
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 18, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'New',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final cat = visibleCats[index];
          final isSelected = selectedCategory.toLowerCase() == cat.name.toLowerCase();

          return GestureDetector(
            onTap: () => onCategorySelected(cat.name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? cat.color.withValues(alpha: 0.16)
                    : Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? cat.color
                      : Theme.of(context).dividerColor.withValues(alpha: 0.4),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.icon,
                    size: 18,
                    color: isSelected ? cat.color : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat.name,
                    style: TextStyle(
                      color: isSelected
                          ? cat.color
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
