import 'package:budgie_breeding_tracker/features/auth/widgets/budgie_login_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgieLoginPalette', () {
    group('static color constants', () {
      test('maleBudgie is correct color', () {
        expect(BudgieLoginPalette.maleBudgie, const Color(0xFF7EC8C8));
      });

      test('femaleBudgie is correct color', () {
        expect(BudgieLoginPalette.femaleBudgie, const Color(0xFFFFD166));
      });

      test('babyBudgie is correct color', () {
        expect(BudgieLoginPalette.babyBudgie, const Color(0xFFA8E6CF));
      });

      test('leaf is correct color', () {
        expect(BudgieLoginPalette.leaf, const Color(0xFF8BC98B));
      });

      test('branch is correct color', () {
        expect(BudgieLoginPalette.branch, const Color(0xFF8B6B4A));
      });

      test('branchBark is correct color', () {
        expect(BudgieLoginPalette.branchBark, const Color(0xFF6B4F3A));
      });

      test('nestStraw is correct color', () {
        expect(BudgieLoginPalette.nestStraw, const Color(0xFFD4A373));
      });

      test('nestLine is correct color', () {
        expect(BudgieLoginPalette.nestLine, const Color(0xFFBC8A5F));
      });

      test('eggShell is correct color', () {
        expect(BudgieLoginPalette.eggShell, const Color(0xFFFFF8F0));
      });

      test('eggSpot is correct color', () {
        expect(BudgieLoginPalette.eggSpot, const Color(0xFFE8DDD0));
      });

      test('beak is correct color', () {
        expect(BudgieLoginPalette.beak, const Color(0xFFFFA07A));
      });

      test('eye is correct color', () {
        expect(BudgieLoginPalette.eye, const Color(0xFF2D2D2D));
      });

      test('maleCheck is correct color', () {
        expect(BudgieLoginPalette.maleCheck, const Color(0xFF7AB8D4));
      });

      test('femaleCheck is correct color', () {
        expect(BudgieLoginPalette.femaleCheck, const Color(0xFFFFB5C5));
      });

      test('blobGreen is correct color', () {
        expect(BudgieLoginPalette.blobGreen, const Color(0xFFE2F0CB));
      });

      test('blobBlue is correct color', () {
        expect(BudgieLoginPalette.blobBlue, const Color(0xFFD4E8F0));
      });
    });

    group('theme-aware methods', () {
      testWidgets('background returns light color in light theme', (
        tester,
      ) async {
        late Color result;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Builder(
              builder: (context) {
                result = BudgieLoginPalette.background(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(result, const Color(0xFFF4F9F9));
      });

      testWidgets('background returns surface color in dark theme', (
        tester,
      ) async {
        late Color result;
        late Color expectedSurface;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Builder(
              builder: (context) {
                result = BudgieLoginPalette.background(context);
                expectedSurface = Theme.of(context).colorScheme.surface;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(result, expectedSurface);
      });

      testWidgets('cardSurface returns white-ish in light theme', (
        tester,
      ) async {
        late Color result;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Builder(
              builder: (context) {
                result = BudgieLoginPalette.cardSurface(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // Light: white with 0.92 alpha
        expect(result, Colors.white.withValues(alpha: 0.92));
      });

      testWidgets('cardSurface returns dark variant in dark theme', (
        tester,
      ) async {
        late Color result;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Builder(
              builder: (context) {
                result = BudgieLoginPalette.cardSurface(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // Dark mode returns surfaceContainerLowest with alpha 0.95
        // Color.a returns the alpha component as 0.0..1.0 double
        expect(result.a, closeTo(0.95, 0.01));
      });

      testWidgets('cardShadow returns correct alpha in light mode', (
        tester,
      ) async {
        late Color result;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Builder(
              builder: (context) {
                result = BudgieLoginPalette.cardShadow(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // Light: black with alpha 0.06
        expect(result, Colors.black.withValues(alpha: 0.06));
      });

      testWidgets('cardShadow returns correct alpha in dark mode', (
        tester,
      ) async {
        late Color result;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Builder(
              builder: (context) {
                result = BudgieLoginPalette.cardShadow(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // Dark: black with alpha 0.2
        expect(result, Colors.black.withValues(alpha: 0.2));
      });

      testWidgets('bellyOverlay returns correct alpha in light mode', (
        tester,
      ) async {
        late Color result;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Builder(
              builder: (context) {
                result = BudgieLoginPalette.bellyOverlay(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // Light: white with alpha 0.55
        expect(result, Colors.white.withValues(alpha: 0.55));
      });

      testWidgets('bellyOverlay returns correct alpha in dark mode', (
        tester,
      ) async {
        late Color result;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Builder(
              builder: (context) {
                result = BudgieLoginPalette.bellyOverlay(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // Dark: white with alpha 0.25
        expect(result, Colors.white.withValues(alpha: 0.25));
      });
    });
  });
}
