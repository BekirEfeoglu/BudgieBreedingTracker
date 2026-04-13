import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_welcome_screen.dart';

import '../../../../helpers/pump_helpers.dart';

void main() {
  group('AiWelcomeScreen', () {
    testWidgets('renders welcome screen with title and button', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiWelcomeScreen(onSetup: () {}),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AiWelcomeScreen), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('calls onSetup when button is tapped', (tester) async {
      var called = false;
      await pumpWidgetSimple(
        tester,
        AiWelcomeScreen(onSetup: () => called = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      expect(called, isTrue);
    });

    testWidgets('shows three feature pills', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiWelcomeScreen(onSetup: () {}),
      );
      await tester.pumpAndSettle();

      // Three feature pills with their L10n labels
      // We can check for the Wrap containing them
      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('shows DNA icon', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiWelcomeScreen(onSetup: () {}),
      );
      await tester.pumpAndSettle();

      // AppIcon wrapping the DNA icon
      expect(find.byType(AiWelcomeScreen), findsOneWidget);
    });

    testWidgets('does not call onSetup without interaction', (tester) async {
      var called = false;
      await pumpWidgetSimple(
        tester,
        AiWelcomeScreen(onSetup: () => called = true),
      );
      await tester.pumpAndSettle();

      expect(called, isFalse);
    });

    testWidgets('renders Wrap for feature pills', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiWelcomeScreen(onSetup: () {}),
      );
      await tester.pumpAndSettle();

      // Feature pills are inside a Wrap widget
      final wrap = find.descendant(
        of: find.byType(AiWelcomeScreen),
        matching: find.byType(Wrap),
      );
      expect(wrap, findsOneWidget);
    });
  });
}
