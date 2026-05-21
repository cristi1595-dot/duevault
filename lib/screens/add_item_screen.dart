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
import '../utils/permission_helper.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import '../utils/logger.dart';
import '../utils/validation_helper.dart';
import '../services/analytics_service.dart';
import '../constants/app_categories.dart';
import 'add_item/bento_input_wrapper.dart';
import 'add_item/category_selector.dart';
import 'add_item/attachment_section.dart';

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
              final valStr = result.probableAmount.toString();
              if (ValidationHelper.isAmountValid(valStr, isRequired: false)) {
                _amountController.text = valStr;
              }
            }
            if (result.probableDate != null && _dueDate == null) {
              if (ValidationHelper.isDateValid(result.probableDate, isRequired: false)) {
                _dueDate = result.probableDate;
              }
            }
            if (_titleController.text.isEmpty) {
              if (result.probableTitle != null && result.probableTitle!.isNotEmpty) {
                _titleController.text = result.probableTitle!;
              } else if (_dueDate != null) {
                _titleController.text =
                    'Scanned Bill - ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}';
              } else {
                _titleController.text = 'Scanned Bill';
              }
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
            (_amountController.text.isEmpty || _dueDate == null || _titleController.text.isEmpty)) {
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
            if (_titleController.text.isEmpty) {
              if (result.probableTitle != null && result.probableTitle!.isNotEmpty) {
                _titleController.text = result.probableTitle!;
              } else if (_dueDate != null) {
                _titleController.text =
                    'Scanned Bill - ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}';
              } else {
                _titleController.text = 'Scanned Bill';
              }
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
      lastDate: DateTime.now().add(const Duration(days: 365 * 50)),
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

    // Force keyboard down globally before validating
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) return;

    final dateError = ValidationHelper.validateDate(_dueDate, isRequired: true);
    if (dateError != null) {
      _showValidationError(dateError);
      return;
    }

    final amountStr = _amountController.text.trim();
    final amountError = ValidationHelper.validateAmount(amountStr, isRequired: true);
    if (amountError != null) {
      _showValidationError(amountError);
      return;
    }
    final amount = double.parse(amountStr.replaceAll(',', '.'));

    final notesStr = _notesController.text.trim();
    final notesError = ValidationHelper.validateNotes(notesStr);
    if (notesError != null) {
      _showValidationError(notesError);
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

    // Fix the bug where item.isPaid = false unconditionally overwrites recurring and Direct Debit logic!
    if (!_isEdit) {
      item.isPaid = _directDebit;
    } else if (_directDebit) {
      item.isPaid = true;
    } // Otherwise, if it is edit and Direct Debit is off, keep the item's previous isPaid status!

    item.notes = notesStr.isEmpty ? null : notesStr;
    item.attachedFiles = _attachedFiles;

    setState(() => _isSaving = true);
    try {
      await ref.read(vaultProvider.notifier).addItem(item);
      await ref.read(analyticsServiceProvider).logItemAdded(item.itemType ?? 'Bill');
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
                ).copyWith(fontSize: 14, letterSpacing: 1.2),
              ),
              const SizedBox(height: 6),
              BentoCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: CategorySelector(
                  selectedCategory: _category,
                  categories: _categories,
                  onCategorySelected: (catName) {
                    setState(() {
                      _category = catName;
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
                ),
              ),
              const SizedBox(height: 8),

              BentoInputWrapper(
                label: 'TITLE',
                child: TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 19,
                  ),
                  decoration: InputDecoration(
                    hintText: _getCategoryHint(),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                  ),
                  onChanged: (val) => setState(() {}),
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                  validator: (value) => ValidationHelper.validateTitle(value),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: BentoInputWrapper(
                      label: 'AMOUNT (${currency.code})',
                      child: SizedBox(
                        height: 38,
                        child: TextFormField(
                          controller: _amountController,
                          onChanged: (val) => setState(() {}),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: false,
                          ),
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 19,
                          ),
                          validator: (value) => ValidationHelper.validateAmount(value, isRequired: true),
                          inputFormatters: [
                            AmountInputFormatter(),
                          ],
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            isDense: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 10,
                              bottom: 8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BentoInputWrapper(
                      label: 'DUE DATE',
                      child: InkWell(
                        onTap: _pickDate,
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          alignment: Alignment.center,
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
                                  fontSize: 19,
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: AppTheme.primaryAction,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  // Recurrence (50%)
                  Expanded(
                    child: BentoInputWrapper(
                      label: 'RECURRENCE',
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        alignment: Alignment.center,
                        child: DropdownButton<String>(
                          value: _recurrence,
                          isExpanded: true,
                          isDense: true,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                          dropdownColor: Theme.of(context).cardTheme.color,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 19,
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
                    child: BentoInputWrapper(
                      label: 'AUTO-PAY',
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
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
                                        fontSize: 19,
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
              const SizedBox(height: 10),

              BentoInputWrapper(
                label: 'NOTES',
                child: TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 17,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Add details...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              AttachmentSection(
                attachedFiles: _attachedFiles,
                useOcr: _useOcr,
                isProcessingOcr: _isProcessingOcr,
                onPickImage: () => _pickImage(ImageSource.camera),
                onPickFiles: _pickFiles,
                onRemoveAttachment: (index) {
                  setState(() {
                    _attachedFiles.removeAt(index);
                  });
                },
                onOcrToggleChanged: (val) {
                  setState(() {
                    _useOcr = val;
                  });
                },
              ),
              const SizedBox(height: 16),

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


}
