import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_item.dart';
import '../services/category_service.dart';

final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);

final categoryProvider =
    StateNotifierProvider<CategoryNotifier, List<CategoryItem>>((ref) {
  return CategoryNotifier();
});

class CategoryNotifier extends StateNotifier<List<CategoryItem>> {
  CategoryNotifier() : super(CategoryService.defaultCategories) {
    _load();
  }

  Future<void> _load() async {
    final custom = await CategoryService.loadCustomCategories();
    final defaults = CategoryService.defaultCategories;
    state = [...defaults, ...custom];
  }

  Future<bool> addCategory(CategoryItem item) async {
    final exists = state.any(
      (c) => c.name.trim().toLowerCase() == item.name.trim().toLowerCase(),
    );
    if (exists) return false;

    final updated = [...state, item];
    state = updated;

    final customOnly = updated.where((c) => c.isCustom).toList();
    await CategoryService.saveCustomCategories(customOnly);
    return true;
  }

  Future<void> deleteCustomCategory(String name) async {
    final updated = state.where((c) => !c.isCustom || c.name != name).toList();
    state = updated;
    final customOnly = updated.where((c) => c.isCustom).toList();
    await CategoryService.saveCustomCategories(customOnly);
  }

  CategoryItem getCategory(String name) {
    return state.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => CategoryItem(
        name: name,
        iconCodePoint: Icons.folder_outlined.codePoint,
        colorValue: 0xFF64748B,
      ),
    );
  }
}
