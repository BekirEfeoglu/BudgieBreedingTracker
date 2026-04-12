import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Pumps a [widget] inside a minimal MaterialApp with GoRouter.
///
/// Use this for widget tests that need a navigation context.
Future<void> pumpWidget(
  WidgetTester tester,
  Widget widget, {
  GoRouter? router,
}) async {
  final testRouter =
      router ??
      GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => widget),
          // Catch-all route for push/go calls
          GoRoute(
            path: '/birds/:id',
            builder: (_, state) =>
                Scaffold(body: Text('Bird: ${state.pathParameters['id']}')),
          ),
        ],
      );

  await tester.pumpWidget(MaterialApp.router(routerConfig: testRouter));
}

/// Pumps a [widget] inside a simple MaterialApp without routing.
///
/// Use this for simple widget tests that don't need GoRouter.
Future<void> pumpWidgetSimple(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
}
