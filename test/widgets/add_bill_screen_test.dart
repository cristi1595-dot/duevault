import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:duevault_app/models/vault_item.dart';
import 'package:duevault_app/models/app_config.dart';
import 'package:duevault_app/providers/vault_provider.dart';
import 'package:duevault_app/providers/database_provider.dart';
import 'package:duevault_app/screens/add_bill_screen.dart';
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
      child: const MaterialApp(home: AddBillScreen()),
    );
  }

  testWidgets(
    'AddBillScreen shows validation error when saving without a date',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());

      // Fill in valid title and amount to pass Form validation
      await tester.enterText(find.byType(TextFormField).first, 'Electricity Bill');
      await tester.enterText(find.byType(TextFormField).at(1), '100.00');

      // Find the Save button
      final saveButton = find.text('Save Bill');
      expect(saveButton, findsOneWidget);

      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle(); // Wait for snackbar

      // Check for snackbar validation error (from date selector)
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Please select a date'), findsOneWidget);
    },
  );

  testWidgets(
    'AddBillScreen shows validation error when saving without amount',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget());

      // Fill in valid title but leave amount empty
      await tester.enterText(find.byType(TextFormField).first, 'Electricity Bill');

      // Find the Save button
      final saveButton = find.text('Save Bill');
      expect(saveButton, findsOneWidget);

      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Check for form validation error message on amount field
      expect(find.text('Amount is required'), findsOneWidget);
    },
  );

  testWidgets('AddBillScreen displays category selection', (tester) async {
    await tester.pumpWidget(createTestWidget());

    expect(find.text('BILL CATEGORY'), findsOneWidget);
    expect(find.text('Housing'), findsOneWidget);
    expect(find.text('Utilities'), findsOneWidget);
  });
}
