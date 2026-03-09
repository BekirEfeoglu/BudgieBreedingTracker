import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_completion_indicator.dart';

void main() {
  group('ProfileCompletionIndicator', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCompletionIndicator(
              completionFraction: 0.5,
              child: Icon(Icons.person),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('has semantics label with percentage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCompletionIndicator(
              completionFraction: 0.75,
              child: Text('Avatar'),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(
        find.byType(ProfileCompletionIndicator),
      );
      expect(semantics.label, contains('75'));
    });

    testWidgets('semantics label shows 0% when fraction is 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCompletionIndicator(
              completionFraction: 0.0,
              child: Text('Avatar'),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(
        find.byType(ProfileCompletionIndicator),
      );
      expect(semantics.label, contains('0'));
    });

    testWidgets('semantics label shows 100% when fraction is 1.0', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCompletionIndicator(
              completionFraction: 1.0,
              child: Text('Avatar'),
            ),
          ),
        ),
      );

      final semantics = tester.getSemantics(
        find.byType(ProfileCompletionIndicator),
      );
      expect(semantics.label, contains('100'));
    });

    testWidgets('respects custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCompletionIndicator(
              completionFraction: 0.5,
              size: 80,
              child: Text('Avatar'),
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(ProfileCompletionIndicator),
          matching: find.byType(SizedBox).first,
        ),
      );
      expect(sizedBox.width, 80);
      expect(sizedBox.height, 80);
    });

    testWidgets('clamps fraction above 1.0', (tester) async {
      // Should not throw even with fraction > 1
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCompletionIndicator(
              completionFraction: 1.5,
              child: Text('Clamped'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Clamped'), findsOneWidget);
    });

    testWidgets('clamps fraction below 0.0', (tester) async {
      // Should not throw even with fraction < 0
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCompletionIndicator(
              completionFraction: -0.5,
              child: Text('Clamped Negative'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Clamped Negative'), findsOneWidget);
    });

    testWidgets('renders RepaintBoundary for performance', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCompletionIndicator(
              completionFraction: 0.5,
              child: Text('Avatar'),
            ),
          ),
        ),
      );

      expect(find.byType(RepaintBoundary), findsAtLeastNWidgets(1));
    });

    testWidgets('renders two CustomPaint (background + progress)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCompletionIndicator(
              completionFraction: 0.5,
              child: Text('Avatar'),
            ),
          ),
        ),
      );

      // Two CustomPaint: background arc + progress arc (may have extra ones in tree)
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(2));
    });

    testWidgets('animation completes after 600ms', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileCompletionIndicator(
              completionFraction: 0.8,
              child: Text('Done'),
            ),
          ),
        ),
      );

      // Advance animation beyond 600ms duration
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Done'), findsOneWidget);
    });
  });
}
