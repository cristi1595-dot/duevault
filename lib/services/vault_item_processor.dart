import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/vault_item.dart';
import '../services/encryption_service.dart';

/// Handles the processing of vault items before persistence.
/// Responsible for file handling, encryption, and checksum calculation.
class VaultItemProcessor {
  /// Prepares a vault item for saving by processing attachments and encrypting data.
  static Future<VaultItem> prepareForSave(VaultItem item) async {
    // 1. Validate
    item.validate();

    // 2. Normalize dates
    if (item.dueDate != null) {
      item.dueDate = DateTime(
        item.dueDate!.year,
        item.dueDate!.month,
        item.dueDate!.day,
      );
      if (item.recurrence != 'None') {
        item.originalDueDay ??= item.dueDate!.day;
      }
    }

    // 3. Ensure UUID
    if (item.uuid.isEmpty) {
      item.uuid = const Uuid().v4();
    }

    // 4. Process attachments
    await _processAttachments(item);

    // 5. Encrypt notes
    await _encryptNotes(item);

    // 6. Update metadata
    item.lastModified = DateTime.now();
    item.wasSynced = false;

    return item;
  }

  /// Processes and encrypts attachment files.
  static Future<void> _processAttachments(VaultItem item) async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDir.path}/attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final List<String> finalPaths = [];
    final List<String> checksums = [];

    for (final path in item.attachedFiles) {
      // Only process files that are NOT already in our internal attachments folder
      if (!path.contains('app_flutter/attachments')) {
        final originalFile = File(path);
        if (await originalFile.exists()) {
          final fileName =
              'doc_${DateTime.now().microsecondsSinceEpoch}_${p.basename(path)}';
          final newPath = '${attachmentsDir.path}/$fileName';

          try {
            final bytes = await originalFile.readAsBytes();
            final fileToSave = File(newPath);
            await fileToSave.writeAsBytes(bytes);
            await EncryptionService.encryptFile(newPath);

            // Calculate MD5 of the encrypted file for cloud comparison
            final encryptedBytes = await fileToSave.readAsBytes();
            checksums.add(md5.convert(encryptedBytes).toString());
          } on FileSystemException catch (e) {
            if (e.osError?.errorCode == 28 || e.message.contains('space')) {
              throw Exception('Cannot save attachment: Storage is full.');
            }
            rethrow;
          }

          finalPaths.add(newPath);
        }
      } else {
        // Already in internal storage, just recalculate checksum
        finalPaths.add(path);
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          checksums.add(md5.convert(bytes).toString());
        }
      }
    }

    item.attachedFiles = finalPaths;
    item.cloudFileChecksums = checksums;
  }

  /// Encrypts the notes field if not already encrypted.
  static Future<void> _encryptNotes(VaultItem item) async {
    if (item.notes != null &&
        item.notes!.isNotEmpty &&
        !item.notes!.startsWith('encrypted:')) {
      final encrypted = await EncryptionService.encryptText(item.notes);
      if (encrypted != null) {
        item.notes = 'encrypted:$encrypted';
      }
    }
  }
}
