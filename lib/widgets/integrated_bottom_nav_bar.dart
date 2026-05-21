import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class IntegratedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onAddPressed;

  const IntegratedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildNavItem(0, Icons.home_filled, 'Home', inactiveColor),
          ),
          _buildAddButton(),
          Expanded(
            child: _buildNavItem(1, Icons.folder_copy, 'Vault', inactiveColor),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    Color inactiveColor,
  ) {
    final isSelected = currentIndex == index;
    const activeColor = AppTheme.primaryAction;
    final color = isSelected ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: onAddPressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.primaryAction,
          borderRadius: BorderRadius.circular(20), // Matches Bento style radius
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 40),
      ),
    );
  }
}
