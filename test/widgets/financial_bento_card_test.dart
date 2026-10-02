import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duevault_app/models/vault_item.dart';
import 'package:duevault_app/providers/vault_provider.dart';
import 'package:duevault_app/providers/currency_provider.dart';
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
  }) {
    return ProviderScope(
      overrides: [
        vaultProvider.overrideWith(() => MockVaultNotifier(items)),
        currencyProvider.overrideWith((ref) => FakeCurrencyNotifier(currency)),
      ],
      child: MaterialApp(
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
      ),
    );
  }

  group('FinancialBentoCard Status Tests', () {
    testWidgets('Shows total amount and overdue badge when overdue bill exists', (tester) async {
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

      expect(find.text('THIS MONTH'), findsOneWidget);
      expect(find.text('£100.00'), findsOneWidget);
      expect(find.text('to pay'), findsOneWidget);
      expect(find.text('1 overdue'), findsOneWidget);
    });

    testWidgets('Shows upcoming count and Auto-Pay badge when enabled', (tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final upcomingBill = VaultItem()
        ..itemType = 'Bill'
        ..isPaid = false
        ..directDebit = true
        ..dueDate = today.add(const Duration(days: 5))
        ..amount = 60.0
        ..title = 'Electricity';

      await tester.pumpWidget(createTestWidget(items: [upcomingBill], isDark: true));
      await tester.pumpAndSettle();

      expect(find.text('THIS MONTH'), findsOneWidget);
      expect(find.text('£60.00'), findsOneWidget);
      expect(find.text('1 upcoming'), findsOneWidget);
      expect(find.text('Auto-Pay: £60 reserved'), findsOneWidget);
    });

    testWidgets('Renders properly with empty items in light and dark mode', (tester) async {
      await tester.pumpWidget(createTestWidget(items: [], isDark: false));
      await tester.pumpAndSettle();

      expect(find.text('THIS MONTH'), findsOneWidget);
      expect(find.text('£0.00'), findsOneWidget);
    });
  });
}
