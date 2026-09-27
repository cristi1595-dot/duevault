import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:duevault_app/services/app_review_service.dart';
import 'package:duevault_app/repositories/vault_repository.dart';
import 'package:duevault_app/models/app_config.dart';

class MockVaultRepository extends Mock implements VaultRepository {}
class MockWidgetRef extends Mock implements WidgetRef {}
class MockBuildContext extends Mock implements BuildContext {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockVaultRepository mockRepository;
  late MockWidgetRef mockRef;
  late MockBuildContext mockContext;
  late AppReviewService service;

  setUpAll(() {
    registerFallbackValue(AppConfig());
  });

  setUp(() {
    mockRepository = MockVaultRepository();
    mockRef = MockWidgetRef();
    mockContext = MockBuildContext();
    service = AppReviewService(mockRepository);
  });

  group('AppReviewService.incrementActionCounter', () {
    test('increments counter when app is not rated', () async {
      final config = AppConfig()
        ..hasRatedApp = false
        ..successfulActionsCount = 0;

      when(() => mockRepository.getConfig()).thenAnswer((_) async => config);
      when(() => mockRepository.updateConfig(any())).thenAnswer((_) async {});

      await service.incrementActionCounter(mockRef, mockContext);

      expect(config.successfulActionsCount, equals(1));
      verify(() => mockRepository.updateConfig(config)).called(1);
    });

    test('does nothing when app has already been rated', () async {
      final config = AppConfig()
        ..hasRatedApp = true
        ..successfulActionsCount = 0;

      when(() => mockRepository.getConfig()).thenAnswer((_) async => config);

      await service.incrementActionCounter(mockRef, mockContext);

      expect(config.successfulActionsCount, equals(0));
      verifyNever(() => mockRepository.updateConfig(any()));
    });

    test('handles exceptions gracefully without crashing and logs with stack trace', () async {
      when(() => mockRepository.getConfig()).thenThrow(Exception('Database error'));

      expect(
        () => service.incrementActionCounter(mockRef, mockContext),
        returnsNormally,
      );
    });
  });
}
