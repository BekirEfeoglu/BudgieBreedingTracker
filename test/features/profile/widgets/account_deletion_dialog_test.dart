import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/profile/widgets/account_deletion_dialog.dart';

import '../../../helpers/test_localization.dart';

void main() {
  group('AccountDeletionDialog', () {
    Future<void> pumpDialog(WidgetTester tester) async {
      await pumpLocalizedApp(
        tester,
        const MaterialApp(home: Scaffold(body: AccountDeletionDialog())),
      );
    }

    FilledButton findDeleteButton(WidgetTester tester) {
      return tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'profile.delete_account'),
      );
    }

    testWidgets('delete button is disabled initially', (tester) async {
      await pumpDialog(tester);
      final button = findDeleteButton(tester);
      expect(button.onPressed, isNull);
    });

    testWidgets('delete button remains disabled with wrong text', (
      tester,
    ) async {
      await pumpDialog(tester);

      await tester.enterText(find.byType(TextField), 'wrong text');
      await tester.pump();

      final button = findDeleteButton(tester);
      expect(button.onPressed, isNull);
    });

    testWidgets('delete button enables when DELETE is entered', (
      tester,
    ) async {
      await pumpDialog(tester);

      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();

      final button = findDeleteButton(tester);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('delete button enables with lowercase delete', (
      tester,
    ) async {
      await pumpDialog(tester);

      await tester.enterText(find.byType(TextField), 'delete');
      await tester.pump();

      final button = findDeleteButton(tester);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('delete button enables with mixed case', (tester) async {
      await pumpDialog(tester);

      await tester.enterText(find.byType(TextField), 'Delete');
      await tester.pump();

      final button = findDeleteButton(tester);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('leading/trailing whitespace is trimmed', (tester) async {
      await pumpDialog(tester);

      await tester.enterText(find.byType(TextField), '  DELETE  ');
      await tester.pump();

      final button = findDeleteButton(tester);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('cancel returns false', (tester) async {
      bool? dialogResult;

      await pumpLocalizedApp(
        tester,
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await AccountDeletionDialog.show(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('common.cancel'));
      await tester.pumpAndSettle();

      expect(dialogResult, isFalse);
    });

    testWidgets('confirm returns true when phrase is entered', (tester) async {
      bool? dialogResult;

      await pumpLocalizedApp(
        tester,
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await AccountDeletionDialog.show(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Enter confirmation phrase (language-neutral: DELETE)
      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();

      // Tap delete button
      await tester.tap(
        find.widgetWithText(FilledButton, 'profile.delete_account'),
      );
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue);
    });
  });
}
