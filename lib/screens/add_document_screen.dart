import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/vault_item.dart';
import '../providers/vault_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/global_components.dart';
import '../services/encryption_service.dart';
import '../utils/validation_helper.dart';
import '../services/analytics_service.dart';
import '../constants/app_categories.dart';
import 'add_shared/bento_input_wrapper.dart';
import 'add_shared/attachment_section.dart';
import 'add_shared/attachment_picker_helper.dart';
import 'add_shared/notes_input_card.dart';
import 'add_document/document_expiry_picker.dart';
import 'add_document/document_validity_chips.dart';
import '../providers/premium_provider.dart';
import '../providers/auth_provider.dart';
import '../services/app_review_service.dart';

class AddDocumentScreen extends ConsumerStatefulWidget {
  final VaultItem? item;
  const AddDocumentScreen({super.key, this.item});

  @override
  ConsumerState<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends ConsumerState<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  String _category = AppCategories.docCategories.first.name;
  DateTime? _expiryDate;

  final _titleController = TextEditingController();
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

    final isGuest = ref.read(isGuestProvider);
    final isPremium = ref.read(isPremiumProvider);
    _useOcr = kAllFeaturesFree || (!isGuest && isPremium);

    if (widget.item != null) {
      _category = widget.item!.category;
      _expiryDate = widget.item!.dueDate;
      _titleController.text = widget.item!.title;
      _attachedFiles = List.from(widget.item!.attachedFiles);

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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    await AttachmentPickerHelper.pickImage(
      context: context,
      source: source,
      useOcr: _useOcr,
      isDocument: true,
      currentCount: _attachedFiles.length,
      onOcrProcessingChanged: (val) => setState(() => _isProcessingOcr = val),
      onFileAdded: (path) => setState(() => _attachedFiles.add(path)),
      onOcrResult: (result) {
        setState(() {
          if (_titleController.text.isEmpty && result.probableTitle != null) {
            final rawTitle = result.probableTitle!;
            _titleController.text = rawTitle.length > 40 ? rawTitle.substring(0, 40) : rawTitle;
          } else if (_titleController.text.isEmpty) {
            _titleController.text = 'Scanned Document';
          }
          if (result.probableDate != null && _expiryDate == null) {
            if (ValidationHelper.isDateValid(result.probableDate, isRequired: false)) {
              _expiryDate = result.probableDate;
            }
          }
        });
      },
      onError: _showValidationError,
    );
  }

  Future<void> _pickFiles() async {
    await AttachmentPickerHelper.pickFiles(
      context: context,
      useOcr: _useOcr,
      isDocument: true,
      currentCount: _attachedFiles.length,
      onOcrProcessingChanged: (val) => setState(() => _isProcessingOcr = val),
      onFilesAdded: (paths) => setState(() => _attachedFiles.addAll(paths)),
      onOcrResult: (result) {
        setState(() {
          if (_titleController.text.isEmpty && result.probableTitle != null) {
            final rawTitle = result.probableTitle!;
            _titleController.text = rawTitle.length > 40 ? rawTitle.substring(0, 40) : rawTitle;
          } else if (_titleController.text.isEmpty) {
            _titleController.text = 'Scanned Document';
          }
          if (result.probableDate != null && _expiryDate == null) {
            if (ValidationHelper.isDateValid(result.probableDate, isRequired: false)) {
              _expiryDate = result.probableDate;
            }
          }
        });
      },
      onError: _showValidationError,
    );
  }

  Future<void> _pickDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
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
      setState(() => _expiryDate = picked);
    }
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
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) return;

    final rawTitle = _titleController.text.trim();
    final titleError = ValidationHelper.validateTitle(rawTitle.isEmpty ? _category : rawTitle);
    if (titleError != null) {
      _showValidationError(titleError);
      return;
    }

    final dateError = ValidationHelper.validateDate(_expiryDate, isRequired: false);
    if (dateError != null) {
      _showValidationError(dateError);
      return;
    }

    final notesStr = _notesController.text.trim();
    final notesError = ValidationHelper.validateNotes(notesStr);
    if (notesError != null) {
      _showValidationError(notesError);
      return;
    }

    final item = _isEdit ? widget.item! : VaultItem();
    item.itemType = 'Document';
    item.title = rawTitle.isEmpty ? _category : rawTitle;
    item.category = _category;
    item.dueDate = _expiryDate;
    item.notes = notesStr.isEmpty ? null : notesStr;
    item.attachedFiles = _attachedFiles;
    item.isPaid = false;

    setState(() => _isSaving = true);
    try {
      await ref.read(vaultProvider.notifier).addItem(item);
      await ref.read(analyticsServiceProvider).logItemAdded('Document');
      if (mounted) {
        final rootContext = Navigator.of(context).context;
        Navigator.of(context).popUntil((route) => route.isFirst);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (rootContext.mounted) {
            ref.read(appReviewServiceProvider).incrementActionCounter(ref, rootContext);
          }
        });
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showValidationError('Error saving document: $e');
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

  bool get _isFormValid =>
      _titleController.text.trim().isNotEmpty && _expiryDate != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          !_isEdit ? 'Add New Document' : 'Edit Document',
          style: AppTypography.titleMedium(AppColors.textPrimary(isDark)).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary(isDark),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BentoInputWrapper(
                label: 'DOCUMENT TITLE',
                icon: Icons.badge_outlined,
                child: TextFormField(
                  key: const Key('doc_title_field'),
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (val) => setState(() {}),
                  style: TextStyle(
                    color: AppColors.textPrimary(isDark),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  validator: (value) => ValidationHelper.validateTitle(value),
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                  decoration: InputDecoration(
                    hintText: 'e.g. Passport, Driver License, Insurance',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted(isDark),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: AppSpacing.sm,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              DocumentExpiryPicker(
                expiryDate: _expiryDate,
                isDark: isDark,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _pickDate();
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              DocumentValidityChips(
                selectedDate: _expiryDate,
                isDark: isDark,
                onValiditySelected: (date) => setState(() => _expiryDate = date),
              ),
              const SizedBox(height: AppSpacing.md),

              NotesInputCard(
                notesController: _notesController,
                showNotes: _showNotes,
                isDark: isDark,
                isBill: false,
                onAddNotesPressed: () => setState(() => _showNotes = true),
                onClosePressed: () {
                  _notesController.clear();
                  setState(() => _showNotes = false);
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              AttachmentSection(
                attachedFiles: _resolvedAttachedFiles,
                useOcr: _useOcr,
                isProcessingOcr: _isProcessingOcr,
                onPickImage: () => _pickImage(ImageSource.camera),
                onPickFiles: _pickFiles,
                onRemoveAttachment: (index) {
                  setState(() => _attachedFiles.removeAt(index));
                },
                onOcrToggleChanged: (val) => setState(() => _useOcr = val),
              ),
              const SizedBox(height: AppSpacing.base),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            AppSpacing.sm,
            AppSpacing.base,
            AppSpacing.base,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface(isDark),
            border: Border(
              top: BorderSide(color: AppColors.border(isDark), width: 1.0),
            ),
          ),
          child: PrimaryButton(
            label: _isSaving
                ? 'Saving...'
                : (_isEdit ? 'Update Document' : 'Save Document'),
            icon: _isSaving ? null : Icons.check_circle_outline,
            isLoading: _isSaving,
            height: 52,
            borderRadius: AppRadius.lg,
            onPressed: (_isFormValid && !_isSaving)
                ? () {
                    HapticFeedback.mediumImpact();
                    _submit();
                  }
                : null,
          ),
        ),
      ),
    );
  }
}
