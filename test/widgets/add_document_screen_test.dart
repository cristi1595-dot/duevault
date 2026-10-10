import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:duevault_app/models/vault_item.dart';
import 'package:duevault_app/models/app_config.dart';
import 'package:duevault_app/providers/vault_provider.dart';
import 'package:duevault_app/providers/database_provider.dart';
import 'package:duevault_app/repositories/vault_repository.dart';
import 'package:duevault_app/screens/add_document_screen.dart';
import 'package:duevault_app/widgets/primary_button.dart';
import 'package:isar_community/isar.dart';

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
      child: const MaterialApp(home: AddDocumentScreen()),
    );
  }

  testWidgets(
    'AddDocumentScreen save button is disabled when title or date is missing',
    (tester) async {
      await tester.pumpWidget(createTestWidget());

      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNull);

      // Enter title only
      await tester.enterText(
        find.byKey(const Key('doc_title_field')),
        'Driver License',
      );
      await tester.pumpAndSettle();

      final buttonAfterTitle = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(buttonAfterTitle.onPressed, isNull);
    },
  );

  testWidgets(
    'AddDocumentScreen enables save button when selecting a Quick Validity chip',
    (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Enter title
      await tester.enterText(
        find.byKey(const Key('doc_title_field')),
        'National ID Card',
      );
      await tester.pumpAndSettle();

      // Tap Quick Validity chip "1 Year"
      expect(find.text('1 Year'), findsOneWidget);
      await tester.tap(find.text('1 Year'));
      await tester.pumpAndSettle();

      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets(
    'AddDocumentScreen toggles notes section on demand',
    (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Add Notes & Remarks'), findsOneWidget);
      expect(find.text('NOTES & REMARKS'), findsNothing);

      // Tap Add Notes button
      await tester.tap(find.text('Add Notes & Remarks'));
      await tester.pumpAndSettle();

      expect(find.text('NOTES & REMARKS'), findsOneWidget);

      // Dismiss notes with close icon
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Add Notes & Remarks'), findsOneWidget);
      expect(find.text('NOTES & REMARKS'), findsNothing);
    },
  );
}
