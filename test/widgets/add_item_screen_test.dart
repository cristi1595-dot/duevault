import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:duevault_app/models/vault_item.dart';
import 'package:duevault_app/models/app_config.dart';
import 'package:duevault_app/providers/vault_provider.dart';
import 'package:duevault_app/providers/database_provider.dart';
import 'package:duevault_app/screens/add_item_screen.dart';
import 'package:duevault_app/repositories/vault_repository.dart';
import 'package:isar/isar.dart';

class MockIsar extends Mock implements Isar {}

class MockVaultRepository extends Mock implements VaultRepository {}

void main() {
  late MockIsar mockIsar;
  late MockVaultRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(AppConfig());
    registerFallbackValue(VaultItem());
  });

  setUp(() {
    mockIsar = MockIsar();
    mockRepository = MockVaultRepository();

    when(
      () => mockRepository.getConfig(),
    ).thenAnswer((_) async => AppConfig()..hasSeenDemo = true);
    when(() => mockIsar.writeTxn<void>(any())).thenAnswer((invocation) {
      final callback = invocation.positionalArguments[0] as Function;
      return (callback() as Future).then((_) => null);
    });
    when(() => mockRepository.updateConfig(any())).thenAnswer((_) async {});
    when(() => mockRepository.getItems(any())).thenAnswer((_) async => []);
    when(
      () => mockRepository.autoArchiveExpiredItems(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepository.deleteSamplesForUser(any()),
    ).thenAnswer((_) async {});
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        isarProvider.overrideWith((ref) => mockIsar),
        vaultRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: const MaterialApp(home: AddItemScreen()),
    );
  }

  testWidgets(
    'AddItemScreen shows validation error when saving without amount',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());

      // Find the Save button
      final saveButton = find.text('Save Bill');
      expect(saveButton, findsOneWidget);

      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle(); // Wait for snackbar

      // Check for snackbar or validation error
      // AddItemScreen calls _showValidationError which shows a SnackBar
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Please select a Due Date'), findsOneWidget);
    },
  );

  testWidgets('AddItemScreen displays category selection', (tester) async {
    await tester.pumpWidget(createTestWidget());

    expect(find.text('BILL CATEGORY'), findsOneWidget);
    expect(find.text('Housing'), findsOneWidget);
    expect(find.text('Utilities'), findsOneWidget);
  });
}
