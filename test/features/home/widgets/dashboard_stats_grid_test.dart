import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/dashboard_stats_grid.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';

Widget _createSubject({DashboardStats? stats, bool isPremium = false}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (_, __) => NoTransitionPage(
          child: Scaffold(
            body: SingleChildScrollView(
              child: DashboardStatsGrid(stats: stats ?? const DashboardStats()),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/birds',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: Scaffold(body: Text('Birds'))),
      ),
      GoRoute(
        path: '/breeding',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: Scaffold(body: Text('Breeding'))),
      ),
      GoRoute(
        path: '/chicks',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: Scaffold(body: Text('Chicks'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [isPremiumProvider.overrideWithValue(isPremium)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('DashboardStatsGrid', () {
    testWidgets('renders without crashing with default stats', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(DashboardStatsGrid), findsOneWidget);
    });

    testWidgets('shows total_birds label', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.text(l10n('home.total_birds')), findsOneWidget);
    });

    testWidgets('shows active_breedings label', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.text(l10n('home.active_breedings')), findsOneWidget);
    });

    testWidgets('shows total_chicks label', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.text(l10n('home.total_chicks')), findsOneWidget);
    });

    testWidgets('shows total_eggs label', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.text(l10n('home.total_eggs')), findsOneWidget);
    });

    testWidgets('shows incubating_eggs label', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.text(l10n('home.incubating_eggs')), findsOneWidget);
    });

    testWidgets('shows stat values from DashboardStats', (tester) async {
      const stats = DashboardStats(
        totalBirds: 12,
        activeBreedings: 3,
        totalChicks: 7,
        totalEggs: 18,
        incubatingEggs: 5,
      );
      await tester.pumpWidget(_createSubject(stats: stats));
      await tester.pump();

      expect(find.textContaining('12'), findsAtLeastNWidgets(1));
      expect(find.textContaining('3'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows free tier progress bar when not premium', (
      tester,
    ) async {
      await tester.pumpWidget(_createSubject(isPremium: false));
      await tester.pump();

      // AppProgressBar renders a usage label in free mode
      expect(find.text(l10n('premium.usage_birds')), findsOneWidget);
    });

    testWidgets('does not show free tier progress bar when premium', (
      tester,
    ) async {
      await tester.pumpWidget(_createSubject(isPremium: true));
      await tester.pump();

      expect(find.text(l10n('premium.usage_birds')), findsNothing);
    });

    testWidgets('renders Column layout', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });
  });
}
