import 'package:budgie_breeding_tracker/features/auth/widgets/budgie_character.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/budgie_login_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  group('BudgieCharacter', () {
    testWidgets('renders without error with required params', (tester) async {
      await pumpWidgetSimple(
        tester,
        const BudgieCharacter(bodyColor: BudgieLoginPalette.maleBudgie),
      );

      expect(find.byType(BudgieCharacter), findsOneWidget);
    });

    testWidgets('renders with default parameters', (tester) async {
      await pumpWidgetSimple(
        tester,
        const BudgieCharacter(bodyColor: BudgieLoginPalette.maleBudgie),
      );

      // Widget tree should have Transform.rotate for body wobble
      expect(find.byType(Transform), findsWidgets);
      // Stack is the main layout container
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('renders with male budgie colors', (tester) async {
      await pumpWidgetSimple(
        tester,
        const BudgieCharacter(
          bodyColor: BudgieLoginPalette.maleBudgie,
          cheekColor: BudgieLoginPalette.maleCheck,
        ),
      );

      expect(find.byType(BudgieCharacter), findsOneWidget);
    });

    testWidgets('renders with female budgie colors', (tester) async {
      await pumpWidgetSimple(
        tester,
        const BudgieCharacter(
          bodyColor: BudgieLoginPalette.femaleBudgie,
          cheekColor: BudgieLoginPalette.femaleCheck,
          isLeft: false,
        ),
      );

      expect(find.byType(BudgieCharacter), findsOneWidget);
    });

    testWidgets('has correct SizedBox dimensions', (tester) async {
      await pumpWidgetSimple(
        tester,
        const BudgieCharacter(bodyColor: BudgieLoginPalette.maleBudgie),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.byType(SizedBox).first,
      );
      expect(sizedBox.width, 64);
      expect(sizedBox.height, 85);
    });

    testWidgets('renders when isBlinking is true', (tester) async {
      await pumpWidgetSimple(
        tester,
        const BudgieCharacter(
          bodyColor: BudgieLoginPalette.maleBudgie,
          isBlinking: true,
        ),
      );

      expect(find.byType(BudgieCharacter), findsOneWidget);
    });

    testWidgets('renders when isSad is true', (tester) async {
      await pumpWidgetSimple(
        tester,
        const BudgieCharacter(
          bodyColor: BudgieLoginPalette.maleBudgie,
          isSad: true,
        ),
      );

      expect(find.byType(BudgieCharacter), findsOneWidget);
      // AnimatedPositioned is used for sad head movement
      expect(find.byType(AnimatedPositioned), findsWidgets);
    });

    testWidgets('renders when isCoveringEyes is true', (tester) async {
      await pumpWidgetSimple(
        tester,
        const BudgieCharacter(
          bodyColor: BudgieLoginPalette.maleBudgie,
          isCoveringEyes: true,
        ),
      );

      expect(find.byType(BudgieCharacter), findsOneWidget);
      // AnimatedRotation is used for the wing covering eyes
      expect(find.byType(AnimatedRotation), findsOneWidget);
    });

    testWidgets('renders with head rotation applied', (tester) async {
      await pumpWidgetSimple(
        tester,
        const BudgieCharacter(
          bodyColor: BudgieLoginPalette.maleBudgie,
          headRotation: 0.3,
        ),
      );

      expect(find.byType(BudgieCharacter), findsOneWidget);
      // TweenAnimationBuilder handles head rotation
      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    });

    testWidgets('renders with wing flap animation value', (tester) async {
      await pumpWidgetSimple(
        tester,
        const BudgieCharacter(
          bodyColor: BudgieLoginPalette.maleBudgie,
          wingFlapValue: 0.5,
        ),
      );

      expect(find.byType(BudgieCharacter), findsOneWidget);
    });

    testWidgets('renders with body wobble animation value', (tester) async {
      await pumpWidgetSimple(
        tester,
        const BudgieCharacter(
          bodyColor: BudgieLoginPalette.maleBudgie,
          bodyWobbleValue: 0.75,
        ),
      );

      expect(find.byType(BudgieCharacter), findsOneWidget);
    });

    testWidgets('renders right-facing character when isLeft is false', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        const BudgieCharacter(
          bodyColor: BudgieLoginPalette.femaleBudgie,
          isLeft: false,
        ),
      );

      expect(find.byType(BudgieCharacter), findsOneWidget);
    });

    testWidgets('contains AnimatedContainer for eye', (tester) async {
      await pumpWidgetSimple(
        tester,
        const BudgieCharacter(bodyColor: BudgieLoginPalette.maleBudgie),
      );

      // The eye is rendered as an AnimatedContainer
      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets('renders with all states combined', (tester) async {
      // Test with multiple state modifiers at once
      await pumpWidgetSimple(
        tester,
        const BudgieCharacter(
          bodyColor: BudgieLoginPalette.maleBudgie,
          cheekColor: BudgieLoginPalette.maleCheck,
          headRotation: 0.2,
          isCoveringEyes: true,
          isSad: false,
          isBlinking: false,
          isLeft: true,
          wingFlapValue: 0.3,
          bodyWobbleValue: 0.6,
        ),
      );

      expect(find.byType(BudgieCharacter), findsOneWidget);
    });

    testWidgets('uses belly overlay color from BudgieLoginPalette', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        const BudgieCharacter(bodyColor: BudgieLoginPalette.maleBudgie),
      );

      // Belly is a Container with bellyOverlay color — just verify it renders
      expect(find.byType(BudgieCharacter), findsOneWidget);
    });
  });
}
