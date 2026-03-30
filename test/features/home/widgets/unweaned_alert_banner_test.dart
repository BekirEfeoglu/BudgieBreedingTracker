import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/features/home/widgets/unweaned_alert_banner.dart';

void main() {
  Widget createSubject(int count) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (_, __) => NoTransitionPage(
            child: Scaffold(body: UnweanedAlertBanner(count: count)),
          ),
        ),
        GoRoute(
          path: '/chicks',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: Scaffold(body: Text('Chicks'))),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  group('UnweanedAlertBanner', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(createSubject(3));
      await tester.pump();

      expect(find.byType(UnweanedAlertBanner), findsOneWidget);
    });

    testWidgets('shows nothing (SizedBox.shrink) when count is 0', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(0));
      await tester.pump();

      // count=0 returns SizedBox.shrink — no alert text visible
      expect(find.text(l10n('home.unweaned_alert')), findsNothing);
      expect(find.text(l10n('common.view')), findsNothing);
    });

    testWidgets('shows banner container when count > 0', (tester) async {
      await tester.pumpWidget(createSubject(3));
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('shows unweaned_alert text when count > 0', (tester) async {
      await tester.pumpWidget(createSubject(5));
      await tester.pump();

      expect(find.text(l10n('home.unweaned_alert')), findsOneWidget);
    });

    testWidgets('shows view button when count > 0', (tester) async {
      await tester.pumpWidget(createSubject(2));
      await tester.pump();

      expect(find.text(l10n('common.view')), findsOneWidget);
    });

    testWidgets('tapping view navigates to chicks screen', (tester) async {
      await tester.pumpWidget(createSubject(2));
      await tester.pump();

      await tester.tap(find.text(l10n('common.view')));
      await tester.pumpAndSettle();

      expect(find.text('Chicks'), findsOneWidget);
    });

    testWidgets('shows single chick banner for count=1', (tester) async {
      await tester.pumpWidget(createSubject(1));
      await tester.pump();

      expect(find.text(l10n('home.unweaned_alert')), findsOneWidget);
    });
  });
}
