import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duevault_app/providers/vault_provider.dart';
import 'package:duevault_app/repositories/vault_repository.dart';
import 'package:duevault_app/models/vault_item.dart';
import 'package:duevault_app/models/app_config.dart';
import 'package:duevault_app/providers/database_provider.dart';
import 'package:duevault_app/models/user.dart';
import 'package:isar/isar.dart';
import 'package:duevault_app/services/migration_service.dart';

class MockVaultRepository extends Mock implements VaultRepository {}
class MockIsar extends Mock implements Isar {}
class MockVaultCollection extends Mock implements IsarCollection<VaultItem> {}
class MockAppConfigCollection extends Mock implements IsarCollection<AppConfig> {}
class MockUserCollection extends Mock implements IsarCollection<User> {}
class MockQuery extends Mock implements Query<VaultItem> {}
class MockQueryBuilder extends Mock implements QueryBuilder<VaultItem, VaultItem, QAfterFilterCondition> {}

class Listener<T> extends Mock {
  void call(T? previous, T next);
}

void main() {
  late MockVaultRepository mockRepository;
  late MockIsar mockIsar;
  late MockVaultCollection mockVaultCollection;
  late MockAppConfigCollection mockAppConfigCollection;
  late MockUserCollection mockUserCollection;

  setUpAll(() {
    registerFallbackValue(AppConfig());
    registerFallbackValue(VaultItem());
  });

  setUp(() {
    mockRepository = MockVaultRepository();
    mockIsar = MockIsar();
    mockVaultCollection = MockVaultCollection();
    mockAppConfigCollection = MockAppConfigCollection();
    mockUserCollection = MockUserCollection();

    when(() => mockIsar.collection<VaultItem>()).thenReturn(mockVaultCollection);
    when(() => mockIsar.collection<AppConfig>()).thenReturn(mockAppConfigCollection);
    when(() => mockIsar.collection<User>()).thenReturn(mockUserCollection);
    when(() => mockAppConfigCollection.get(any())).thenAnswer((_) async => AppConfig()
      ..hasSeenDemo = true
      ..dataVersion = MigrationService.currentDataVersion);
    
    when(() => mockRepository.autoArchiveExpiredItems(any())).thenAnswer((_) async {});
    when(() => mockRepository.deleteSamplesForUser(any())).thenAnswer((_) async {});
    when(() => mockRepository.updateConfig(any())).thenAnswer((_) async {});
    when(() => mockRepository.getItems(any())).thenAnswer((_) async => []);
    when(() => mockRepository.getConfig()).thenAnswer((_) async => AppConfig()
      ..hasSeenDemo = true
      ..dataVersion = MigrationService.currentDataVersion);
  });

  test('VaultNotifier loads items from repository after initialization delay', () async {
    final items = [VaultItem()..title = 'Test Item'..ownerId = 'local_user'];
    
    when(() => mockRepository.getItems(any())).thenAnswer((_) async => items);

    final container = ProviderContainer(
      overrides: [
        vaultRepositoryProvider.overrideWithValue(mockRepository),
        isarProvider.overrideWith((ref) => mockIsar),
      ],
    );
    addTearDown(container.dispose);

    final listener = Listener<List<VaultItem>>();
    container.listen<List<VaultItem>>(
      vaultProvider,
      listener.call,
      fireImmediately: true,
    );

    // Initial state is empty []
    verify(() => listener(null, [])).called(1);

    // The notifier has a 2.5s delay for Android 15 stability in _loadItems
    // We wait enough time for it to complete
    await Future.delayed(const Duration(milliseconds: 3000));

    // State should now be the items
    expect(container.read(vaultProvider), items);
  });
}
