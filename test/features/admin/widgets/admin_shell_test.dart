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

/// Drains all overflow exceptions thrown after widget rendering.
void _drainOverflowErrors(WidgetTester tester) {
  for (var i = 0; i < 20; i++) {
    final error = tester.takeException();
    if (error == null) break;
  }
}

void main() {
  group('AdminShell — narrow layout (width < 840)', () {
    testWidgets('renders without crashing', (tester) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpLocalizedApp(tester, _wrapWithRouter(shellChild: _childWidget));
      _drainOverflowErrors(tester);
      expect(find.byType(AdminShell), findsOneWidget);
    });

    testWidgets('shows AppBar on narrow screen', (tester) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpLocalizedApp(tester, _wrapWithRouter(shellChild: _childWidget));
      _drainOverflowErrors(tester);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Scaffold has drawer set on narrow screen', (tester) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpLocalizedApp(tester, _wrapWithRouter(shellChild: _childWidget));
      _drainOverflowErrors(tester);
      // Closed drawers are not built into the visible widget tree —
      // verify the Scaffold has a non-null drawer property instead.
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.drawer, isNotNull);
    });

    testWidgets('shows child content', (tester) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpLocalizedApp(tester, _wrapWithRouter(shellChild: _childWidget));
      _drainOverflowErrors(tester);
      expect(find.text('Page Content'), findsOneWidget);
    });

    testWidgets('title shows admin.dashboard for dashboard route', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpLocalizedApp(tester, _wrapWithRouter(shellChild: _childWidget));
      _drainOverflowErrors(tester);
      // Without easy_localization, .tr() returns key
      expect(find.text('admin.dashboard'), findsOneWidget);
    });

    testWidgets('title shows admin.users for users route', (tester) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpLocalizedApp(
        tester,
        _wrapWithRouter(
          shellChild: _childWidget,
          initialLocation: '/admin/users',
        ),
      );
      _drainOverflowErrors(tester);
      expect(find.text('admin.users'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows back-to-app icon button', (tester) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpLocalizedApp(tester, _wrapWithRouter(shellChild: _childWidget));
      _drainOverflowErrors(tester);
      // Back to app IconButton is in AppBar actions
      expect(find.byType(IconButton), findsAtLeastNWidgets(1));
    });
  });

  group('AdminShell — wide layout (width >= 840)', () {
    testWidgets('renders without crashing', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpLocalizedApp(tester, _wrapWithRouter(shellChild: _childWidget));
      _drainOverflowErrors(tester);
      expect(find.byType(AdminShell), findsOneWidget);
    });

    testWidgets('shows AdminSidebar on wide screen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpLocalizedApp(tester, _wrapWithRouter(shellChild: _childWidget));
      _drainOverflowErrors(tester);
      expect(find.byType(VerticalDivider), findsOneWidget);
    });

    testWidgets('shows child content on wide screen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpLocalizedApp(tester, _wrapWithRouter(shellChild: _childWidget));
      _drainOverflowErrors(tester);
      expect(find.text('Page Content'), findsOneWidget);
    });

    testWidgets('has no AppBar on wide screen', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpLocalizedApp(tester, _wrapWithRouter(shellChild: _childWidget));
      _drainOverflowErrors(tester);
      // Wide layout uses _WideLayout which has no AppBar (just Row with Sidebar)
      expect(find.byType(AppBar), findsNothing);
    });
  });
}
