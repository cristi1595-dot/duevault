import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import '../models/vault_item.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/vault_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/global_components.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/currency_provider.dart';
import '../services/encryption_service.dart';
import 'package:flutter/services.dart';
import '../utils/validation_helper.dart';
import '../utils/amount_formatter.dart';
import '../services/analytics_service.dart';
import '../services/ocr_service.dart';
import '../constants/app_categories.dart';
import 'add_shared/bento_input_wrapper.dart';
import 'add_shared/attachment_section.dart';
import 'add_shared/attachment_picker_helper.dart';
import 'add_bill/bill_amount_date_row.dart';
import 'add_bill/bill_recurrence_autopay_row.dart';
import '../providers/premium_provider.dart';
import '../providers/auth_provider.dart';
import 'paywall_screen.dart';
import '../services/app_review_service.dart';

class AddBillScreen extends ConsumerStatefulWidget {
  final VaultItem? item;
  final List<String>? initialAttachments;
  final bool? initialIsPaid;
  final OcrResult? initialOcrResult;

  const AddBillScreen({
    super.key,
    this.item,
    this.initialAttachments,
    this.initialIsPaid,
    this.initialOcrResult,
  });

  @override
  ConsumerState<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends ConsumerState<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  String _itemType = 'Bill';
  String _category = AppCategories.billCategories.first.name;
  String _recurrence = 'None';
  bool _directDebit = false;
  bool _isAlreadyPaid = false;
  DateTime? _dueDate;

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  List<String> _attachedFiles = [];
  bool _useOcr = true;
  bool _isProcessingOcr = false;
  bool _isSaving = false;
  String? _attachmentsDirPath;
  bool _showNotes = false;

