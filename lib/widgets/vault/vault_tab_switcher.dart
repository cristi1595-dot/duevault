import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class VaultTabSwitcher extends StatelessWidget {
  final int activeTabIndex;
  final Function(int) onTabTap;

  const VaultTabSwitcher({
    super.key,
    required this.activeTabIndex,
    required this.onTabTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            _buildTabPill(context, 0, 'ALL'),
            _buildTabPill(context, 1, 'BILLS'),
            _buildTabPill(context, 2, 'DOCS'),
            _buildTabPill(context, 3, 'HISTORY'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill(BuildContext context, int index, String label) {
    final isSelected = activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabTap(index),
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
