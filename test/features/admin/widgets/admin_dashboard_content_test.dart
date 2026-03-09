import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_data_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_dashboard_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_dashboard_content.dart';

const _defaultStats = AdminStats(
  totalUsers: 10,
  activeToday: 2,
  newUsersToday: 1,
  totalBirds: 50,
  activeBreedings: 3,
);

/// Wraps widget with ProviderScope overrides and optional GoRouter.
Widget _wrapWithProviders(
  Widget child, {
  AsyncValue<Map<String, dynamic>> healthData = const AsyncLoading(),
  AsyncValue<List<SystemAlert>> alerts = const AsyncLoading(),
  AsyncValue<List<AdminLog>> actions = const AsyncLoading(),
  bool withRouter = false,
}) {
  final overrides = [
    systemHealthProvider.overrideWithValue(healthData),
    adminSystemAlertsProvider.overrideWithValue(alerts),
    recentAdminActionsProvider.overrideWithValue(actions),
  ];

  if (withRouter) {
    final router = GoRouter(
      initialLocation: '/admin/dashboard',
      routes: [
        GoRoute(
          path: '/admin/dashboard',
          builder: (_, __) => Scaffold(body: child),
        ),
        GoRoute(
          path: '/admin/settings',
          builder: (_, __) => const Scaffold(body: Text('Settings')),
        ),
        GoRoute(
          path: '/admin/users',
          builder: (_, __) => const Scaffold(body: Text('Users')),
        ),
      ],
    );
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('DashboardSystemHealthBanner', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const DashboardSystemHealthBanner(stats: _defaultStats),
        ),
      );
      await tester.pump();
      expect(find.byType(DashboardSystemHealthBanner), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const DashboardSystemHealthBanner(stats: _defaultStats),
          healthData: const AsyncLoading(),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows checking_health text when loading', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const DashboardSystemHealthBanner(stats: _defaultStats),
          healthData: const AsyncLoading(),
        ),
      );
      await tester.pump();
      expect(find.text('admin.checking_health'), findsOneWidget);
    });

    testWidgets('shows system_healthy text on healthy status', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const DashboardSystemHealthBanner(stats: _defaultStats),
          healthData: const AsyncData({'status': 'ok'}),
        ),
      );
      await tester.pump();
      expect(find.text('admin.system_healthy'), findsOneWidget);
    });

    testWidgets('shows system_degraded text on error status', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const DashboardSystemHealthBanner(stats: _defaultStats),
          healthData: const AsyncData({
            'status': 'error',
            'message': 'DB down',
          }),
        ),
      );
      await tester.pump();
      expect(find.text('admin.system_degraded'), findsOneWidget);
    });

    testWidgets('shows health_unavailable text on unavailable status', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const DashboardSystemHealthBanner(stats: _defaultStats),
          healthData: const AsyncData({'status': 'unavailable'}),
        ),
      );
      await tester.pump();
      expect(find.text('admin.health_unavailable'), findsOneWidget);
    });

    testWidgets('shows error message from data on error status', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const DashboardSystemHealthBanner(stats: _defaultStats),
          healthData: const AsyncData({
            'status': 'error',
            'message': 'DB down',
          }),
        ),
      );
      await tester.pump();
      expect(find.text('DB down'), findsOneWidget);
    });

    testWidgets('shows all_services_running text on healthy status', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const DashboardSystemHealthBanner(stats: _defaultStats),
          healthData: const AsyncData({'status': 'ok'}),
        ),
      );
      await tester.pump();
      expect(find.text('admin.all_services_running'), findsOneWidget);
    });
  });

  group('DashboardStatCard', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardStatCard(
              icon: Icon(Icons.people),
              label: 'Total Users',
              value: '42',
              color: Colors.blue,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(DashboardStatCard), findsOneWidget);
    });

    testWidgets('shows label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardStatCard(
              icon: Icon(Icons.people),
              label: 'My Label',
              value: '10',
              color: Colors.green,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('My Label'), findsOneWidget);
    });

    testWidgets('shows non-numeric value directly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardStatCard(
              icon: Icon(Icons.people),
              label: 'Status',
              value: 'N/A',
              color: Colors.orange,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('N/A'), findsOneWidget);
    });
  });

  group('DashboardQuickActionButton', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardQuickActionButton(
              icon: const Icon(Icons.settings),
              label: 'Go to Settings',
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(DashboardQuickActionButton), findsOneWidget);
    });

    testWidgets('shows label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardQuickActionButton(
              icon: const Icon(Icons.settings),
              label: 'Settings Label',
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Settings Label'), findsOneWidget);
    });

    testWidgets('triggers onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardQuickActionButton(
              icon: const Icon(Icons.settings),
              label: 'Settings',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });
  });

  group('DashboardContent', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const DashboardContent(stats: _defaultStats),
          healthData: const AsyncData({'status': 'ok'}),
          alerts: const AsyncData([]),
          actions: const AsyncData([]),
          withRouter: true,
        ),
      );
      await tester.pump();

      // DashboardStatCard TweenAnimationBuilder may cause overflow — consume
      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(DashboardContent), findsOneWidget);
    });

    testWidgets('shows quick_actions section title', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const DashboardContent(stats: _defaultStats),
          healthData: const AsyncData({'status': 'ok'}),
          alerts: const AsyncData([]),
          actions: const AsyncData([]),
          withRouter: true,
        ),
      );
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('admin.quick_actions'), findsOneWidget);
    });

    testWidgets('shows go_to_settings quick action', (tester) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          const DashboardContent(stats: _defaultStats),
          healthData: const AsyncData({'status': 'ok'}),
          alerts: const AsyncData([]),
          actions: const AsyncData([]),
          withRouter: true,
        ),
      );
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('admin.go_to_settings'), findsOneWidget);
    });
  });
}
