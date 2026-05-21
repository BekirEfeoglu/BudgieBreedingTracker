import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

bool _intlInitialized = false;

/// Initializes intl date locale data exactly once per test run. Widgets
/// that pass an explicit locale to `DateFormat.yMd('tr')` / `.Hm('de')` etc.
/// throw `LocaleDataException` without this. The runtime path calls this
/// from `main.dart` via easy_localization initialization, but test helpers
/// bypass that bootstrap so we must initialize here.
void _ensureIntlReady() {
  if (_intlInitialized) return;
  initializeDateFormatting();
  _intlInitialized = true;
}

/// Pumps a [widget] inside a minimal MaterialApp with GoRouter.
///
/// Use this for widget tests that need a navigation context.
Future<void> pumpWidget(
  WidgetTester tester,
  Widget widget, {
  GoRouter? router,
}) async {
  _ensureIntlReady();
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
  _ensureIntlReady();
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
}
