import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/features/home/widgets/quick_actions_row.dart';

Widget _createSubject() {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: Scaffold(body: QuickActionsRow())),
      ),
      GoRoute(
        path: '/birds/form',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: Scaffold(body: Text('BirdForm'))),
      ),
      GoRoute(
        path: '/breeding/form',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: Scaffold(body: Text('BreedingForm'))),
      ),
      GoRoute(
        path: '/chicks/form',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: Scaffold(body: Text('ChickForm'))),
      ),
      GoRoute(
        path: '/breeding',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: Scaffold(body: Text('Breeding'))),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('QuickActionsRow', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(QuickActionsRow), findsOneWidget);
    });

    testWidgets('shows add bird action label', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.text('birds.add_bird'), findsOneWidget);
    });

    testWidgets('shows add breeding action label', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.text('breeding.add_breeding'), findsOneWidget);
    });

    testWidgets('shows add chick action label', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.text('chicks.add_chick'), findsOneWidget);
    });

    testWidgets('shows manage eggs action label', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.text('home.manage_eggs'), findsOneWidget);
    });

    testWidgets('tapping add bird navigates to bird form', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      await tester.tap(find.text('birds.add_bird'));
      await tester.pumpAndSettle();

      expect(find.text('BirdForm'), findsOneWidget);
    });

    testWidgets('tapping add breeding navigates to breeding form', (
      tester,
    ) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      await tester.tap(find.text('breeding.add_breeding'));
      await tester.pumpAndSettle();

      expect(find.text('BreedingForm'), findsOneWidget);
    });

    testWidgets('renders Stack layout', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(Stack), findsAtLeastNWidgets(1));
    });
  });
}
