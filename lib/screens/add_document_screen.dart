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
import '../services/ocr_service.dart';
import '../services/encryption_service.dart';
import '../widgets/encrypted_image.dart';
import '../utils/permission_helper.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import '../utils/logger.dart';
import '../utils/validation_helper.dart';

import '../constants/app_categories.dart';

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
  final ImagePicker _picker = ImagePicker();

  final List<CategoryData> _categories = AppCategories.docCategories;

  @override
  void initState() {
    super.initState();
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
      case 'Legal':
        return 'e.g. Rent Contract';
      case 'Career':
        return 'e.g. University Diploma';
      case 'Travel':
        return 'e.g. Boarding Pass';
      default:
        return 'e.g. General Document';
    }
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
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (pickedFile != null && mounted) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();

        if (fileSize > 10485760) {
          _showValidationError(
            'Image too large (Max 10MB). Current: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB',
          );
          return;
        }

        if (_useOcr) {
          setState(() => _isProcessingOcr = true);
          final result = await OcrService.processImage(
            File(pickedFile.path),
            isDocument: true,
          );
          setState(() {
            _isProcessingOcr = false;

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

            if (_attachedFiles.length < 5) {
              _attachedFiles.add(pickedFile.path);
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
    // We try to request, but don't block, as FilePicker handles its own permissions on many platforms
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
            (_titleController.text.isEmpty || _expiryDate == null)) {
          setState(() => _isProcessingOcr = true);
          final result = await OcrService.processImage(
            File(firstImagePath),
            isDocument: true,
          );
          setState(() {
            _isProcessingOcr = false;
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
                ).copyWith(fontSize: 12, letterSpacing: 1.2),
              ),
              const SizedBox(height: 10),
              BentoCard(
                padding: const EdgeInsets.all(12), // Symmetrical padding
                child: GridView.builder(
                  padding: EdgeInsets.zero, // Remove default grid padding
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 4, // Reduced
                    crossAxisSpacing: 6, // Reduced
                    childAspectRatio: 1.15, // Taller
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _category == cat.name;
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat.name),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryAction
                              : Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryAction
                                : Theme.of(
                                    context,
                                  ).dividerColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              cat.icon,
                              size: 28, // Maximized to match Bills
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.primaryAction,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat.name,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
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
                ),
              ),
              const SizedBox(height: 12),

              _buildBentoInput(
                label: 'DOCUMENT TITLE',
                child: TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (val) => setState(() {}),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 17,
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
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildBentoInput(
                label: 'EXPIRY / RENEWAL DATE',
                child: InkWell(
                  onTap: _pickDate,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
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
              const SizedBox(height: 16),

              _buildBentoInput(
                label: 'NOTES',
                child: TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  inputFormatters: [LengthLimitingTextInputFormatter(1000)],
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
                              subtitle: 'PDF, Images',
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
                                      color: Theme.of(
                                        context,
                                      ).dividerColor.withValues(alpha: 0.5),
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
                    : (_isEdit ? 'Update Document' : 'Save Document'),
                icon: _isSaving ? null : Icons.check_circle_outline,
                onPressed: (_isFormValid && !_isSaving) ? _submit : null,
              ),
              const SizedBox(height: 40),
            ],
          ),
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

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
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
