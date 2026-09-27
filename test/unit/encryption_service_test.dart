import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:duevault_app/services/encryption_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EncryptionService.importKeysFromBackup', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('successfully imports keys when valid JSON with "key" field is provided', () async {
      final validBackup = jsonEncode({
        'key': 'test_key_base64',
        'iv': 'test_iv_base64',
        'master': 'test_master_base64',
      });

      final result = await EncryptionService.importKeysFromBackup(validBackup);
      expect(result, isTrue);
    });

    test('returns false when backup data is missing "key" field', () async {
      final invalidBackup = jsonEncode({
        'other_key': 'some_value',
      });

      final result = await EncryptionService.importKeysFromBackup(invalidBackup);
      expect(result, isFalse);
    });

    test('returns false and logs error when JSON string is malformed', () async {
      const malformedData = 'not_json_data';

      final result = await EncryptionService.importKeysFromBackup(malformedData);
      expect(result, isFalse);
    });
  });
}
