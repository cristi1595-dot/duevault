import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/global_components.dart';
import '../../constants/app_categories.dart';
import '../add_shared/category_selector.dart';

class BillCategorySelector extends StatelessWidget {
  final String selectedCategory;
  final List<CategoryData> categories;
  final ValueChanged<String> onCategorySelected;

  const BillCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BILL CATEGORY',
          style: AppTheme.labelCapsStyle(
            context,
          ).copyWith(fontSize: 14, letterSpacing: 1.2),
        ),
        const SizedBox(height: 6),
        BentoCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: CategorySelector(
            selectedCategory: selectedCategory,
            categories: categories,
            onCategorySelected: onCategorySelected,
          ),
        ),
      ],
    );
  }
}
