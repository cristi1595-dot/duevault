import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duevault_app/models/vault_item.dart';
import 'package:duevault_app/providers/vault_provider.dart';
import 'package:duevault_app/providers/currency_provider.dart';
import 'package:duevault_app/providers/navigation_provider.dart';
import 'package:duevault_app/repositories/vault_repository.dart';
import 'package:duevault_app/screens/home/financial_bento_card.dart';
import 'package:duevault_app/theme/app_theme.dart';

class MockVaultNotifier extends VaultNotifier {
  final List<VaultItem> _items;
  MockVaultNotifier(this._items);

  @override
  List<VaultItem> build() {
    return _items;
  }
}

class FakeCurrencyNotifier extends StateNotifier<Currency> implements CurrencyNotifier {
  FakeCurrencyNotifier(super.state);

  @override
  VaultRepository get repository => throw UnimplementedError();

  @override
  Ref get ref => throw UnimplementedError();

  @override
  Future<void> setCurrency(Currency currency) async {}
}

void main() {
  Widget createTestWidget({
    required List<VaultItem> items,
    Currency currency = const Currency('GBP', '£'),
    bool isDark = true,
    ProviderContainer? container,
  }) {
    final app = MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              FinancialBentoCard(),
            ],
          ),
        ),
      ),
    );

    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: app,
      );
    }

    return ProviderScope(
      overrides: [
        vaultProvider.overrideWith(() => MockVaultNotifier(items)),
        currencyProvider.overrideWith((ref) => FakeCurrencyNotifier(currency)),
      ],
      child: app,
    );
  }

  group('FinancialBentoCard Status Tests', () {
    testWidgets('Shows 2-column Bento Grid with Bills & Documents, and overdue badge', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final overdueBill = VaultItem()
        ..itemType = 'Bill'
        ..isPaid = false
        ..dueDate = today.subtract(const Duration(days: 1))
        ..amount = 100.0
        ..title = 'Overdue Gas';

      await tester.pumpWidget(createTestWidget(items: [overdueBill], isDark: true));
      await tester.pumpAndSettle();

      expect(find.text('BILLS'), findsOneWidget);
      expect(find.text('DOCUMENTS'), findsOneWidget);
      expect(find.text('£100.00'), findsNWidgets(2)); // 7d and 30d
      expect(find.text('1 overdue'), findsOneWidget);
      expect(find.text('0'), findsOneWidget); // 0 docs expiring
    });

    testWidgets('Shows upcoming bills and documents correctly', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final upcomingBill = VaultItem()
        ..itemType = 'Bill'
        ..isPaid = false
        ..dueDate = today.add(const Duration(days: 5))
        ..amount = 60.0
        ..title = 'Electricity';

      final upcomingDoc = VaultItem()
        ..itemType = 'Document'
        ..isPaid = false
        ..dueDate = today.add(const Duration(days: 3))
        ..title = 'ID Card';

      await tester.pumpWidget(createTestWidget(items: [upcomingBill, upcomingDoc], isDark: true));
      await tester.pumpAndSettle();

      expect(find.text('BILLS'), findsOneWidget);
      expect(find.text('DOCUMENTS'), findsOneWidget);
      expect(find.text('£60.00'), findsNWidgets(2));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('expiring'), findsOneWidget);
    });

    testWidgets('Renders properly with empty items in light and dark mode', (tester) async {
      await tester.pumpWidget(createTestWidget(items: [], isDark: false));
      await tester.pumpAndSettle();

      expect(find.text('BILLS'), findsOneWidget);
      expect(find.text('DOCUMENTS'), findsOneWidget);
      expect(find.text('£0.00'), findsNWidgets(2));
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('Tapping Bills column sets bottomNavIndex to 1, Documents sets to 2', (tester) async {
      final container = ProviderContainer(
        overrides: [
          vaultProvider.overrideWith(() => MockVaultNotifier([])),
          currencyProvider.overrideWith((ref) => FakeCurrencyNotifier(const Currency('GBP', '£'))),
        ],
      );

      await tester.pumpWidget(createTestWidget(items: [], container: container));
      await tester.pumpAndSettle();

      expect(container.read(bottomNavIndexProvider), 0);

      // Tap Bills column
      await tester.tap(find.text('BILLS'));
      await tester.pumpAndSettle();
      expect(container.read(bottomNavIndexProvider), 1);

      // Tap Documents column
      await tester.tap(find.text('DOCUMENTS'));
      await tester.pumpAndSettle();
      expect(container.read(bottomNavIndexProvider), 2);
    });
  });
}
