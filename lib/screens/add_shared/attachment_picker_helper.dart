import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../services/ocr_service.dart';
import '../../utils/permission_helper.dart';
import '../../utils/logger.dart';

class AttachmentPickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Prompts camera or gallery picker, checks file size, and runs OCR if enabled.
  static Future<void> pickImage({
    required BuildContext context,
    required ImageSource source,
    required bool useOcr,
    required bool isDocument,
    required int currentCount,
    required Function(bool) onOcrProcessingChanged,
    required Function(String path) onFileAdded,
    required Function(OcrResult result) onOcrResult,
    required Function(String error) onError,
  }) async {
    if (source == ImageSource.camera) {
      final granted = await PermissionHelper.requestCameraPermission(context);
      if (!granted) return;
    } else {
      final granted = await PermissionHelper.requestGalleryPermission(context);
      if (!granted) return;
    }

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920.0,
        maxHeight: 1920.0,
        imageQuality: 70,
      );
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final fileSize = await file.length();

      // 10MB limit (10 * 1024 * 1024)
      if (fileSize > 10485760) {
        onError('Image too large (Max 10MB). Current: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB');
        return;
      }

      if (currentCount >= 5) {
        onError('Maximum 5 attachments allowed');
        return;
      }

      onFileAdded(pickedFile.path);

      if (useOcr) {
        onOcrProcessingChanged(true);
        final result = await OcrService.processImage(file, isDocument: isDocument);
        onOcrProcessingChanged(false);
        onOcrResult(result);
      }
    } catch (e) {
      logger.e('Error picking image', error: e);
    }
  }

  /// Prompts file picker, checks file sizes, and runs OCR on the first image file if enabled.
  static Future<void> pickFiles({
    required BuildContext context,
    required bool useOcr,
    required bool isDocument,
    required int currentCount,
    required Function(bool) onOcrProcessingChanged,
    required Function(List<String> paths) onFilesAdded,
    required Function(OcrResult result) onOcrResult,
    required Function(String error) onError,
  }) async {
    final granted = await PermissionHelper.requestGalleryPermission(context);
    if (!granted) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg', 'heic', 'heif', 'webp'],
      );
      if (result == null) return;

      final newPaths = result.paths.whereType<String>().toList();
      final List<String> validPaths = [];

      for (var path in newPaths) {
        final file = File(path);
        final fileSize = await file.length();

        if (fileSize > 10485760) {
          onError('File too large: ${p.basename(path)} (Max 10MB)');
          continue;
        }
        validPaths.add(path);
      }

      if (validPaths.isEmpty) return;

      final availableSlots = 5 - currentCount;
      if (availableSlots <= 0) {
        onError('Maximum 5 attachments allowed');
        return;
      }

      final List<String> pathsToAdd = validPaths.take(availableSlots).toList();
      if (validPaths.length > availableSlots) {
        onError('Only added $availableSlots files. Maximum 5 attachments allowed.');
      }

      onFilesAdded(pathsToAdd);

      if (useOcr) {
        // OCR Support for first uploaded image
        final firstImagePath = pathsToAdd.firstWhere(
          (path) {
            final lower = path.toLowerCase();
            return lower.endsWith('.jpg') ||
                lower.endsWith('.jpeg') ||
                lower.endsWith('.png') ||
                lower.endsWith('.heic') ||
                lower.endsWith('.heif') ||
                lower.endsWith('.webp');
          },
          orElse: () => '',
        );

        if (firstImagePath.isNotEmpty) {
          onOcrProcessingChanged(true);
          final ocrResult = await OcrService.processImage(File(firstImagePath), isDocument: isDocument);
          onOcrProcessingChanged(false);
          onOcrResult(ocrResult);
        }
      }
    } catch (e) {
      logger.e('Error picking files', error: e);
    }
  }
}
