import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';


import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import '../utils/logger.dart';

class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'isar_encryption_key_v1';
  static const _isarMasterKeyName = 'isar_database_master_key_v32';
  static const _ivName = 'isar_encryption_iv_v1';

  /// Gets or generates a 32-byte key for Isar Native Encryption
  static Future<Uint8List> getIsarMasterKey() async {
    String? base64Key = await _storage.read(key: _isarMasterKeyName);
    if (base64Key == null) {
      final random = Random.secure();
      final keyBytes = Uint8List.fromList(
        List.generate(32, (_) => random.nextInt(256)),
      );
      base64Key = base64.encode(keyBytes);
      await _storage.write(key: _isarMasterKeyName, value: base64Key);
      return keyBytes;
    }
    return base64.decode(base64Key);
  }

  /// Gets the existing encryption key or generates a new one (32 bytes for AES-256)

  static Future<Uint8List> _getOrCreateKey() async {
    String? base64Key = await _storage.read(key: _keyName);
    
    if (base64Key == null) {
      final random = Random.secure();
      final keyBytes = Uint8List.fromList(
        List.generate(32, (_) => random.nextInt(256)),
      );
      base64Key = base64.encode(keyBytes);
      await _storage.write(key: _keyName, value: base64Key);
      return keyBytes;
    }
    
    return base64.decode(base64Key);
  }


  // --- TEXT ENCRYPTION (DYNAMIC IV) ---

  static Future<String?> encryptText(String? text) async {
    if (text == null || text.isEmpty) return text;
    
    final keyBytes = await _getOrCreateKey();
    // Generate a UNIQUE IV for every call
    final random = Random.secure();
    final ivBytes = Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
    
    final key = encrypt.Key(keyBytes);
    final iv = encrypt.IV(ivBytes);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(text, iv: iv);
    
    // Combine IV (16 bytes) + Ciphertext
    final combined = Uint8List(ivBytes.length + encrypted.bytes.length);
    combined.setAll(0, ivBytes);
    combined.setAll(ivBytes.length, encrypted.bytes);
    
    return base64.encode(combined);
  }

  static Future<String?> decryptText(String? base64Text) async {
    if (base64Text == null || base64Text.isEmpty) return base64Text;
    
    try {
      final combined = base64.decode(base64Text);
      if (combined.length <= 16) return base64Text; // Likely legacy or wrong format

      // Split IV and Ciphertext
      final ivBytes = combined.sublist(0, 16);
      final encryptedBytes = combined.sublist(16);
      
      final keyBytes = await _getOrCreateKey();
      final key = encrypt.Key(keyBytes);
      final iv = encrypt.IV(ivBytes);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      return encrypter.decrypt64(base64.encode(encryptedBytes), iv: iv);
    } catch (e) {
      // If decryption fails, it might be unencrypted legacy data
      return base64Text;
    }
  }

  // --- FILE ENCRYPTION (DYNAMIC IV) ---

  static Future<void> encryptFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return;

    final bytes = await file.readAsBytes();
    final keyBytes = await _getOrCreateKey();
    
    // Generate a UNIQUE IV
    final random = Random.secure();
    final ivBytes = Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
    
    final key = encrypt.Key(keyBytes);
    final iv = encrypt.IV(ivBytes);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encryptBytes(bytes, iv: iv);
    
    // Write IV + Ciphertext to file
    final combined = Uint8List(ivBytes.length + encrypted.bytes.length);
    combined.setAll(0, ivBytes);
    combined.setAll(ivBytes.length, encrypted.bytes);
    
    await file.writeAsBytes(combined);
  }

  static Future<Uint8List?> decryptFileToBytes(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;

    try {
      final combined = await file.readAsBytes();
      if (combined.length <= 16) return combined;

      // Split IV and Ciphertext
      final ivBytes = combined.sublist(0, 16);
      final encryptedBytes = combined.sublist(16);
      
      final keyBytes = await _getOrCreateKey();
      final key = encrypt.Key(keyBytes);
      final iv = encrypt.IV(ivBytes);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final decrypted = encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes), iv: iv);
      return Uint8List.fromList(decrypted);
    } catch (e) {
      // Fallback for unencrypted files
      return await file.readAsBytes();
    }
  }

  /// Wipes the encryption key and IV from secure storage
  static Future<void> deleteKey() async {
    await _storage.delete(key: _keyName);
    await _storage.delete(key: _ivName);
  }

  /// Exports current keys as a JSON string for cloud backup.
  static Future<String?> exportKeysForBackup() async {
    final key = await _storage.read(key: _keyName);
    final iv = await _storage.read(key: _ivName);
    final master = await _storage.read(key: _isarMasterKeyName);
    if (key == null) return null;
    
    return jsonEncode({
      'key': key, 
      'iv': iv,
      'master': master,
    });
  }

  /// Imports keys from a cloud backup JSON string.
  static Future<bool> importKeysFromBackup(String data) async {
    try {
      final Map<String, dynamic> decoded = jsonDecode(data);
      if (decoded.containsKey('key')) {
        await _storage.write(key: _keyName, value: decoded['key']);
        if (decoded.containsKey('iv')) await _storage.write(key: _ivName, value: decoded['iv']);
        if (decoded.containsKey('master')) await _storage.write(key: _isarMasterKeyName, value: decoded['master']);
        
        logger.i('Encryption keys imported to Secure Storage.');
        return true;
      }
      return false;
    } catch (e, stack) {
      logger.e('Error importing keys', error: e, stackTrace: stack);
      return false;
    }

  }

}
