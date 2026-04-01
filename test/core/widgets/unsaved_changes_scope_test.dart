import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/unsaved_changes_scope.dart';

import '../../helpers/test_localization.dart';

void main() {
  Future<void> pumpSubject(
    WidgetTester tester, {
    required bool isDirty,
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    await pumpLocalizedApp(
      tester,
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => UnsavedChangesScope(
                      isDirty: isDirty,
                      child: const Scaffold(body: Text('Form Screen')),
                    ),
                  ),
                );
              },
              child: const Text('Open Form'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Form'));
    await tester.pumpAndSettle();
    expect(find.text('Form Screen'), findsOneWidget);
  }

  group('UnsavedChangesScope', () {
    testWidgets('pops immediately when form is clean', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await pumpSubject(tester, isDirty: false, navigatorKey: navigatorKey);

      await navigatorKey.currentState!.maybePop();
      await tester.pumpAndSettle();

      expect(find.text('Form Screen'), findsNothing);
      expect(find.text('Open Form'), findsOneWidget);
      expect(find.text('common.unsaved_changes'), findsNothing);
    });

    testWidgets('shows confirmation dialog when form is dirty', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await pumpSubject(tester, isDirty: true, navigatorKey: navigatorKey);

      await navigatorKey.currentState!.maybePop();
      await tester.pumpAndSettle();

      expect(find.text('Form Screen'), findsOneWidget);
      expect(find.text('common.unsaved_changes'), findsOneWidget);
      expect(find.text('common.unsaved_changes_message'), findsOneWidget);
      expect(find.text('common.cancel'), findsOneWidget);
      expect(find.text('common.discard'), findsOneWidget);
    });

    testWidgets('stays on screen when cancel is tapped', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await pumpSubject(tester, isDirty: true, navigatorKey: navigatorKey);

      await navigatorKey.currentState!.maybePop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('common.cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Form Screen'), findsOneWidget);
      expect(find.text('Open Form'), findsNothing);
    });

    testWidgets('pops when discard is confirmed', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await pumpSubject(tester, isDirty: true, navigatorKey: navigatorKey);

      await navigatorKey.currentState!.maybePop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('common.discard'));
      await tester.pumpAndSettle();

      expect(find.text('Form Screen'), findsNothing);
      expect(find.text('Open Form'), findsOneWidget);
    });
  });
}