  @override
  void initState() {
    super.initState();
    _loadAttachmentsDirectory();
    
    // Default OCR to false for Guest or Free tier users
    final isGuest = ref.read(isGuestProvider);
    final isPremium = ref.read(isPremiumProvider);
    _useOcr = !isGuest && isPremium;

    if (widget.initialAttachments != null) {
      _attachedFiles.addAll(widget.initialAttachments!);
    }
    if (widget.initialIsPaid == true) {
      _isAlreadyPaid = true;
    }

    if (widget.item != null) {
      _itemType = widget.item!.itemType ?? 'Bill';
      _category = _isEdit ? widget.item!.category : AppCategories.billCategories.first.name;
      _recurrence = widget.item!.recurrence;
      _directDebit = widget.item!.directDebit;
      _dueDate = widget.item!.dueDate;
      if (widget.item!.isPaid) {
        _isAlreadyPaid = true;
      }
      _titleController.text = widget.item!.title;
      _amountController.text = widget.item!.amount?.formatAmount() ?? '';
      _attachedFiles = List.from(widget.item!.attachedFiles);

      // Decrypt notes asynchronously to keep the UI perfectly responsive
      if (widget.item!.notes != null && widget.item!.notes!.isNotEmpty) {
        _showNotes = true;
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

    if (widget.initialOcrResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showOcrFeedback(widget.initialOcrResult!);
        }
      });
    }
  }

  void _showOcrFeedback(OcrResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'AI Extracted: ${result.summary}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryAction,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleOcrResult(OcrResult result) {
    if (result.probableAmount != null && _amountController.text.isEmpty) {
      final valStr = result.probableAmount!.formatAmount();
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
    if (result.isReceipt && !_isAlreadyPaid) {
      _isAlreadyPaid = true;
    }
    _showOcrFeedback(result);
  }

  Future<void> _pickImage(ImageSource source) async {
    final isGuest = ref.read(isGuestProvider);
    final isPremium = ref.read(isPremiumProvider);
    if (isGuest || !isPremium) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;
    }
    await AttachmentPickerHelper.pickImage(
      context: context,
      source: source,
      useOcr: _useOcr,
      isDocument: false,
      currentCount: _attachedFiles.length,
      onOcrProcessingChanged: (val) => setState(() => _isProcessingOcr = val),
      onFileAdded: (path) {
        setState(() {
          _attachedFiles.add(path);
        });
      },
      onOcrResult: (result) {
        setState(() {
          _handleOcrResult(result);
        });
      },
      onError: _showValidationError,
    );
  }

  Future<void> _pickFiles() async {
    await AttachmentPickerHelper.pickFiles(
      context: context,
      useOcr: _useOcr,
      isDocument: false,
      currentCount: _attachedFiles.length,
      onOcrProcessingChanged: (val) => setState(() => _isProcessingOcr = val),
      onFilesAdded: (paths) {
        setState(() {
          _attachedFiles.addAll(paths);
        });
      },
      onOcrResult: (result) {
        setState(() {
          _handleOcrResult(result);
        });
      },
      onError: _showValidationError,
    );
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
              surface: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
              onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
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

  Future<void> _loadAttachmentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    if (mounted) {
      setState(() {
        _attachmentsDirPath = '${appDir.path}/attachments';
      });
    }
  }

  List<String> get _resolvedAttachedFiles {
    if (_attachmentsDirPath == null) return [];
    return _attachedFiles.map((path) {
      if (path.contains('/') || path.contains('\\')) {
        return path;
      }
      return '$_attachmentsDirPath/$path';
    }).toList();
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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDayOnly = _dueDate != null
        ? DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day)
        : null;
    final isDuePassed = dueDayOnly != null &&
        (dueDayOnly.isBefore(today) || dueDayOnly.isAtSameMomentAs(today));

    // Proper Autopay & Paid state logic:
    if (_isAlreadyPaid) {
      item.isPaid = true;
      item.isArchived = true;
      item.directDebit = false;
    } else if (_directDebit) {
      if (isDuePassed) {
        // Autopay is ON and payment date has arrived or passed -> marked as paid!
        item.isPaid = true;
        if (dueDayOnly.isBefore(today)) {
          // If strictly in the past, also mark as archived
          item.isArchived = true;
        }
      } else {
        // Autopay is ON but payment date is in the future -> NOT paid yet!
        item.isPaid = false;
      }
    } else {
      if (!_isEdit) {
        item.isPaid = false;
      }
      // If editing and autopay is OFF, retain user's previous manual isPaid status
    }

    item.notes = notesStr.isEmpty ? null : notesStr;
    item.attachedFiles = _attachedFiles;

    setState(() => _isSaving = true);
    try {
      await ref.read(vaultProvider.notifier).addItem(item);
      await ref.read(analyticsServiceProvider).logItemAdded(item.itemType ?? 'Bill');
      if (mounted) {
        final rootContext = Navigator.of(context).context;
        // Direct to Home: pop until we reach the root (HomeScreen)
        Navigator.of(context).popUntil((route) => route.isFirst);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (rootContext.mounted) {
            ref.read(appReviewServiceProvider).incrementActionCounter(ref, rootContext);
          }
        });
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
    final isFormValid = _titleController.text.trim().isNotEmpty &&
        _amountController.text.trim().isNotEmpty &&
        _dueDate != null;
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
              BentoInputWrapper(
                label: 'TITLE',
                child: TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 19,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Electricity, Rent, Internet',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                  validator: (value) => ValidationHelper.validateTitle(value),
                ),
              ),
              const SizedBox(height: 10),

              // Already Paid (Receipt) Card
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _isAlreadyPaid
                      ? AppTheme.primaryAction.withValues(alpha: 0.12)
                      : (Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isAlreadyPaid
                        ? AppTheme.primaryAction.withValues(alpha: 0.45)
                        : Theme.of(context).dividerColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isAlreadyPaid ? Icons.check_circle : Icons.receipt_long_outlined,
                      color: _isAlreadyPaid
                          ? AppTheme.primaryAction
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Already Paid (Receipt)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          Text(
                            _isAlreadyPaid
                                ? 'Saves to Paid & Settled (no reminder alarms)'
                                : 'For past receipts, warranties & expense records',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAlreadyPaid,
                      activeTrackColor: AppTheme.primaryAction,
                      activeThumbColor: Colors.white,
                      onChanged: (val) {
                        setState(() {
                          _isAlreadyPaid = val;
                          if (val && _dueDate == null) {
                            _dueDate = DateTime.now();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),

              BillAmountDateRow(
                amountController: _amountController,
                dueDate: _dueDate,
                currencyCode: currency.code,
                onDateTap: _pickDate,
                onAmountChanged: (val) => setState(() {}),
                onQuickDateSelected: (date) => setState(() => _dueDate = date),
              ),
              const SizedBox(height: 12),

              BillRecurrenceAutoPayRow(
                recurrence: _recurrence,
                directDebit: _directDebit,
                onRecurrenceChanged: (v) {
                  if (v != null) setState(() => _recurrence = v);
                },
                onDirectDebitChanged: (val) => setState(() => _directDebit = val),
              ),
              const SizedBox(height: 12),

              if (!_showNotes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextButton.icon(
                    onPressed: () => setState(() => _showNotes = true),
                    icon: const Icon(Icons.note_add_outlined, size: 18),
                    label: const Text('Add Notes & Remarks'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryAction,
                    ),
                  ),
                )
              else
                BentoInputWrapper(
                  label: 'NOTES',
                  child: TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add invoice number, payment details...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _notesController.clear();
                          setState(() => _showNotes = false);
                        },
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 10),

              AttachmentSection(
                attachedFiles: _resolvedAttachedFiles,
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
                  final isGuest = ref.read(isGuestProvider);
                  final isPremium = ref.read(isPremiumProvider);
                  if (val && (isGuest || !isPremium)) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaywallScreen()),
                    );
                    return;
                  }
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
                onPressed: (_isSaving || !isFormValid) ? null : _submit,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
