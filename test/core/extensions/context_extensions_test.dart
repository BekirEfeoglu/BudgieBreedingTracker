import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/extensions/context_extensions.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/action_feedback_providers.dart';

void main() {
  group('ContextExtensions', () {
    testWidgets('theme returns ThemeData', (tester) async {
      late ThemeData captured;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              captured = context.theme;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(captured, isA<ThemeData>());
    });

    testWidgets('colorScheme returns ColorScheme', (tester) async {
      late ColorScheme captured;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(primary: Colors.red),
          ),
          home: Builder(
            builder: (context) {
              captured = context.colorScheme;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(captured.primary, Colors.red);
    });

    testWidgets('textTheme returns TextTheme', (tester) async {
      late TextTheme captured;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              captured = context.textTheme;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(captured, isA<TextTheme>());
    });

    testWidgets('screenSize returns non-zero dimensions', (tester) async {
      late Size captured;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              captured = context.screenSize;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(captured.width, greaterThan(0));
      expect(captured.height, greaterThan(0));
    });

    testWidgets('screenWidth and screenHeight return positive values', (
      tester,
    ) async {
      late double width;
      late double height;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              width = context.screenWidth;
              height = context.screenHeight;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(width, greaterThan(0));
      expect(height, greaterThan(0));
    });

    testWidgets('showSnackBar displays a default SnackBar', (tester) async {
      ActionFeedbackService.resetForTesting();
      final received = <ActionFeedback>[];
      final sub = ActionFeedbackService.stream.listen(received.add);
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => context.showSnackBar('Test message'),
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      // Default (non-error) messages go through ActionFeedbackService
      expect(received, hasLength(1));
      expect(received.first.message, 'Test message');
      expect(received.first.type, ActionFeedbackType.info);
    });

    testWidgets('showSnackBar with isError uses error color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () =>
                      context.showSnackBar('Error!', isError: true),
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Error!'), findsOneWidget);
    });

    testWidgets('showSnackBar with isSuccess uses ActionFeedbackService', (tester) async {
      ActionFeedbackService.resetForTesting();
      final received = <ActionFeedback>[];
      final sub = ActionFeedbackService.stream.listen(received.add);
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () =>
                      context.showSnackBar('Done!', isSuccess: true),
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      // Success messages go through ActionFeedbackService with success type
      expect(received, hasLength(1));
      expect(received.first.message, 'Done!');
      expect(received.first.type, ActionFeedbackType.success);
    });
  });
}
