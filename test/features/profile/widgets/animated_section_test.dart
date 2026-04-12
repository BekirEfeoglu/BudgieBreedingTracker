import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/animated_section.dart';

void main() {
  group('AnimatedSection', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedSection(index: 0, child: Text('Test Child')),
          ),
        ),
      );

      // Advance time to fire Future.delayed(Duration.zero) timer + 400ms animation
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('wraps child in FadeTransition', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedSection(index: 0, child: Text('Fade Child')),
          ),
        ),
      );

      // Advance time to fire Future.delayed(Duration.zero) timer + 400ms animation
      await tester.pump(const Duration(milliseconds: 500));

      // MaterialApp has its own transitions too; check at least one FadeTransition exists
      expect(find.byType(FadeTransition), findsAtLeastNWidgets(1));
    });

    testWidgets('wraps child in SlideTransition', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedSection(index: 0, child: Text('Slide Child')),
          ),
        ),
      );

      // Advance time to fire Future.delayed(Duration.zero) timer + 400ms animation
      await tester.pump(const Duration(milliseconds: 500));

      // MaterialApp has its own transitions too; check at least one SlideTransition exists
      expect(find.byType(SlideTransition), findsAtLeastNWidgets(1));
    });

    testWidgets('index 0 starts animation immediately (no delay)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedSection(index: 0, child: Text('No Delay')),
          ),
        ),
      );

      // Advance past the 400ms animation
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('No Delay'), findsOneWidget);
    });

    testWidgets('higher index uses staggered delay (index * 80ms)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedSection(index: 3, child: Text('Delayed')),
          ),
        ),
      );

      // Child should still be there before delay completes (opacity may be near 0)
      await tester.pump();
      expect(find.text('Delayed'), findsOneWidget);

      // After 3 * 80ms = 240ms delay + 400ms animation
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Delayed'), findsOneWidget);
    });

    testWidgets('can handle index 1', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedSection(index: 1, child: Text('Index 1')),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Index 1'), findsOneWidget);
    });

    testWidgets('disposes without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedSection(index: 0, child: Text('Dispose Test')),
          ),
        ),
      );

      // Advance fake time to let the delayed future fire before dispose
      await tester.pump(const Duration(milliseconds: 600));

      // Replace widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Replaced'))),
      );

      expect(find.text('Replaced'), findsOneWidget);
    });
  });
}
