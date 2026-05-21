import 'package:flutter/material.dart';
import '../../constants/app_categories.dart';
import '../../theme/app_theme.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final List<CategoryData> categories;
  final ValueChanged<String> onCategorySelected;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero, // Remove default grid padding
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 4, // Reduced spacing
        crossAxisSpacing: 6, // Reduced spacing
        childAspectRatio: 1.15, // Taller items
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final isSelected = selectedCategory == cat.name;
        return GestureDetector(
          onTap: () => onCategorySelected(cat.name),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryAction
                  : Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryAction
                    : Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cat.icon,
                  size: 32,
                  color: isSelected ? Colors.white : AppTheme.primaryAction,
                ),
                const SizedBox(height: 6),
                Text(
                  cat.name,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
