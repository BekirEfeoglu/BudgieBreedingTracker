import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/features/admin/widgets/admin_shell.dart';

import '../../../helpers/test_localization.dart';

/// Wraps AdminShell inside a minimal GoRouter context.
Widget _wrapWithRouter({
  required Widget shellChild,
  String initialLocation = '/admin/dashboard',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/admin/dashboard',
        builder: (_, __) => AdminShell(child: shellChild),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (_, __) => AdminShell(child: shellChild),
      ),
      GoRoute(
        path: '/admin/audit',
        builder: (_, __) => AdminShell(child: shellChild),
      ),
      GoRoute(
        path: '/admin/monitoring',
        builder: (_, __) => AdminShell(child: shellChild),
      ),
      GoRoute(
        path: '/admin/database',
        builder: (_, __) => AdminShell(child: shellChild),
      ),
      GoRoute(
        path: '/admin/security',
        builder: (_, __) => AdminShell(child: shellChild),
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (_, __) => AdminShell(child: shellChild),
      ),
      GoRoute(
        path: '/admin/feedback',
        builder: (_, __) => AdminShell(child: shellChild),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('Home')),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

const _childWidget = Text('Page Content');

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size size,
  String initialLocation = '/admin/dashboard',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await pumpLocalizedApp(
    tester,
    _wrapWithRouter(shellChild: _childWidget, initialLocation: initialLocation),
  );
}

void main() {
  group('AdminShell — narrow layout (width < 840)', () {
    testWidgets('renders without crashing', (tester) async {
      await _pumpShell(tester, size: const Size(600, 900));
      expect(find.byType(AdminShell), findsOneWidget);
    });

    testWidgets('shows AppBar on narrow screen', (tester) async {
      await _pumpShell(tester, size: const Size(600, 900));
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Scaffold has drawer set on narrow screen', (tester) async {
      await _pumpShell(tester, size: const Size(600, 900));
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.drawer, isA<Drawer>());
    });

    testWidgets('shows child content', (tester) async {
      await _pumpShell(tester, size: const Size(600, 900));
      expect(find.text('Page Content'), findsOneWidget);
    });

    testWidgets('title shows admin.dashboard for dashboard route', (
      tester,
    ) async {
      await _pumpShell(tester, size: const Size(600, 900));
      expect(find.text('admin.dashboard'), findsOneWidget);
    });

    testWidgets('title shows admin.users for users route', (tester) async {
      await _pumpShell(
        tester,
        size: const Size(600, 900),
        initialLocation: '/admin/users',
      );
      expect(find.text('admin.users'), findsOneWidget);
    });

    testWidgets('shows back-to-app icon button', (tester) async {
      await _pumpShell(tester, size: const Size(600, 900));
      expect(find.byTooltip('admin.back_to_app'), findsOneWidget);
    });

    testWidgets('back-to-app action navigates home', (tester) async {
      await _pumpShell(tester, size: const Size(600, 900));
      await tester.tap(find.byTooltip('admin.back_to_app'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });
  });

  group('AdminShell — wide layout (width >= 840)', () {
    testWidgets('renders without crashing', (tester) async {
      await _pumpShell(tester, size: const Size(1200, 900));
      expect(find.byType(AdminShell), findsOneWidget);
    });

    testWidgets('shows AdminSidebar on wide screen', (tester) async {
      await _pumpShell(tester, size: const Size(1200, 900));
      expect(find.text('admin.panel_title'), findsOneWidget);
      expect(find.byType(VerticalDivider), findsOneWidget);
    });

    testWidgets('shows child content on wide screen', (tester) async {
      await _pumpShell(tester, size: const Size(1200, 900));
      expect(find.text('Page Content'), findsOneWidget);
    });

    testWidgets('has no AppBar on wide screen', (tester) async {
      await _pumpShell(tester, size: const Size(1200, 900));
      expect(find.byType(AppBar), findsNothing);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.drawer, isNull);
    });
  });
}
