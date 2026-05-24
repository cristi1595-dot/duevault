import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/vault_item.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/vault_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/global_components.dart';
import 'package:image_picker/image_picker.dart';
import '../services/encryption_service.dart';
import 'package:flutter/services.dart';
import '../utils/validation_helper.dart';
import '../services/analytics_service.dart';
import '../constants/app_categories.dart';
import 'add_shared/bento_input_wrapper.dart';
import 'add_shared/category_selector.dart';
import 'add_shared/attachment_section.dart';
import 'add_shared/attachment_picker_helper.dart';
import '../providers/premium_provider.dart';
import '../providers/auth_provider.dart';
import 'paywall_screen.dart';

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

  final List<CategoryData> _categories = AppCategories.docCategories;

  @override
  void initState() {
    super.initState();
    _loadAttachmentsDirectory();

    // Default OCR to false for Guest or Free tier users
    final isGuest = ref.read(isGuestProvider);
    final isPremium = ref.read(isPremiumProvider);
    _useOcr = !isGuest && isPremium;

    if (widget.item != null) {
      _category = widget.item!.category;
      _expiryDate = widget.item!.dueDate;
      _titleController.text = widget.item!.title;
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
    _notesController.dispose();
    super.dispose();
  }

  String _getCategoryHint() {
    switch (_category) {
      case 'Identity':
        return 'e.g. My Passport';
      case 'Health':
        return 'e.g. Blood Test Results';
      case 'Warranty':
        return 'e.g. iPhone Warranty';
      case 'Property':
        return 'e.g. House Deed';
      case 'Auto':
        return 'e.g. Driving License';
      case 'Career':
        return 'e.g. University Diploma';
      case 'Travel':
        return 'e.g. Boarding Pass';
      default:
        return 'e.g. General Document';
    }
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
      isDocument: true,
      currentCount: _attachedFiles.length,
      onOcrProcessingChanged: (val) => setState(() => _isProcessingOcr = val),
      onFileAdded: (path) {
        setState(() {
          _attachedFiles.add(path);
        });
      },
      onOcrResult: (result) {
        setState(() {
          // Auto-fill Title if empty
          if (_titleController.text.isEmpty && result.probableTitle != null) {
            final rawTitle = result.probableTitle!;
            _titleController.text = rawTitle.length > 40 ? rawTitle.substring(0, 40) : rawTitle;
          } else if (_titleController.text.isEmpty) {
            _titleController.text = 'Scanned Document';
          }

          // Auto-fill Expiry Date if found and not set
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
      onFilesAdded: (paths) {
        setState(() {
          _attachedFiles.addAll(paths);
        });
      },
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
      setState(() => _expiryDate = picked);
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
        // Direct to Home: pop until we reach the root (HomeScreen)
        Navigator.of(context).popUntil((route) => route.isFirst);
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
      _titleController.text.trim().isNotEmpty ||
      _attachedFiles.isNotEmpty ||
      _expiryDate != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          !_isEdit ? 'Add New Document' : 'Edit Document',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DOCUMENT CATEGORY',
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
                  onCategorySelected: (cat) => setState(() => _category = cat),
                ),
              ),
              const SizedBox(height: 8),

              BentoInputWrapper(
                label: 'DOCUMENT TITLE',
                child: TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (val) => setState(() {}),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 19,
                  ),
                  validator: (value) => ValidationHelper.validateTitle(value),
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
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
                ),
              ),
              const SizedBox(height: 10),

              BentoInputWrapper(
                label: 'EXPIRY / RENEWAL DATE',
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
                          _expiryDate != null
                              ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                              : 'Select Date',
                          style: TextStyle(
                            color: _expiryDate != null
                                ? Theme.of(context).textTheme.bodyLarge?.color
                                : Theme.of(context).textTheme.bodyMedium?.color,
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
                    : (_isEdit ? 'Update Document' : 'Save Document'),
                icon: _isSaving ? null : Icons.check_circle_outline,
                onPressed: (_isFormValid && !_isSaving) ? _submit : null,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
