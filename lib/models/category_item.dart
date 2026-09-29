// ignore_for_file: non_const_argument_for_const_parameter
import 'package:flutter/material.dart';

class CategoryItem {
  final String name;
  final int iconCodePoint;
  final String? iconFontFamily;
  final int colorValue;
  final String itemType; // 'Bill', 'Document', 'Both'
  final bool isCustom;

  const CategoryItem({
    required this.name,
    required this.iconCodePoint,
    this.iconFontFamily,
    required this.colorValue,
    this.itemType = 'Both',
    this.isCustom = false,
  });

  IconData get icon => IconData(
        iconCodePoint,
        fontFamily: iconFontFamily ?? 'MaterialIcons',
      );

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'name': name,
        'iconCodePoint': iconCodePoint,
        'iconFontFamily': iconFontFamily,
        'colorValue': colorValue,
        'itemType': itemType,
        'isCustom': isCustom,
      };

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
        name: json['name'] as String? ?? 'General',
        iconCodePoint: json['iconCodePoint'] as int? ?? Icons.folder_outlined.codePoint,
        iconFontFamily: json['iconFontFamily'] as String?,
        colorValue: json['colorValue'] as int? ?? 0xFF6366F1,
        itemType: json['itemType'] as String? ?? 'Both',
        isCustom: json['isCustom'] as bool? ?? true,
      );

  CategoryItem copyWith({
    String? name,
    int? iconCodePoint,
    String? iconFontFamily,
    int? colorValue,
    String? itemType,
    bool? isCustom,
  }) =>
      CategoryItem(
        name: name ?? this.name,
        iconCodePoint: iconCodePoint ?? this.iconCodePoint,
        iconFontFamily: iconFontFamily ?? this.iconFontFamily,
        colorValue: colorValue ?? this.colorValue,
        itemType: itemType ?? this.itemType,
        isCustom: isCustom ?? this.isCustom,
      );
}
