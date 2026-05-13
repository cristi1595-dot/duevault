import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:crypto/crypto.dart';
import '../models/user.dart';

import '../models/vault_item.dart';
import '../models/app_config.dart';
import 'encryption_service.dart';

// Authenticated http.Client for Drive API (fix M3: properly closes inner client)
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  /// Close the inner http.Client to prevent memory leaks (fix M3)
  @override
  void close() {
    _client.close();
    super.close();
  }
}

class DriveService {
  final GoogleAuthClient authClient;
  late final drive.DriveApi driveApi;

  DriveService(this.authClient) {
    driveApi = drive.DriveApi(authClient);
  }

  /// Close the underlying HTTP client when done
  void dispose() {
    authClient.close();
  }

  /// Calculates MD5 checksum of a file
  Future<String> getFileChecksum(File file) async {
    if (!await file.exists()) return '';
    final bytes = await file.readAsBytes();
    return md5.convert(bytes).toString();
  }


  // Backup the local Isar database and Encryption Keys to Google Drive
  Future<bool> backupDatabase() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File('${dir.path}/default.isar');

      if (!await dbFile.exists()) {
        debugPrint('Local DB file not found for backup.');
        return false;
      }

      // --- 1. BACKUP ISAR DB ---
      await _uploadToDrive(
        fileName: 'duevault_backup.isar',
        file: dbFile,
      );

      // --- 2. BACKUP ENCRYPTION KEYS ---
      // This ensures data can be decrypted after a full wipe
      final keys = await EncryptionService.exportKeysForBackup();
      if (keys != null) {
        final tempDir = await getTemporaryDirectory();
        final keyFile = File('${tempDir.path}/keys.json');
        await keyFile.writeAsString(keys);
        
        await _uploadToDrive(
          fileName: 'duevault_keys.json',
          file: keyFile,
        );
        debugPrint('Encryption keys backed up.');
      }

