import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/category_item.dart';
import '../constants/app_categories.dart';

class CategoryService {
  static const String _fileName = 'custom_categories.json';

  static List<CategoryItem> get defaultCategories {
    final list = <CategoryItem>[];
    for (final cat in AppCategories.billCategories) {
      list.add(CategoryItem(
        name: cat.name,
        iconCodePoint: cat.icon.codePoint,
        iconFontFamily: cat.icon.fontFamily,
        colorValue: cat.color.toARGB32(),
        itemType: 'Bill',
        isCustom: false,
      ));
    }
    for (final cat in AppCategories.docCategories) {
      final exists = list.any((e) => e.name.toLowerCase() == cat.name.toLowerCase());
      if (exists) {
        final index = list.indexWhere((e) => e.name.toLowerCase() == cat.name.toLowerCase());
        list[index] = list[index].copyWith(itemType: 'Both');
      } else {
        list.add(CategoryItem(
          name: cat.name,
          iconCodePoint: cat.icon.codePoint,
          iconFontFamily: cat.icon.fontFamily,
          colorValue: cat.color.toARGB32(),
          itemType: 'Document',
          isCustom: false,
        ));
      }
    }
    return list;
  }

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<CategoryItem>> loadCustomCategories() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((e) => CategoryItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCustomCategories(List<CategoryItem> customList) async {
    try {
      final file = await _getFile();
      final jsonList = customList.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (_) {}
  }
}
