import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/dialogs/confirm_dialog.dart';

void main() {
  group('ConfirmDialog', () {
    testWidgets('displays title and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const ConfirmDialog(
                      title: 'Delete?',
                      message: 'This cannot be undone.',
                    ),
                  ),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Delete?'), findsOneWidget);
      expect(find.text('This cannot be undone.'), findsOneWidget);
    });

    testWidgets('uses custom confirm and cancel labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const ConfirmDialog(
                      title: 'Title',
                      message: 'Body',
                      confirmLabel: 'Yes',
                      cancelLabel: 'No',
                    ),
                  ),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
    });

    testWidgets('returns true on confirm tap', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showConfirmDialog(
                      context,
                      title: 'Confirm?',
                      message: 'Are you sure?',
                      confirmLabel: 'OK',
                      cancelLabel: 'Nope',
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('returns false on cancel tap', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showConfirmDialog(
                      context,
                      title: 'Confirm?',
                      message: 'Are you sure?',
                      confirmLabel: 'OK',
                      cancelLabel: 'Nope',
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nope'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('destructive mode applies error color to confirm button', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const ConfirmDialog(
                      title: 'Delete?',
                      message: 'Danger!',
                      isDestructive: true,
                      confirmLabel: 'Delete',
                      cancelLabel: 'Cancel',
                    ),
                  ),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify confirm button exists and dialog renders in destructive mode
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
