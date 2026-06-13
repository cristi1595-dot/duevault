import 'package:flutter/material.dart';

class CategoryData {
  final String name;
  final IconData icon;
  final Color color;

  const CategoryData({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class AppCategories {
  static const List<CategoryData> billCategories = [
    CategoryData(
      name: 'Housing',
      icon: Icons.home_outlined,
      color: Colors.blue,
    ),
    CategoryData(
      name: 'Utilities',
      icon: Icons.electric_bolt_outlined,
      color: Colors.orange,
    ),
    CategoryData(
      name: 'Loans',
      icon: Icons.account_balance_outlined,
      color: Colors.indigo,
    ),
    CategoryData(
      name: 'Subscriptions',
      icon: Icons.subscriptions_outlined,
      color: Colors.purple,
    ),
    CategoryData(
      name: 'Auto',
      icon: Icons.directions_car_outlined,
      color: Colors.red,
    ),
    CategoryData(
      name: 'Telecom',
      icon: Icons.wifi_outlined,
      color: Colors.teal,
    ),
    CategoryData(
      name: 'Health',
      icon: Icons.health_and_safety_outlined,
      color: Colors.green,
    ),
    CategoryData(
      name: 'Other',
      icon: Icons.more_horiz_outlined,
      color: Colors.grey,
    ),
  ];

  static const List<CategoryData> docCategories = [
    CategoryData(
      name: 'Identity',
      icon: Icons.badge_outlined,
      color: Colors.indigo,
    ),
    CategoryData(
      name: 'Health',
      icon: Icons.medical_services_outlined,
      color: Colors.red,
    ),
    CategoryData(
      name: 'Warranty',
      icon: Icons.verified_outlined,
      color: Colors.amber,
    ),
    CategoryData(
      name: 'Property',
      icon: Icons.home_work_outlined,
      color: Colors.brown,
    ),
    CategoryData(
      name: 'Auto',
      icon: Icons.directions_car_outlined,
      color: Colors.red,
    ),
    CategoryData(
      name: 'Career',
      icon: Icons.school_outlined,
      color: Colors.blueGrey,
    ),
    CategoryData(
      name: 'Travel',
      icon: Icons.flight_takeoff_outlined,
      color: Colors.orange,
    ),
    CategoryData(
      name: 'Other',
      icon: Icons.more_horiz_outlined,
      color: Colors.grey,
    ),
  ];

  static IconData getIcon(String categoryName) {
    final all = [...billCategories, ...docCategories];
    try {
      return all.firstWhere((cat) => cat.name == categoryName).icon;
    } catch (_) {
      return Icons.more_horiz_outlined;
    }
  }

  static Color getColor(String categoryName) {
    final all = [...billCategories, ...docCategories];
    try {
      return all.firstWhere((cat) => cat.name == categoryName).color;
    } catch (_) {
      return Colors.grey;
    }
  }
}
