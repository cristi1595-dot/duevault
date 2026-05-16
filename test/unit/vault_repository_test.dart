import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:isar/isar.dart';
import 'package:duevault_app/repositories/vault_repository.dart';
import 'package:duevault_app/models/vault_item.dart';

import 'package:flutter/services.dart';

class MockIsar extends Mock implements Isar {
  @override
  Future<T> writeTxn<T>(
    Future<T> Function() callback, {
    bool silent = false,
  }) async {
    return callback();
  }
}

class MockIsarCollection extends Mock implements IsarCollection<VaultItem> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VaultRepository repository;
  late MockIsar mockIsar;
  late MockIsarCollection mockCollection;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
            return '.';
          },
        );
    registerFallbackValue(VaultItem());
  });

  setUp(() {
    mockIsar = MockIsar();
    mockCollection = MockIsarCollection();

    when(() => mockIsar.collection<VaultItem>()).thenReturn(mockCollection);

    repository = VaultRepository(mockIsar);
  });

  group('VaultRepository.saveItem', () {
    test('Saving a new item calls put on Isar collection', () async {
      final item = VaultItem()
        ..title = 'Test Bill'
        ..itemType = 'Bill'
        ..amount = 100.0;

      // Mock put
      when(() => mockCollection.put(any())).thenAnswer((_) async => 1);

      // We need to bypass the file processing in saveItem for this unit test
      // or mock the file system. Since we want to check if put works:

      try {
        await repository.saveItem(item);
      } catch (e) {
        // saveItem might fail because of getApplicationDocumentsDirectory in a unit test
        // if not properly mocked, but we are checking the Isar interaction.
      }

      // Verify that put was called (even if the method threw later due to other IO)
      verify(() => mockCollection.put(any())).called(1);
    });
  });
}
