import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/auth/widgets/budgie_login_background.dart';

void main() {
  group('BudgieLoginBackground', () {
    Widget buildSubject({
      bool reduceMotion = false,
      Size size = const Size(400, 800),
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size, disableAnimations: reduceMotion),
          child: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: const Stack(children: [BudgieLoginBackground()]),
            ),
          ),
        ),
      );
    }

    testWidgets('renders three circular, direction-aware blobs', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BudgieLoginBackground), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BudgieLoginBackground),
          matching: find.byType(PositionedDirectional),
        ),
        findsNWidgets(3),
      );
      final circularContainers = find.descendant(
        of: find.byType(BudgieLoginBackground),
        matching: find.byWidgetPredicate((widget) {
          final decoration = widget is Container ? widget.decoration : null;
          return decoration is BoxDecoration &&
              decoration.shape == BoxShape.circle;
        }),
      );
      expect(circularContainers, findsNWidgets(3));
    });

    testWidgets('animates with paint transforms instead of layout positions', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 100));

      final transforms = find.descendant(
        of: find.byType(BudgieLoginBackground),
        matching: find.byType(Transform),
      );
      expect(transforms, findsNWidgets(3));
      final firstTranslations = tester
          .widgetList<Transform>(transforms)
          .map((widget) => widget.transform.getTranslation())
          .toList();

      await tester.pump(const Duration(seconds: 1));

      final secondTranslations = tester
          .widgetList<Transform>(transforms)
          .map((widget) => widget.transform.getTranslation())
          .toList();
      expect(secondTranslations, isNot(firstTranslations));
    });

    testWidgets('becomes static and settles when reduced motion is enabled', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(reduceMotion: true));

      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(BudgieLoginBackground),
          matching: find.byType(AnimatedBuilder),
        ),
        findsNothing,
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('disposes its controller cleanly', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in constrained space', (tester) async {
      await tester.pumpWidget(buildSubject(size: const Size(200, 300)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BudgieLoginBackground), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
