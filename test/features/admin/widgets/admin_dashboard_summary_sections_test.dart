import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_dashboard_content.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _subject() {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(
          body: DashboardStatsGrid(
            stats: AdminStats(totalUsers: 10, activeToday: 4, newUsersToday: 2),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        builder: (_, state) =>
            Text(state.uri.queryParameters['filter'] ?? 'no-filter'),
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('DashboardStatsGrid drill-down', () {
    testWidgets('active today card opens users filtered to active today', (
      tester,
    ) async {
      await tester.pumpWidget(_subject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('admin.active_today'));
      await tester.pumpAndSettle();

      expect(find.text('activeToday'), findsOneWidget);
    });

    testWidgets('new today card opens users filtered to new today', (
      tester,
    ) async {
      await tester.pumpWidget(_subject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('admin.new_today'));
      await tester.pumpAndSettle();

      expect(find.text('newToday'), findsOneWidget);
    });
  });
}
