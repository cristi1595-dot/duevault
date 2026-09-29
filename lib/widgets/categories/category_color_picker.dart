import 'package:flutter/material.dart';

class CategoryColorPicker extends StatelessWidget {
  final int selectedColorValue;
  final ValueChanged<int> onColorSelected;

  static const List<int> palette = [
    0xFF6366F1, // Indigo
    0xFF3B82F6, // Blue
    0xFF0EA5E9, // Sky
    0xFF14B8A6, // Teal
    0xFF10B981, // Emerald
    0xFF84CC16, // Lime
    0xFFF59E0B, // Amber
    0xFFF97316, // Orange
    0xFFEF4444, // Red
    0xFFEC4899, // Pink
    0xFFA855F7, // Purple
    0xFF8B5CF6, // Violet
    0xFF64748B, // Slate
    0xFF78716C, // Stone
    0xFF0284C7, // Ocean
    0xFF059669, // Forest
  ];

  const CategoryColorPicker({
    super.key,
    required this.selectedColorValue,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: palette.map((colorVal) {
        final isSelected = colorVal == selectedColorValue;
        return GestureDetector(
          onTap: () => onColorSelected(colorVal),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(colorVal),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Color(colorVal).withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
