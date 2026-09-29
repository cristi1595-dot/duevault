import 'package:flutter/material.dart';

class CategoryIconPicker extends StatelessWidget {
  final int selectedIconCode;
  final ValueChanged<int> onIconSelected;
  final Color activeColor;

  static const List<IconData> icons = [
    Icons.pets_outlined,
    Icons.child_care_outlined,
    Icons.fitness_center_outlined,
    Icons.school_outlined,
    Icons.flight_takeoff_outlined,
    Icons.directions_car_outlined,
    Icons.home_outlined,
    Icons.medical_services_outlined,
    Icons.receipt_long_outlined,
    Icons.credit_card_outlined,
    Icons.shopping_bag_outlined,
    Icons.build_outlined,
    Icons.work_outline,
    Icons.sports_esports_outlined,
    Icons.restaurant_outlined,
    Icons.security_outlined,
    Icons.family_restroom_outlined,
    Icons.local_gas_station_outlined,
    Icons.palette_outlined,
    Icons.electric_bolt_outlined,
    Icons.wifi_outlined,
    Icons.phone_iphone_outlined,
    Icons.savings_outlined,
    Icons.folder_outlined,
    Icons.account_balance_outlined,
    Icons.subscriptions_outlined,
    Icons.health_and_safety_outlined,
    Icons.badge_outlined,
    Icons.verified_outlined,
    Icons.home_work_outlined,
    Icons.more_horiz_outlined,
  ];

  static IconData getIcon(int codePoint) {
    for (final icon in icons) {
      if (icon.codePoint == codePoint) return icon;
    }
    return Icons.folder_outlined;
  }

  const CategoryIconPicker({
    super.key,
    required this.selectedIconCode,
    required this.onIconSelected,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: 24, // Show the primary 24 curated icons in the picker grid
        itemBuilder: (context, index) {
          final iconData = icons[index];
          final isSelected = iconData.codePoint == selectedIconCode;

          return InkWell(
            onTap: () => onIconSelected(iconData.codePoint),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.18)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? activeColor : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Icon(
                iconData,
                size: 22,
                color: isSelected ? activeColor : Theme.of(context).iconTheme.color,
              ),
            ),
          );
        },
      ),
    );
  }
}
