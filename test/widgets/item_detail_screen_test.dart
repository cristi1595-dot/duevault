import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duevault_app/models/vault_item.dart';
import 'package:duevault_app/providers/vault_provider.dart';
import 'package:duevault_app/providers/currency_provider.dart';
import 'package:duevault_app/repositories/vault_repository.dart';
import 'package:duevault_app/main.dart';
import 'package:duevault_app/screens/item_detail_screen.dart';
import 'package:duevault_app/theme/app_theme.dart';

class MockVaultNotifier extends VaultNotifier {
  final List<VaultItem> _items;
  MockVaultNotifier(this._items);

  @override
  List<VaultItem> build() {
    return _items;
  }

  @override
  Future<void> updatePaidStatus(int id, bool isPaid) async {
    final index = state.indexWhere((i) => i.id == id);
    if (index != -1) {
      final updated = state[index]..isPaid = isPaid;
      state = [...state]..[index] = updated;
    }
  }

  @override
  Future<void> toggleArchiveStatus(int id, bool isArchived) async {
    final index = state.indexWhere((i) => i.id == id);
    if (index != -1) {
      final updated = state[index]..isArchived = isArchived;
      state = [...state]..[index] = updated;
    }
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
    required VaultItem item,
    List<VaultItem>? allItems,
    Currency currency = const Currency('USD', '\$'),
    bool isDark = true,
  }) {
    final items = allItems ?? [item];
    return ProviderScope(
      overrides: [
        vaultProvider.overrideWith(() => MockVaultNotifier(items)),
        currencyProvider.overrideWith((ref) => FakeCurrencyNotifier(currency)),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: ItemDetailScreen(item: item),
      ),
    );
  }

  group('ItemDetailScreen - Design System & UI Tests', () {
    testWidgets('Renders Hero Bento Card with category, title, bold amount and status badge', (tester) async {
      final item = VaultItem()
        ..id = 1
        ..title = 'Electricity Bill'
        ..category = 'Utilities'
        ..itemType = 'Bill'
        ..amount = 142.50
        ..dueDate = DateTime.now().add(const Duration(days: 10));

      await tester.pumpWidget(createTestWidget(item: item));
      await tester.pumpAndSettle();

      expect(find.text('Bill Details'), findsOneWidget);
      expect(find.text('Electricity Bill'), findsOneWidget);
      expect(find.text('UTILITIES'), findsOneWidget);
      expect(find.text('\$142.50'), findsOneWidget);
      expect(find.text('amount due'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Mark as Paid'), findsOneWidget);
    });

    testWidgets('Renders Auto-Pay banner when directDebit is true', (tester) async {
      final item = VaultItem()
        ..id = 2
        ..title = 'Mortgage Loan'
        ..category = 'Housing'
        ..itemType = 'Bill'
        ..amount = 1200.00
        ..dueDate = DateTime.now().add(const Duration(days: 5))
        ..directDebit = true;

      await tester.pumpWidget(createTestWidget(item: item));
      await tester.pumpAndSettle();

      expect(find.text('Auto-Pay (Funds Reserved)'), findsOneWidget);
      expect(find.text('Money is set aside; debited automatically on due date.'), findsOneWidget);
    });

    testWidgets('Tapping Mark as Paid updates status and shows undo snackbar', (tester) async {
      final item = VaultItem()
        ..id = 3
        ..title = 'Broadband Internet'
        ..category = 'Telecom'
        ..itemType = 'Bill'
        ..amount = 49.99
        ..dueDate = DateTime.now().add(const Duration(days: 4));

      await tester.pumpWidget(createTestWidget(item: item));
      await tester.pumpAndSettle();

      expect(find.text('Mark as Paid'), findsOneWidget);
      await tester.tap(find.text('Mark as Paid'));
      await tester.pumpAndSettle();

      expect(find.text('Broadband Internet marked as paid'), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);
      expect(find.text('Mark as Unpaid'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 3500));
    });

    testWidgets('Renders Document Details correctly with expiration timeline', (tester) async {
      final doc = VaultItem()
        ..id = 4
        ..title = 'Passport'
        ..category = 'Identity'
        ..itemType = 'Document'
        ..dueDate = DateTime.now().add(const Duration(days: 180));

      await tester.pumpWidget(createTestWidget(item: doc));
      await tester.pumpAndSettle();

      expect(find.text('Document Details'), findsOneWidget);
      expect(find.text('Passport'), findsOneWidget);
      expect(find.text('EXPIRATION TIMELINE'), findsOneWidget);
      expect(find.text('Expiry Date'), findsOneWidget);
      expect(find.text('Mark as Renewed'), findsOneWidget);
    });

    testWidgets('Sticky Bottom Bar includes Archive action button', (tester) async {
      final item = VaultItem()
        ..id = 5
        ..title = 'Water Bill'
        ..category = 'Utilities'
        ..itemType = 'Bill'
        ..amount = 25.00
        ..dueDate = DateTime.now().add(const Duration(days: 2));

      await tester.pumpWidget(createTestWidget(item: item));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
    });
  });
}
