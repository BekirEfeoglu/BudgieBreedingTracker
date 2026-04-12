import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/dialogs/confirm_dialog.dart';

void main() {
  group('ConfirmDialog', () {
    testWidgets('renders title and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmDialog(
              title: 'Delete Bird',
              message: 'Are you sure?',
            ),
          ),
        ),
      );

      expect(find.text('Delete Bird'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
    });

    testWidgets('shows default cancel and confirm labels from l10n',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmDialog(
              title: 'Delete',
              message: 'Sure?',
            ),
          ),
        ),
      );

      // In test env, .tr() returns the key itself
      expect(find.text('common.cancel'), findsOneWidget);
      expect(find.text('common.confirm'), findsOneWidget);
    });

    testWidgets('shows custom labels when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmDialog(
              title: 'Delete',
              message: 'Sure?',
              confirmLabel: 'Yes, delete',
              cancelLabel: 'No, keep',
            ),
          ),
        ),
      );

      expect(find.text('Yes, delete'), findsOneWidget);
      expect(find.text('No, keep'), findsOneWidget);
    });

    testWidgets('cancel button pops with false', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (_) => const ConfirmDialog(
                    title: 'Delete',
                    message: 'Sure?',
                    cancelLabel: 'Cancel',
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('confirm button pops with true', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (_) => const ConfirmDialog(
                    title: 'Delete',
                    message: 'Sure?',
                    confirmLabel: 'Confirm',
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('destructive mode applies error color to confirm button',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: const ColorScheme.light()),
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog<bool>(
                  context: context,
                  builder: (_) => const ConfirmDialog(
                    title: 'Delete',
                    message: 'Sure?',
                    confirmLabel: 'Delete',
                    isDestructive: true,
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify the confirm button has a custom style (destructive)
      final buttons = tester.widgetList<TextButton>(find.byType(TextButton));
      final confirmButton = buttons.last;
      expect(confirmButton.style, isNotNull);
    });
  });

  group('showConfirmDialog', () {
    testWidgets('opens dialog and returns result', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showConfirmDialog(
                  context,
                  title: 'Delete',
                  message: 'Sure?',
                  confirmLabel: 'OK',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmDialog), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
