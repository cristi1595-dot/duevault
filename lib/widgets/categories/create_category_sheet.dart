import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category_item.dart';
import '../../providers/category_provider.dart';
import 'category_color_picker.dart';
import 'category_icon_picker.dart';

class CreateCategorySheet extends ConsumerStatefulWidget {
  final String defaultType;

  const CreateCategorySheet({super.key, this.defaultType = 'Both'});

  static Future<CategoryItem?> show(BuildContext context, {String defaultType = 'Both'}) {
    return showModalBottomSheet<CategoryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateCategorySheet(defaultType: defaultType),
    );
  }

  @override
  ConsumerState<CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends ConsumerState<CreateCategorySheet> {
  final _nameController = TextEditingController();
  int _colorValue = 0xFF6366F1;
  int _iconCodePoint = Icons.folder_outlined.codePoint;
  late String _itemType;
  String? _error;

  @override
  void initState() {
    super.initState();
    _itemType = widget.defaultType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a category name');
      return;
    }

    final newCat = CategoryItem(
      name: name,
      iconCodePoint: _iconCodePoint,
      colorValue: _colorValue,
      itemType: _itemType,
      isCustom: true,
    );

    final success = await ref.read(categoryProvider.notifier).addCategory(newCat);
    if (!mounted) return;

    if (!success) {
      setState(() => _error = 'A category with this name already exists');
      return;
    }

    Navigator.pop(context, newCat);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF161A22) : Colors.white;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Category',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: _save,
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Pets, Vacation, Kids',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Icon', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              CategoryIconPicker(
                selectedIconCode: _iconCodePoint,
                activeColor: Color(_colorValue),
                onIconSelected: (code) => setState(() => _iconCodePoint = code),
              ),
              const SizedBox(height: 16),
              const Text('Color', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              CategoryColorPicker(
                selectedColorValue: _colorValue,
                onColorSelected: (colorVal) => setState(() => _colorValue = colorVal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
