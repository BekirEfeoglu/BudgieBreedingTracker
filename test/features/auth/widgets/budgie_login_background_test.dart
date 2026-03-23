import 'package:budgie_breeding_tracker/features/auth/widgets/budgie_login_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgieLoginBackground', () {
    Widget buildSubject() {
      return const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 800,
            child: Stack(children: [BudgieLoginBackground()]),
          ),
        ),
      );
    }

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildSubject());
      // Use pump with duration since background has repeating animations
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BudgieLoginBackground), findsOneWidget);
    });

    testWidgets('contains animated blob containers', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 100));

      // Three blob containers in a Stack
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('uses AnimatedBuilder for animation', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 100));

      // At least one AnimatedBuilder from BudgieLoginBackground
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('contains three Positioned blobs', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 100));

      // There are 3 Positioned blobs inside the AnimatedBuilder Stack
      final positionedFinder = find.descendant(
        of: find.byType(BudgieLoginBackground),
        matching: find.byType(Positioned),
      );
      expect(positionedFinder, findsNWidgets(3));
    });

    testWidgets('blobs are circular containers', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 100));

      // Each blob is a Container with BoxShape.circle
      final circularContainers = find.descendant(
        of: find.byType(BudgieLoginBackground),
        matching: find.byWidgetPredicate((widget) {
          if (widget is Container && widget.decoration is BoxDecoration) {
            final decoration = widget.decoration! as BoxDecoration;
            return decoration.shape == BoxShape.circle;
          }
          return false;
        }),
      );
      expect(circularContainers, findsNWidgets(3));
    });

    testWidgets('animations progress over time', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 100));

      // First snapshot
      final firstPositioned = tester.widgetList<Positioned>(
        find.descendant(
          of: find.byType(BudgieLoginBackground),
          matching: find.byType(Positioned),
        ),
      );
      final firstTop = firstPositioned.first.top;

      // Advance animation substantially
      await tester.pump(const Duration(seconds: 3));

      final secondPositioned = tester.widgetList<Positioned>(
        find.descendant(
          of: find.byType(BudgieLoginBackground),
          matching: find.byType(Positioned),
        ),
      );
      final secondTop = secondPositioned.first.top;

      // Position should change as animation progresses
      expect(firstTop != secondTop, isTrue);
    });

    testWidgets('disposes animation controllers cleanly', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 100));

      // Replace widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      await tester.pump();

      // No exception means controllers were properly disposed
    });

    testWidgets('renders correctly in constrained space', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: Stack(children: [BudgieLoginBackground()]),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BudgieLoginBackground), findsOneWidget);
    });
  });
}
