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
import 'add_shared/attachment_section.dart';
import 'add_shared/attachment_picker_helper.dart';
import 'add_bill/bill_hero_amount_input.dart';
import 'add_bill/bill_date_recurrence_card.dart';
import '../providers/premium_provider.dart';
import '../providers/auth_provider.dart';
import 'paywall_screen.dart';
import '../services/app_review_service.dart';

class AddBillScreen extends ConsumerStatefulWidget {
  final VaultItem? item;
  final List<String>? initialAttachments;
  final OcrResult? initialOcrResult;

  const AddBillScreen({
    super.key,
    this.item,
    this.initialAttachments,
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

    if (widget.item != null) {
      _itemType = widget.item!.itemType ?? 'Bill';
      _category = _isEdit ? widget.item!.category : AppCategories.billCategories.first.name;
      _recurrence = widget.item!.recurrence;
      _directDebit = widget.item!.directDebit;
      _dueDate = widget.item!.dueDate;
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
    if (_directDebit) {
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
              BillHeroAmountInput(
                amountController: _amountController,
                currencyCode: currency.code,
                currencySymbol: currency.symbol,
                onAmountChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // CARD 1: TITLE BENTO CARD (#161F30, #222F48)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF161F30),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF222F48),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          size: 15,
                          color: AppTheme.primaryAction,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'BILL TITLE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const Key('bill_title_field'),
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Electricity, Rent, Internet',
                        hintStyle: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setState(() {});
                      },
                      inputFormatters: [LengthLimitingTextInputFormatter(40)],
                      validator: (value) => ValidationHelper.validateTitle(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // CARD 2: DUE DATE, RECURRENCE & AUTO-PAY BENTO CARD
              BillDateRecurrenceCard(
                dueDate: _dueDate,
                onDateTap: _pickDate,
                onQuickDateSelected: (date) => setState(() => _dueDate = date),
                recurrence: _recurrence,
                onRecurrenceChanged: (v) {
                  if (v != null) setState(() => _recurrence = v);
                },
                directDebit: _directDebit,
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161F30),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF222F48),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 15,
                                color: AppTheme.primaryAction,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'NOTES & REMARKS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              _notesController.clear();
                              setState(() => _showNotes = false);
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Add invoice number, payment details...',
                          hintStyle: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ],
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: PrimaryButton(
            label: _isSaving
                ? 'Saving...'
                : (!_isEdit ? 'Save Bill' : 'Update Bill'),
            icon: _isSaving ? null : Icons.check_circle_outline,
            onPressed: (_isSaving || !isFormValid) ? null : _submit,
          ),
        ),
      ),
    );
  }
}
