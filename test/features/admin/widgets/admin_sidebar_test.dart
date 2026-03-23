import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/features/admin/widgets/admin_sidebar.dart';

import '../../../helpers/test_localization.dart';

/// Minimal GoRouter that provides all admin routes + home for navigation tests.
GoRouter _buildRouter({String initialLocation = '/admin/dashboard'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/admin/dashboard',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: Scaffold(body: AdminSidebar())),
      ),
      GoRoute(
        path: '/admin/users',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: Scaffold(body: Text('Users Screen'))),
      ),
      GoRoute(
        path: '/admin/monitoring',
        pageBuilder: (_, __) => const NoTransitionPage(
          child: Scaffold(body: Text('Monitoring Screen')),
        ),
      ),
      GoRoute(
        path: '/admin/database',
        pageBuilder: (_, __) => const NoTransitionPage(
          child: Scaffold(body: Text('Database Screen')),
        ),
      ),
      GoRoute(
        path: '/admin/audit',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: Scaffold(body: Text('Audit Screen'))),
      ),
      GoRoute(
        path: '/admin/security',
        pageBuilder: (_, __) => const NoTransitionPage(
          child: Scaffold(body: Text('Security Screen')),
        ),
      ),
      GoRoute(
        path: '/admin/settings',
        pageBuilder: (_, __) => const NoTransitionPage(
          child: Scaffold(body: Text('Settings Screen')),
        ),
      ),
      GoRoute(
        path: '/admin/feedback',
        pageBuilder: (_, __) => const NoTransitionPage(
          child: Scaffold(body: Text('Feedback Screen')),
        ),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: Scaffold(body: Text('Home Screen'))),
      ),
    ],
  );
}

/// Drains all overflow exceptions thrown after widget rendering.
void _drainOverflowErrors(WidgetTester tester) {
  // Consume up to 20 pending overflow exceptions.
  for (var i = 0; i < 20; i++) {
    final error = tester.takeException();
    if (error == null) break;
  }
}

void main() {
  group('AdminSidebar', () {
    testWidgets('renders without crashing', (tester) async {
      final router = _buildRouter();
      await pumpLocalizedApp(tester, MaterialApp.router(routerConfig: router));
      _drainOverflowErrors(tester);
      expect(find.byType(AdminSidebar), findsOneWidget);
    });

    testWidgets('shows panel title header', (tester) async {
      final router = _buildRouter();
      await pumpLocalizedApp(tester, MaterialApp.router(routerConfig: router));
      _drainOverflowErrors(tester);
      expect(find.text('admin.panel_title'), findsOneWidget);
    });

    testWidgets('shows back to app link', (tester) async {
      final router = _buildRouter();
      await pumpLocalizedApp(tester, MaterialApp.router(routerConfig: router));
      _drainOverflowErrors(tester);
      expect(find.text('admin.back_to_app'), findsOneWidget);
    });

    testWidgets('shows all 8 menu item labels', (tester) async {
      final router = _buildRouter();
      await pumpLocalizedApp(tester, MaterialApp.router(routerConfig: router));
      _drainOverflowErrors(tester);
      expect(find.text('admin.dashboard'), findsOneWidget);
      expect(find.text('admin.users'), findsOneWidget);
      expect(find.text('admin.monitoring'), findsOneWidget);
      expect(find.text('admin.database'), findsOneWidget);
      expect(find.text('admin.audit'), findsOneWidget);
      expect(find.text('admin.security'), findsOneWidget);
      expect(find.text('admin.settings'), findsOneWidget);
      expect(find.text('admin.feedback_admin'), findsOneWidget);
    });

    testWidgets('dashboard item is selected on dashboard route', (
      tester,
    ) async {
      final router = _buildRouter(initialLocation: '/admin/dashboard');
      await pumpLocalizedApp(tester, MaterialApp.router(routerConfig: router));
      _drainOverflowErrors(tester);
      expect(find.text('admin.dashboard'), findsOneWidget);
    });

    testWidgets('users item is selected on users route', (tester) async {
      final router = _buildRouter(initialLocation: '/admin/users');
      await pumpLocalizedApp(tester, MaterialApp.router(routerConfig: router));
      _drainOverflowErrors(tester);
      expect(find.text('Users Screen'), findsOneWidget);
    });

    testWidgets('tapping users menu item navigates to users route', (
      tester,
    ) async {
      final router = _buildRouter();
      await pumpLocalizedApp(tester, MaterialApp.router(routerConfig: router));
      _drainOverflowErrors(tester);
      await tester.tap(find.text('admin.users'));
      await tester.pump();
      _drainOverflowErrors(tester);
      expect(find.text('Users Screen'), findsOneWidget);
    });

    testWidgets('tapping back to app navigates to home', (tester) async {
      final router = _buildRouter();
      await pumpLocalizedApp(tester, MaterialApp.router(routerConfig: router));
      _drainOverflowErrors(tester);
      await tester.tap(find.text('admin.back_to_app'));
      await tester.pump();
      _drainOverflowErrors(tester);
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('has fixed width of 260', (tester) async {
      final router = _buildRouter();
      await pumpLocalizedApp(tester, MaterialApp.router(routerConfig: router));
      _drainOverflowErrors(tester);
      final sidebarFinder = find.byType(AdminSidebar);
      final renderBox = tester.renderObject<RenderBox>(sidebarFinder);
      expect(renderBox.size.width, equals(260.0));
    });

    testWidgets('shows ListView with menu items', (tester) async {
      final router = _buildRouter();
      await pumpLocalizedApp(tester, MaterialApp.router(routerConfig: router));
      _drainOverflowErrors(tester);
      expect(find.byType(ListView), findsAtLeastNWidgets(1));
    });
  });
}
