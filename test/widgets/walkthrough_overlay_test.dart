import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:duevault_app/widgets/walkthrough_overlay.dart';
import 'package:duevault_app/theme/app_theme.dart';

void main() {
  Widget buildTestWidget({
    required VoidCallback onFinished,
    required VoidCallback onSkipped,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: WalkthroughOverlay(
        onFinished: onFinished,
        onSkipped: onSkipped,
      ),
    );
  }

  group('WalkthroughOverlay 6-Step Guided Tour Tests', () {
    testWidgets('Renders Step 1 (Financial & Document Overview)', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          onFinished: () {},
          onSkipped: () {},
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('STEP 1 OF 6'), findsOneWidget);
      expect(find.text('Financial & Document Overview'), findsOneWidget);
      expect(find.text('Skip Tour'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Steps sequentially from Step 1 through Step 6 to completion', (tester) async {
      bool finishedCalled = false;

      await tester.pumpWidget(
        buildTestWidget(
          onFinished: () => finishedCalled = true,
          onSkipped: () {},
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      // Step 1 -> Step 2
      expect(find.text('STEP 1 OF 6'), findsOneWidget);
      expect(find.text('Financial & Document Overview'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));

      // Step 2: Profile & Account (Home Only)
      expect(find.text('STEP 2 OF 6'), findsOneWidget);
      expect(find.text('Profile & Account (Home Only)'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));

      // Step 3: Fast Add & AI Scanner
      expect(find.text('STEP 3 OF 6'), findsOneWidget);
      expect(find.text('Fast Add & AI Scanner'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));

      // Step 4: Dedicated Bills Hub
      expect(find.text('STEP 4 OF 6'), findsOneWidget);
      expect(find.text('Dedicated Bills Hub'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));

      // Step 5: Secure Documents Hub
      expect(find.text('STEP 5 OF 6'), findsOneWidget);
      expect(find.text('Secure Documents Hub'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 400));

      // Step 6: Global Settings Hub & "Got it" button
      expect(find.text('STEP 6 OF 6'), findsOneWidget);
      expect(find.text('Global Settings Hub'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);

      // Finish tour
      await tester.tap(find.text('Got it'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(finishedCalled, isTrue);
    });

    testWidgets('Tapping Skip Tour triggers onSkipped callback', (tester) async {
      bool skippedCalled = false;

      await tester.pumpWidget(
        buildTestWidget(
          onFinished: () {},
          onSkipped: () => skippedCalled = true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Skip Tour'), findsOneWidget);
      await tester.tap(find.text('Skip Tour'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(skippedCalled, isTrue);
    });
  });
}
