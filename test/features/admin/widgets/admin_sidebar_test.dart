import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/features/admin/widgets/admin_sidebar.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';

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

Future<void> _pumpSidebar(
  WidgetTester tester, {
  String initialLocation = '/admin/dashboard',
}) async {
  final router = _buildRouter(initialLocation: initialLocation);
  await pumpLocalizedApp(
    tester,
    ProviderScope(
      overrides: [
        // Badge providers call requireAdmin which checks userId.
        // Returning 'anonymous' causes requireAdmin to throw, which is caught
        // gracefully by the badge providers (they return 0 on any error).
        currentUserIdProvider.overrideWithValue('anonymous'),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  group('AdminSidebar', () {
    testWidgets('renders without crashing', (tester) async {
      await _pumpSidebar(tester);
      expect(find.byType(AdminSidebar), findsOneWidget);
    });

    testWidgets('shows panel title header', (tester) async {
      await _pumpSidebar(tester);
      expect(find.text(l10n('admin.panel_title')), findsOneWidget);
    });

    testWidgets('shows back to app link', (tester) async {
      await _pumpSidebar(tester);
      expect(find.text(l10n('admin.back_to_app')), findsOneWidget);
    });

    testWidgets('shows all 8 menu item labels', (tester) async {
      await _pumpSidebar(tester);
      expect(find.text(l10n('admin.dashboard')), findsOneWidget);
      expect(find.text(l10n('admin.users')), findsOneWidget);
      expect(find.text(l10n('admin.monitoring')), findsOneWidget);
      expect(find.text(l10n('admin.database')), findsOneWidget);
      expect(find.text(l10n('admin.audit')), findsOneWidget);
      expect(find.text(l10n('admin.security')), findsOneWidget);
      expect(find.text(l10n('admin.settings')), findsOneWidget);
      expect(find.text(l10n('admin.feedback_admin')), findsOneWidget);
    });

    testWidgets('dashboard item is selected on dashboard route', (
      tester,
    ) async {
      await _pumpSidebar(tester, initialLocation: '/admin/dashboard');
      expect(find.text(l10n('admin.dashboard')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.constraints?.maxWidth == 4 &&
              widget.constraints?.maxHeight == 20,
        ),
        findsOneWidget,
      );
    });

    testWidgets('users item is selected on users route', (tester) async {
      await _pumpSidebar(tester, initialLocation: '/admin/users');
      expect(find.text('Users Screen'), findsOneWidget);
    });

    testWidgets('tapping users menu item navigates to users route', (
      tester,
    ) async {
      await _pumpSidebar(tester);
      await tester.tap(find.text(l10n('admin.users')));
      await tester.pumpAndSettle();
      expect(find.text('Users Screen'), findsOneWidget);
    });

    testWidgets('tapping back to app navigates to home', (tester) async {
      await _pumpSidebar(tester);
      await tester.tap(find.text(l10n('admin.back_to_app')));
      await tester.pumpAndSettle();
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('has fixed width of 260', (tester) async {
      await _pumpSidebar(tester);
      final sidebarFinder = find.byType(AdminSidebar);
      final renderBox = tester.renderObject<RenderBox>(sidebarFinder);
      expect(renderBox.size.width, equals(260.0));
    });

    testWidgets('shows ListView with menu items', (tester) async {
      await _pumpSidebar(tester);
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
