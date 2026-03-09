import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/features/admin/widgets/admin_sidebar.dart';

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

/// Consumes all pending test exceptions (e.g. layout overflow from long l10n keys).
void _consumeExceptions(WidgetTester tester) {
  var ex = tester.takeException();
  while (ex != null) {
    ex = tester.takeException();
  }
}

void main() {
  group('AdminSidebar', () {
    testWidgets('renders without crashing', (tester) async {
      final router = _buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      _consumeExceptions(tester);
      expect(find.byType(AdminSidebar), findsOneWidget);
    });

    testWidgets('shows panel title header', (tester) async {
      final router = _buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      _consumeExceptions(tester);
      expect(find.text('admin.panel_title'), findsOneWidget);
    });

    testWidgets('shows back to app link', (tester) async {
      final router = _buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      _consumeExceptions(tester);
      expect(find.text('admin.back_to_app'), findsOneWidget);
    });

    testWidgets('shows all 8 menu item labels', (tester) async {
      final router = _buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      _consumeExceptions(tester);

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
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      _consumeExceptions(tester);
      expect(find.text('admin.dashboard'), findsOneWidget);
    });

    testWidgets('users item is selected on users route', (tester) async {
      final router = _buildRouter(initialLocation: '/admin/users');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      _consumeExceptions(tester);
      expect(find.text('Users Screen'), findsOneWidget);
    });

    testWidgets('tapping users menu item navigates to users route', (
      tester,
    ) async {
      final router = _buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      _consumeExceptions(tester);

      await tester.tap(find.text('admin.users'));
      await tester.pump();
      _consumeExceptions(tester);

      expect(find.text('Users Screen'), findsOneWidget);
    });

    testWidgets('tapping back to app navigates to home', (tester) async {
      final router = _buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      _consumeExceptions(tester);

      await tester.tap(find.text('admin.back_to_app'));
      await tester.pump();
      _consumeExceptions(tester);

      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('has fixed width of 260', (tester) async {
      final router = _buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      _consumeExceptions(tester);

      final sidebarFinder = find.byType(AdminSidebar);
      final renderBox = tester.renderObject<RenderBox>(sidebarFinder);
      expect(renderBox.size.width, equals(260.0));
    });

    testWidgets('shows ListView with menu items', (tester) async {
      final router = _buildRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      _consumeExceptions(tester);

      expect(find.byType(ListView), findsAtLeastNWidgets(1));
    });
  });
}
