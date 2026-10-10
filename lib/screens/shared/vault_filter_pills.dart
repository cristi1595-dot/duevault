import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// Reusable horizontal pill filter for vault screens (BillsScreen & DocumentsScreen).
class VaultFilterPills extends StatelessWidget {
  final int selectedIndex;
  final List<String> options;
  final bool isDark;
  final Color activeColor;
  final ValueChanged<int> onSelect;

  const VaultFilterPills({
    super.key,
    required this.selectedIndex,
    required this.options,
    required this.isDark,
    required this.activeColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (int i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            _buildChip(options[i], i),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(String label, int index) {
    final isSelected = selectedIndex == index;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onSelect(index);
      },
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppColors.surfaceElevated(isDark),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border(isDark),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium(
            isSelected ? Colors.white : AppColors.textSecondary(isDark),
          ).copyWith(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
