import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

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
        find.widgetWithText(FilledButton, l10n('profile.delete_account')),
      );
    }

    testWidgets('shows data deletion timeline info', (tester) async {
      await pumpDialog(tester);

      expect(
        find.text(l10n('profile.delete_account_timeline')),
        findsOneWidget,
      );
    });

    testWidgets('delete button is disabled initially', (tester) async {
      await pumpDialog(tester);
      final button = findDeleteButton(tester);
      expect(button.onPressed, isNull);
    });

    testWidgets('delete button enables when password is entered', (
      tester,
    ) async {
      await pumpDialog(tester);

      await tester.enterText(find.byType(TextField), 'password123');
      await tester.pump();

      final button = findDeleteButton(tester);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('delete button stays disabled without password', (
      tester,
    ) async {
      await pumpDialog(tester);

      await tester.pump();

      final button = findDeleteButton(tester);
      expect(button.onPressed, isNull);
    });

    testWidgets('dialog only asks for password verification', (tester) async {
      await pumpDialog(tester);

      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('DELETE'), findsNothing);
    });

    testWidgets('cancel returns null', (tester) async {
      String? dialogResult = 'sentinel';

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
      await tester.tap(find.text(l10n('common.cancel')));
      await tester.pumpAndSettle();

      expect(dialogResult, isNull);
    });

    testWidgets('confirm returns password when password entered', (
      tester,
    ) async {
      String? dialogResult;

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

      // Enter password
      await tester.enterText(find.byType(TextField), 'myPassword123!');
      await tester.pump();

      // Tap delete button
      await tester.tap(
        find.widgetWithText(FilledButton, l10n('profile.delete_account')),
      );
      await tester.pumpAndSettle();

      expect(dialogResult, equals('myPassword123!'));
    });
  });
}
