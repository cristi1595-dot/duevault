import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:duevault_app/models/app_config.dart';
import 'package:duevault_app/models/vault_item.dart';
import 'package:duevault_app/providers/database_provider.dart';
import 'package:duevault_app/providers/vault_provider.dart';
import 'package:duevault_app/providers/auth_provider.dart';
import 'package:duevault_app/providers/security_provider.dart';
import 'package:duevault_app/providers/notification_provider.dart';
import 'package:duevault_app/repositories/vault_repository.dart';
import 'package:duevault_app/services/analytics_service.dart';
import 'package:duevault_app/screens/settings_screen.dart';
import 'package:duevault_app/screens/settings/compact_profile_card.dart';
import 'package:duevault_app/screens/settings/storage_reset_sheet.dart';
import 'package:isar_community/isar.dart';

class MockIsar extends Mock implements Isar {}
class MockIsarCollection<T> extends Mock implements IsarCollection<T> {}
class MockVaultRepository extends Mock implements VaultRepository {}
class MockAnalyticsService extends Mock implements AnalyticsService {}

class FakeSecurityNotifier extends StateNotifier<SecurityState> implements SecurityNotifier {
  FakeSecurityNotifier() : super(SecurityState());

  @override
  Future<void> toggleSecurity(bool enabled) async {
    state = state.copyWith(isEnabled: enabled);
  }

  @override
  Future<void> reset() async {
    state = SecurityState();
  }

  @override
  Future<void> openSecuritySettings() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotificationHealthNotifier extends NotificationHealthNotifier {
  FakeNotificationHealthNotifier(super.ref);

  @override
  Future<void> checkHealth() async {
    state = NotificationHealthStatus.healthy;
  }
}

class FakeGlobalNotificationsNotifier extends GlobalNotificationsNotifier {
  FakeGlobalNotificationsNotifier(super.ref);

  @override
  Future<void> toggle(bool enabled) async {
    state = enabled;
  }
}

final kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _TestHttpClient();
}

class _TestHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _TestHttpClientRequest();
}

class _TestHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _TestHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _TestHttpClientResponse();
}

class _TestHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _TestHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  late MockIsar mockIsar;
  late MockIsarCollection<AppConfig> mockConfigCollection;
  late MockVaultRepository mockRepository;
  late MockAnalyticsService mockAnalyticsService;

  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
    registerFallbackValue(AppConfig());
    registerFallbackValue(VaultItem());
  });

  setUp(() {
    mockIsar = MockIsar();
    mockConfigCollection = MockIsarCollection<AppConfig>();
    mockRepository = MockVaultRepository();
    mockAnalyticsService = MockAnalyticsService();

    when(() => mockAnalyticsService.logUserType(any())).thenAnswer((_) async {});
    when(() => mockAnalyticsService.logItemAdded(any())).thenAnswer((_) async {});
    when(() => mockAnalyticsService.logSettingsChanged(any(), any())).thenAnswer((_) async {});

    when(() => mockIsar.appConfigs).thenReturn(mockConfigCollection);
    when(() => mockConfigCollection.get(any())).thenAnswer(
      (_) async => AppConfig()
        ..hasSeenDemo = true
        ..globalNotificationsEnabled = true,
    );
    when(() => mockRepository.getConfig()).thenAnswer(
      (_) async => AppConfig()
        ..hasSeenDemo = true
        ..globalNotificationsEnabled = true,
    );
    when(() => mockIsar.writeTxn<void>(any())).thenAnswer((invocation) {
      final callback = invocation.positionalArguments[0] as Function;
      return (callback() as Future).then((_) => null);
    });
    when(() => mockRepository.updateConfig(any())).thenAnswer((_) async {});
    when(() => mockRepository.getItems(any())).thenAnswer((_) async => []);
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        isarProvider.overrideWith((ref) => mockIsar),
        vaultRepositoryProvider.overrideWithValue(mockRepository),
        analyticsServiceProvider.overrideWithValue(mockAnalyticsService),
        securityProvider.overrideWith((ref) => FakeSecurityNotifier()),
        authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        notificationHealthProvider.overrideWith((ref) => FakeNotificationHealthNotifier(ref)),
        globalNotificationsProvider.overrideWith((ref) => FakeGlobalNotificationsNotifier(ref)),
      ],
      child: const MaterialApp(
        home: SettingsScreen(),
      ),
    );
  }

  group('SettingsScreen - Design System & UI Tests', () {
    testWidgets('Renders all primary section headers, profile card and version footer', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify app bar title
      expect(find.text('Settings'), findsOneWidget);

      // Verify CompactProfileCard is present
      expect(find.byType(CompactProfileCard), findsOneWidget);

      // Verify section headers
      expect(find.text('SECURITY'), findsOneWidget);
      expect(find.text('INTERFACE'), findsOneWidget);
      expect(find.text('ALERTS & NOTIFICATIONS'), findsOneWidget);
      expect(find.text('STORAGE & CLOUD'), findsOneWidget);
      expect(find.text('SUPPORT & FEEDBACK'), findsOneWidget);

      // Verify version footer
      expect(find.text('Version 1.0.1'), findsOneWidget);

      // Verify key tiles
      expect(find.text('Biometric Lock'), findsOneWidget);
      expect(find.text('Primary Currency'), findsOneWidget);
      expect(find.text('App Theme'), findsOneWidget);
      expect(find.text('Smart Reminder Service'), findsOneWidget);
      expect(find.text('Storage Integrity'), findsOneWidget);
      expect(find.text('Rate DueVault'), findsOneWidget);
      expect(find.text('Replay Tutorial'), findsOneWidget);
    });

    testWidgets('Tapping version footer 7 times reveals DEVELOPER section', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final versionFinder = find.text('Version 1.0.1');
      expect(versionFinder, findsOneWidget);

      // Developer section initially not visible
      expect(find.text('DEVELOPER'), findsNothing);

      // Tap 7 times
      for (int i = 0; i < 7; i++) {
        await tester.tap(versionFinder);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // DEVELOPER header should now be visible
      expect(find.text('DEVELOPER'), findsOneWidget);
      expect(find.text('Automated Cloud Sync'), findsOneWidget);
      expect(find.text('Cloud Backup Diagnostics'), findsOneWidget);
      expect(find.text('Force Restore Cloud Backup'), findsOneWidget);
      expect(find.text('Simulate Test Crash'), findsOneWidget);
    });

    testWidgets('Tapping Storage Integrity opens StorageResetSheet bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final storageTile = find.text('Storage Integrity');
      expect(storageTile, findsOneWidget);

      await tester.tap(storageTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Bottom sheet should be visible
      expect(find.byType(StorageResetSheet), findsOneWidget);
      expect(find.text('Storage & Reset'), findsOneWidget);
      expect(find.text('Manage your database and cloud space'), findsOneWidget);
      expect(find.text('Erase All Data (Local)'), findsOneWidget);
    });
  });
}
