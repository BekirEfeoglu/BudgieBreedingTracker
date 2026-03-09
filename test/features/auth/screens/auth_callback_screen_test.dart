import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/screens/auth_callback_screen.dart';

void main() {
  Widget createSubject({bool isAuthenticated = false}) {
    // NoTransitionPage prevents animation timers from running during tests
    final router = GoRouter(
      initialLocation: '/auth/callback',
      routes: [
        GoRoute(
          path: '/auth/callback',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: AuthCallbackScreen()),
        ),
        GoRoute(
          path: '/',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: Scaffold(body: Text('Home'))),
        ),
        GoRoute(
          path: '/login',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: Scaffold(body: Text('Login'))),
        ),
      ],
    );

    return ProviderScope(
      overrides: [isAuthenticatedProvider.overrideWithValue(isAuthenticated)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('AuthCallbackScreen', () {
    testWidgets('renders AuthCallbackScreen without crashing', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(AuthCallbackScreen), findsOneWidget);

      // Drain the 1-second Future.delayed timer to avoid pending timer error
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('shows CircularProgressIndicator on initial render', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Drain the pending timer
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('navigates to home when authenticated after delay', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(isAuthenticated: true));
      await tester.pump(); // initial frame

      // After 1 second delay, _handleCallback fires and navigates to home
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('navigates to login when not authenticated after delay', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(isAuthenticated: false));
      await tester.pump();

      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('shows Scaffold as root widget', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));

      // Drain the pending timer
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
