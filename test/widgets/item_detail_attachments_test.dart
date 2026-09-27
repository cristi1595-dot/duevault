import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:duevault_app/models/vault_item.dart';
import 'package:duevault_app/screens/item_detail/item_detail_attachments.dart';
import 'package:duevault_app/theme/app_theme.dart';

class FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/tmp';
  }

  @override
  Future<String?> getTemporaryPath() async {
    return '/tmp';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PathProviderPlatform.instance = FakePathProviderPlatform();
  });

  Widget createTestWidget(VaultItem item) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ItemDetailAttachments(item: item),
          ),
        ),
      ),
    );
  }

  group('ItemDetailAttachments Widget Tests', () {
    testWidgets('Renders shrink when attachedFiles is empty', (WidgetTester tester) async {
      final item = VaultItem()..attachedFiles = [];

      await tester.pumpWidget(createTestWidget(item));
      await tester.pump();

      expect(find.textContaining('ATTACHMENTS'), findsNothing);
    });

    testWidgets('Renders attachment section when attachedFiles is non-empty', (WidgetTester tester) async {
      final item = VaultItem()
        ..attachedFiles = ['test_document.pdf']
        ..cloudFileIds = [];

      await tester.pumpWidget(createTestWidget(item));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('ATTACHMENTS (1)'), findsOneWidget);
    });

    testWidgets('Shows error snackbar when tapping file with no local copy or cloud backup', (WidgetTester tester) async {
      final item = VaultItem()
        ..attachedFiles = ['non_existent.pdf']
        ..cloudFileIds = [];

      await tester.pumpWidget(createTestWidget(item));
      await tester.pump(const Duration(milliseconds: 500));

      final tileFinder = find.byType(GestureDetector).last;
      await tester.tap(tileFinder);
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('File not found locally and has no cloud backup.'),
        findsOneWidget,
      );
    });
  });
}
