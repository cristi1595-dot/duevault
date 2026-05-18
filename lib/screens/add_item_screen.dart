import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/vault_item.dart';
import '../providers/vault_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/global_components.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/currency_provider.dart';
import '../services/ocr_service.dart';
import '../services/encryption_service.dart';
import '../widgets/encrypted_image.dart';
import '../utils/permission_helper.dart';
import 'package:path/path.dart' as p;
import '../utils/logger.dart';

import '../constants/app_categories.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  final VaultItem? item;
  const AddItemScreen({super.key, this.item});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  String _itemType = 'Bill';
  String _category = AppCategories.billCategories.first.name;
  String _recurrence = 'None';
  bool _directDebit = false;
  DateTime? _dueDate;

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  List<String> _attachedFiles = [];
  bool _useOcr = true;
  bool _isProcessingOcr = false;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  final List<CategoryData> _categories = AppCategories.billCategories;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _itemType = widget.item!.itemType ?? 'Bill';
      _category = widget.item!.category;
      _recurrence = widget.item!.recurrence;
      _directDebit = widget.item!.directDebit;
      _dueDate = widget.item!.dueDate;
      _titleController.text = widget.item!.title;
      _amountController.text = widget.item!.amount?.toString() ?? '';
      _attachedFiles = List.from(widget.item!.attachedFiles);

      // Decrypt notes asynchronously to keep the UI perfectly responsive
      if (widget.item!.notes != null && widget.item!.notes!.isNotEmpty) {
        _notesController.text = 'Loading notes...';
        EncryptionService.decryptText(widget.item!.notes).then((decrypted) {
          if (mounted) {
            setState(() {
              _notesController.text = decrypted ?? '';
            });
          }
        });
      } else {
        _notesController.text = '';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    // 1. Permission Check - continue even if status is uncertain
    if (!mounted) return;
    if (source == ImageSource.camera) {
      await PermissionHelper.requestCameraPermission(context);
    } else {
      await PermissionHelper.requestGalleryPermission(context);
    }

    if (!mounted) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600, // Balanced resolution for mobile/cloud
        imageQuality: 80, // High-quality compression
      );
      if (pickedFile != null && mounted) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();

        // 10MB limit (10 * 1024 * 1024)
        if (fileSize > 10485760) {
          _showValidationError(
            'Image too large (Max 10MB). Current: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB',
          );
          return;
        }

        if (_useOcr) {
          setState(() => _isProcessingOcr = true);
          final result = await OcrService.processImage(File(pickedFile.path));
          setState(() {
            _isProcessingOcr = false;
            if (result.probableAmount != null &&
                _amountController.text.isEmpty) {
              _amountController.text = result.probableAmount.toString();
            }
            if (result.probableDate != null && _dueDate == null) {
              _dueDate = result.probableDate;
            }
            if (_titleController.text.isEmpty && result.probableDate != null) {
              _titleController.text =
                  'Scanned Bill - ${result.probableDate!.day}/${result.probableDate!.month}/${result.probableDate!.year}';
            } else if (_titleController.text.isEmpty) {
              _titleController.text = 'Scanned Bill';
            }
            if (_attachedFiles.length < 5) {
              _attachedFiles.add(pickedFile.path);
            }

            // Optionally add raw OCR text to notes if empty
            if (_notesController.text.isEmpty && result.rawText.isNotEmpty) {
              // _notesController.text = 'OCR Text:\n${result.rawText}';
              // Decided to keep notes clean, or user can uncomment this
            }
          });
        } else {
          setState(() {
            if (_attachedFiles.length < 5) {
              _attachedFiles.add(pickedFile.path);
            } else {
              _showValidationError('Maximum 5 attachments allowed');
            }
          });
        }
      }
    } catch (e) {
      logger.e('Error picking image', error: e);
    }
  }

  Future<void> _pickFiles() async {
    // Try to request, but don't block
    await PermissionHelper.requestGalleryPermission(context);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
        allowMultiple: true,
      );
      if (result != null) {
        final newPaths = result.paths.whereType<String>().toList();
        final List<String> validPaths = [];

        for (var path in newPaths) {
          final file = File(path);
          final fileSize = await file.length();

          if (fileSize > 10485760) {
            _showValidationError(
              'File too large: ${p.basename(path)} (Max 10MB)',
            );
            continue;
          }
          validPaths.add(path);
        }

        setState(() {
          for (var path in validPaths) {
            if (_attachedFiles.length < 5) {
              _attachedFiles.add(path);
            }
          }
        });

        // OCR Support for Uploaded Images
        final firstImagePath = validPaths.firstWhere(
          (path) =>
              path.toLowerCase().endsWith('.jpg') ||
              path.toLowerCase().endsWith('.jpeg') ||
              path.toLowerCase().endsWith('.png'),
          orElse: () => '',
        );

        if (firstImagePath.isNotEmpty &&
            (_amountController.text.isEmpty || _dueDate == null)) {
          setState(() => _isProcessingOcr = true);
          final result = await OcrService.processImage(File(firstImagePath));
          setState(() {
            _isProcessingOcr = false;
            if (result.probableAmount != null &&
                _amountController.text.isEmpty) {
              _amountController.text = result.probableAmount!.toStringAsFixed(
                2,
              );
            }
            if (result.probableDate != null && _dueDate == null) {
              _dueDate = result.probableDate;
            }
          });
        }
      }
    } catch (e) {
      logger.e('Error picking files', error: e);
    }
  }

  Future<void> _pickDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme(
              brightness: Theme.of(context).brightness,
              primary: AppTheme.primaryAction,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardTheme.color!,
              onSurface: Theme.of(context).textTheme.bodyLarge!.color!,
              secondary: AppTheme.primaryAction,
              onSecondary: Colors.white,
              error: AppTheme.urgentRed,
              onError: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
    // Force keyboard down globally
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_dueDate == null) {
      _showValidationError('Please select a Due Date');
      return;
    }

    final amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) {
      _showValidationError('Please enter an amount');
      return;
    }

    final amount = double.tryParse(amountStr.replaceAll(',', '.'));
    if (amount == null) {
      _showValidationError('Please enter a valid amount');
      return;
    }

    // Use existing item for edit, or create new for addition
    final item = _isEdit ? widget.item! : VaultItem();

    item.itemType = _itemType;
    final rawTitle = _titleController.text.trim();
    item.title = rawTitle.isEmpty ? _category : rawTitle;
    item.category = _category;
    item.amount = amount;
    item.dueDate = _dueDate;
    item.recurrence = _recurrence;
    item.directDebit = _directDebit;

    // If Direct Debit is ON, we treat it as paid automatically
    if (_directDebit) {
      item.isPaid = true;
    }

    item.notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();
    item.attachedFiles = _attachedFiles;
    item.isPaid = false;

    setState(() => _isSaving = true);
    try {
      await ref.read(vaultProvider.notifier).addItem(item);
      if (mounted) {
        // Direct to Home: pop until we reach the root (HomeScreen)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showValidationError('Error saving item: $e');
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.urgentRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool get _isEdit =>
      widget.item != null && widget.item!.id != Isar.autoIncrement;

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          !_isEdit ? 'Add New Bill' : 'Edit Bill',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BILL CATEGORY',
                style: AppTheme.labelCapsStyle(
                  context,
                ).copyWith(fontSize: 12, letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              BentoCard(
                padding: const EdgeInsets.all(12), // Symmetrical padding
                child: _buildCompactCategoryWrap(),
              ),
              const SizedBox(height: 12), // Reduced spacing

              _buildBentoInput(
                label: 'TITLE',
                child: TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 17,
                  ),
                  decoration: InputDecoration(
                    hintText: _getCategoryHint(),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (val) => setState(() {}),
                  validator: null,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildBentoInput(
                      label: 'AMOUNT (${currency.code})',
                      child: TextFormField(
                        controller: _amountController,
                        onChanged: (val) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: false,
                        ),
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 17,
                        ),
                        decoration: const InputDecoration(
                          hintText: '0.00',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBentoInput(
                      label: 'DUE DATE',
                      child: InkWell(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _dueDate != null
                                    ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                    : 'Select',
                                style: TextStyle(
                                  color: _dueDate != null
                                      ? Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                  fontSize: 15,
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: AppTheme.primaryAction,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  // Recurrence (50%)
                  Expanded(
                    child: _buildBentoInput(
                      label: 'RECURRENCE',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        child: DropdownButton<String>(
                          value: _recurrence,
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                          dropdownColor: Theme.of(context).cardTheme.color,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 13,
                          ),
                          items: ['None', 'Weekly', 'Monthly', 'Yearly'].map((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _recurrence = v);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Direct Debit (50%)
                  Expanded(
                    child: _buildBentoInput(
                      label: 'AUTO-PAY',
                      child: Container(
                        height: 48, // Match dropdown height
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.account_balance_outlined,
                                    color: _directDebit
                                        ? AppTheme.primaryAction
                                        : Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Direct Debit',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _directDebit,
                              onChanged: (val) =>
                                  setState(() => _directDebit = val),
                              activeThumbColor: AppTheme.primaryAction,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildBentoInput(
                label: 'NOTES',
                child: TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 15,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Add details...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildBentoInput(
                label: 'ATTACHMENTS',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(child: _buildCameraCardWithOcrToggle()),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.upload_file_outlined,
                              title: 'Upload Files',
                              subtitle: 'PDF, JPG, PNG',
                              onTap: _pickFiles,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_attachedFiles.isNotEmpty)
                      Container(
                        height: 90,
                        padding: const EdgeInsets.only(
                          left: 12,
                          bottom: 12,
                          top: 4,
                        ),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _attachedFiles.length,
                          separatorBuilder: (ctx, i) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final path = _attachedFiles[index];
                            return Stack(
                              children: [
                                Container(
                                  width: 70,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                  child: _buildAttachmentIcon(path),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _attachedFiles.removeAt(index),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                label: _isSaving
                    ? 'Saving...'
                    : (!_isEdit ? 'Save Bill' : 'Update Bill'),
                icon: _isSaving ? null : Icons.check_circle_outline,
                onPressed: _isSaving ? null : _submit,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110, // Reduced height
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primaryAction, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodySmall?.color ??
                    AppTheme.lightTextSecondary,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraCardWithOcrToggle() {
    return GestureDetector(
      onTap: _isProcessingOcr ? null : () => _pickImage(ImageSource.camera),
      child: Container(
        height: 110,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _useOcr
                ? AppTheme.primaryAction.withValues(alpha: 0.5)
                : Theme.of(context).dividerColor,
            width: _useOcr ? 1.5 : 1.0,
          ),
          boxShadow: _useOcr
              ? [
                  BoxShadow(
                    color: AppTheme.primaryAction.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessingOcr)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            else
              Icon(
                Icons.auto_awesome,
                color: _useOcr
                    ? AppTheme.primaryAction
                    : AppTheme.lightTextSecondary,
                size: 28,
              ),

            const SizedBox(height: 6),
            Text(
              _isProcessingOcr ? 'Scanning...' : 'Smart Scan',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _useOcr ? 'AUTO-FILL ON' : 'AUTO-FILL OFF',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: _useOcr
                        ? AppTheme.primaryAction
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  height: 20,
                  width: 32,
                  child: Switch(
                    value: _useOcr,
                    onChanged: (val) => setState(() => _useOcr = val),
                    activeThumbColor: AppTheme.primaryAction,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoInput({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
          ),
          child: child,
        ),
      ],
    );
  }

  String _getCategoryHint() {
    switch (_category) {
      case 'Housing':
        return 'e.g. Monthly Rent';
      case 'Utilities':
        return 'e.g. Electricity Bill';
      case 'Loans':
        return 'e.g. Bank Loan';
      case 'Subscription':
        return 'e.g. Netflix / Spotify';
      case 'Auto':
        return 'e.g. Fuel / Repairs';
      case 'Telecom':
        return 'e.g. Internet Bill';
      case 'Insurance':
        return 'e.g. Health Insurance';
      default:
        return 'e.g. Grocery Bill';
    }
  }

  Widget _buildCompactCategoryWrap() {
    return GridView.builder(
      padding: EdgeInsets.zero, // Remove default grid padding
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 4, // Reduced spacing
        crossAxisSpacing: 6, // Reduced spacing
        childAspectRatio: 1.15, // Taller items
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final isSelected = _category == cat.name;
        return GestureDetector(
          onTap: () {
            setState(() {
              _category = cat.name;
              // Auto-set recurrence based on category
              if ([
                'Housing',
                'Utilities',
                'Subscription',
                'Telecom',
              ].contains(_category)) {
                _recurrence = 'Monthly';
              } else {
                _recurrence = 'None';
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryAction
                  : Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryAction
                    : Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cat.icon,
                  size: 28, // Maximized icon
                  color: isSelected ? Colors.white : AppTheme.primaryAction,
                ),
                const SizedBox(height: 6),
                Text(
                  cat.name,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 10, // Slightly larger font
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentIcon(String path) {
    final isImage =
        path.toLowerCase().endsWith('.jpg') ||
        path.toLowerCase().endsWith('.jpeg') ||
        path.toLowerCase().endsWith('.png');

    if (isImage) {
      final isStored = path.contains('app_flutter/attachments');
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: isStored
            ? EncryptedImage(path: path, fit: BoxFit.cover)
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.insert_drive_file,
                  color: AppTheme.primaryAction,
                ),
              ),
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, color: AppTheme.urgentRed, size: 24),
            SizedBox(height: 2),
            Text(
              'PDF',
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
  }
}