      return true;
    } catch (e) {
      debugPrint('Backup error: $e');
      return false;
    }
  }

  /// Helper to upload a file to Drive AppData
  Future<void> _uploadToDrive({required String fileName, required File file}) async {
    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$fileName'",
    );

    String? existingFileId;
    if (fileList.files != null && fileList.files!.isNotEmpty) {
      existingFileId = fileList.files!.first.id;
    }

    final driveFile = drive.File()
      ..name = fileName
      ..parents = ['appDataFolder'];

    final media = drive.Media(file.openRead(), file.lengthSync());

    if (existingFileId != null) {
      await driveApi.files.update(drive.File(), existingFileId, uploadMedia: media);
    } else {
      await driveApi.files.create(driveFile, uploadMedia: media);
    }
  }

  /// Uploads a small JSON file with sync metadata to Drive
  Future<void> uploadMetadata(Map<String, dynamic> metadata) async {
    try {
      final content = jsonEncode(metadata);
      final tempDir = await getTemporaryDirectory();
      final metaFile = File('${tempDir.path}/sync_metadata.json');
      await metaFile.writeAsString(content);

      await _uploadToDrive(
        fileName: 'sync_metadata.json',
        file: metaFile,
      );
      debugPrint('Sync metadata uploaded.');
    } catch (e) {
      debugPrint('Error uploading metadata: $e');
    }
  }

  /// Downloads and parses the sync_metadata.json from Drive
  Future<Map<String, dynamic>?> getCloudMetadata() async {
    try {
      final data = await _downloadFromDrive('sync_metadata.json');
      if (data == null) return null;
      return jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting cloud metadata: $e');
      return null;
    }
  }


  // Restore the database from Google Drive
  Future<Isar?> restoreDatabase() async {
    try {
      // --- 1. RESTORE ENCRYPTION KEYS FIRST ---
      final keyData = await _downloadFromDrive('duevault_keys.json');
      if (keyData != null) {
        final keyString = utf8.decode(keyData);
        final success = await EncryptionService.importKeysFromBackup(keyString);
        if (!success) {
          throw Exception('FAILED_TO_IMPORT_KEYS');
        }
        debugPrint('Encryption keys restored.');
      }

      // --- 2. RESTORE ISAR DB ---
      final dataStore = await _downloadFromDrive('duevault_backup.isar');
      if (dataStore == null) {
        debugPrint('No backup found in Drive.');
        return null;
      }

      // 4. Close Isar before overwriting
      final instances = Isar.instanceNames;
      for (final name in instances) {
        final instance = Isar.getInstance(name);
        if (instance != null && instance.isOpen) {
          await instance.close();
        }
      }

      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File('${dir.path}/default.isar');
      
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
      
      await dbFile.writeAsBytes(dataStore, flush: true);

      final newIsar = await Isar.open(
        [UserSchema, VaultItemSchema, AppConfigSchema],
        directory: dir.path,
      );





      debugPrint('Backup restored successfully.');
      return newIsar;
    } catch (e) {
      debugPrint('Restore error: $e');
      return null;
    }
  }

  /// Downloads the cloud DB to a temporary location and opens it without closing the current Isar instance.
  /// Used for smart merging.
  Future<Isar?> downloadAndOpenDatabase(String name) async {
    try {
      final dataStore = await _downloadFromDrive('duevault_backup.isar');
      if (dataStore == null) return null;

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$name.isar');
      if (await tempFile.exists()) await tempFile.delete();
      await tempFile.writeAsBytes(dataStore);

      return await Isar.open(
        [UserSchema, VaultItemSchema, AppConfigSchema],
        directory: tempDir.path,
        name: name,
      );




    } catch (e) {
      debugPrint('Error opening cloud DB for merge: $e');
      return null;
    }
  }

  /// Helper to download a file from Drive AppData
  Future<Uint8List?> _downloadFromDrive(String fileName) async {
    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$fileName'",
    );

    if (fileList.files == null || fileList.files!.isEmpty) return null;

    final fileId = fileList.files!.first.id!;
    final drive.Media media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytesBuilder = BytesBuilder();
    await for (final chunk in media.stream) {
      bytesBuilder.add(chunk);
    }
    return bytesBuilder.takeBytes();
  }

  /// Get the last modified time of the backup file in Google Drive
  Future<DateTime?> getBackupModifiedTime() async {
    try {
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = 'duevault_backup.isar'",
        $fields: 'files(id, modifiedTime)',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.modifiedTime;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting cloud metadata: $e');
      return null;
    }
  }

  /// Uploads a generic file to Drive AppData and returns its fileId.
  Future<String?> uploadAttachment(File file, String fileName) async {
    try {
      final driveFile = drive.File()
        ..name = fileName
        ..parents = ['appDataFolder'];

      final media = drive.Media(file.openRead(), file.lengthSync());
      
      final result = await driveApi.files.create(driveFile, uploadMedia: media);
      return result.id;
    } catch (e) {
      debugPrint('Error uploading attachment: $e');
      return null;
    }
  }

  /// Downloads a file by ID to a specific local path using streaming.
  Future<bool> downloadAttachment(String fileId, String localPath) async {
    try {
      final drive.Media media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final outputFile = File(localPath);
      if (!await outputFile.parent.exists()) {
        await outputFile.parent.create(recursive: true);
      }
      
      final iosink = outputFile.openWrite();
      await iosink.addStream(media.stream);
      await iosink.close();
      return true;
    } catch (e) {
      debugPrint('Error downloading attachment $fileId: $e');
      return false;
    }
  }

  /// Delete a specific file from Google Drive
  Future<bool> deleteFile(String fileId) async {
    try {
      await driveApi.files.delete(fileId);
      return true;
    } catch (e) {
      debugPrint('Error deleting file $fileId: $e');
      return false;
    }
  }

  /// Delete the backup file from Google Drive (AppData folder)
  Future<bool> deleteBackup() async {
    try {
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = 'duevault_backup.isar'",
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        for (var file in fileList.files!) {
          if (file.id != null) {
            await driveApi.files.delete(file.id!);
          }
        }
        debugPrint('Cloud backup deleted successfully.');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting cloud backup: $e');
      return false;
    }
  }
}
