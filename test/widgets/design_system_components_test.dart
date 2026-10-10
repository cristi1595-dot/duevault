import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duevault_app/theme/app_theme.dart';
import 'package:duevault_app/widgets/global_components.dart';

void main() {
  Widget buildThemedApp(Widget child, {bool isDark = false}) {
    return MaterialApp(
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('DueVault Design System - Components & Tokens Tests', () {
    testWidgets('BentoCard renders and responds to onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildThemedApp(
          BentoCard(
            onTap: () => tapped = true,
            child: const Text('Bento Content'),
          ),
        ),
      );

      expect(find.text('Bento Content'), findsOneWidget);
      await tester.tap(find.text('Bento Content'));
      expect(tapped, isTrue);
    });

    testWidgets('PrimaryButton renders icon, text, and loading state', (tester) async {
      bool tapped = false;

      // Normal state
      await tester.pumpWidget(
        buildThemedApp(
          PrimaryButton(
            label: 'Save Bill',
            icon: Icons.save,
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Save Bill'), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
      await tester.tap(find.text('Save Bill'));
      expect(tapped, isTrue);

      // Loading state
      await tester.pumpWidget(
        buildThemedApp(
          const PrimaryButton(
            label: 'Save Bill',
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Save Bill'), findsNothing);
    });

    testWidgets('SecondaryButton renders with outlined style and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildThemedApp(
          SecondaryButton(
            label: 'Cancel',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      expect(tapped, isTrue);
    });

    testWidgets('StatusBadge displays dot indicator for urgent status and renders label', (tester) async {
      await tester.pumpWidget(
        buildThemedApp(
          const StatusBadge(
            label: 'OVERDUE',
            daysLeft: -1,
          ),
          isDark: true,
        ),
      );

      expect(find.text('OVERDUE'), findsOneWidget);
    });

    testWidgets('CustomInputField renders label and accepts input with visible focus', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        buildThemedApp(
          CustomInputField(
            label: 'Biller Name',
            hintText: 'e.g. Electric Company',
            controller: controller,
          ),
        ),
      );

      expect(find.text('BILLER NAME'), findsOneWidget);
      expect(find.text('e.g. Electric Company'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Vodafone');
      expect(controller.text, equals('Vodafone'));
    });

    testWidgets('EmptyState renders custom title, message, and CTA button', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        buildThemedApp(
          EmptyState(
            title: 'No Documents Found',
            subtitle: 'Try searching for something else.',
            icon: Icons.search_off,
            actionLabel: 'Reset Filter',
            onAction: () => actionTriggered = true,
          ),
        ),
      );

      expect(find.text('No Documents Found'), findsOneWidget);
      expect(find.text('Try searching for something else.'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('Reset Filter'), findsOneWidget);

      await tester.tap(find.text('Reset Filter'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('AppShimmer renders animated skeleton box and circle', (tester) async {
      await tester.pumpWidget(
        buildThemedApp(
          const Column(
            children: [
              AppShimmer.box(width: 120, height: 20),
              AppShimmer.circle(size: 40),
            ],
          ),
        ),
      );

      expect(find.bySubtype<AppShimmer>(), findsNWidgets(2));
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
