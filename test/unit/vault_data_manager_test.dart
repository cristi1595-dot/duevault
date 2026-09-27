import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:duevault_app/services/vault_data_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('vault_data_manager_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getApplicationDocumentsDirectory') {
              return tempDir.path;
            }
            return tempDir.path;
          },
        );
  });

  tearDownAll(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('VaultDataManager.clearLocalCache', () {
    test('clears files inside attachments directory without throwing', () async {
      final attachmentsDir = Directory('${tempDir.path}/attachments');
      await attachmentsDir.create(recursive: true);

      final dummyFile = File('${attachmentsDir.path}/test_attachment.txt');
      await dummyFile.writeAsString('test data');

      expect(await dummyFile.exists(), isTrue);

      await VaultDataManager.clearLocalCache();

      expect(await dummyFile.exists(), isFalse);
    });
  });
}
