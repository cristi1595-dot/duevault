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

  Finder findMainCardContainer() {
    return find.byWidgetPredicate((w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).gradient is LinearGradient
    );
  }

  group('FinancialBentoCard Status Tests', () {
    testWidgets('Red Status Test: Overdue bill triggers Urgent state', (WidgetTester tester) async {
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

      // Verify Red Status properties
      expect(find.text('ACTION REQUIRED'), findsOneWidget);
      expect(find.text('Includes £100 overdue'), findsOneWidget);

      // Verify the container decoration has the correct status color
      final container = tester.widget<Container>(findMainCardContainer());
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(border.top.color, AppTheme.urgentRed.withValues(alpha: 0.15));

      final gradient = decoration.gradient as LinearGradient;
      final expectedStartColor = Color.alphaBlend(
        AppTheme.urgentRed.withValues(alpha: 0.08),
        const Color(0xFF1C2028),
      );
      expect(gradient.colors[0], expectedStartColor);
    });

    testWidgets('Red Status Test: Bill due in 2 days triggers Urgent state', (WidgetTester tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final urgentBill = VaultItem()
        ..itemType = 'Bill'
        ..isPaid = false
        ..dueDate = today.add(const Duration(days: 2))
        ..amount = 50.0
        ..title = 'Due in 2 days';

      await tester.pumpWidget(createTestWidget(items: [urgentBill], isDark: true));
      await tester.pumpAndSettle();

      // Verify Red Status properties
      expect(find.text('ACTION REQUIRED'), findsOneWidget);
      
      final container = tester.widget<Container>(findMainCardContainer());
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(border.top.color, AppTheme.urgentRed.withValues(alpha: 0.15));
    });

    testWidgets('Yellow Status Test: Bill due in 5 days triggers Warning state', (WidgetTester tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final warningBill = VaultItem()
        ..itemType = 'Bill'
        ..isPaid = false
        ..dueDate = today.add(const Duration(days: 5))
        ..amount = 150.0
        ..title = 'Due in 5 days';

      await tester.pumpWidget(createTestWidget(items: [warningBill], isDark: true));
      await tester.pumpAndSettle();

      // Verify Yellow Status properties
      expect(find.text('UPCOMING DUE'), findsOneWidget);

      final container = tester.widget<Container>(findMainCardContainer());
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(border.top.color, AppTheme.warningYellow.withValues(alpha: 0.15));
    });

    testWidgets('Green Status Test: Bill due in 8 days triggers Safe state', (WidgetTester tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final safeBill = VaultItem()
        ..itemType = 'Bill'
        ..isPaid = false
        ..dueDate = today.add(const Duration(days: 8))
        ..amount = 200.0
        ..title = 'Due in 8 days';

      await tester.pumpWidget(createTestWidget(items: [safeBill], isDark: true));
      await tester.pumpAndSettle();

      // Verify Green Status properties
      expect(find.text('ALL CLEAR'), findsOneWidget);

      final container = tester.widget<Container>(findMainCardContainer());
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(border.top.color, AppTheme.safeGreen.withValues(alpha: 0.15));
    });

    testWidgets('Green Status Test: No items triggers Safe state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(items: [], isDark: true));
      await tester.pumpAndSettle();

      // Verify Green Status properties
      expect(find.text('ALL CLEAR'), findsOneWidget);

      final container = tester.widget<Container>(findMainCardContainer());
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(border.top.color, AppTheme.safeGreen.withValues(alpha: 0.15));
    });

    testWidgets('Light Theme Test: Correct alphaBlend start color used', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(items: [], isDark: false));
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(findMainCardContainer());
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;
      
      // Border color in light mode: statusColor (safeGreen) with 0.22 alpha
      expect(border.top.color, AppTheme.safeGreen.withValues(alpha: 0.22));

      final gradient = decoration.gradient as LinearGradient;
      final expectedStartColor = Color.alphaBlend(
        AppTheme.safeGreen.withValues(alpha: 0.05),
        Colors.white,
      );
      expect(gradient.colors[0], expectedStartColor);
    });
  });
}
