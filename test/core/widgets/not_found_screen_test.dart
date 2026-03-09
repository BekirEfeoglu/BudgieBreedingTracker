import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/widgets/not_found_screen.dart';

void main() {
  group('NotFoundScreen', () {
    testWidgets('renders 404 text', (tester) async {
      final router = GoRouter(
        initialLocation: '/not-found',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/not-found',
            builder: (_, __) => const NotFoundScreen(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('404'), findsOneWidget);
    });

    testWidgets('renders file question icon', (tester) async {
      final router = GoRouter(
        initialLocation: '/not-found',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/not-found',
            builder: (_, __) => const NotFoundScreen(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.fileQuestion), findsOneWidget);
    });

    testWidgets('contains a FilledButton for navigation', (tester) async {
      final router = GoRouter(
        initialLocation: '/not-found',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/not-found',
            builder: (_, __) => const NotFoundScreen(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('navigates to home when button is tapped', (tester) async {
      final router = GoRouter(
        initialLocation: '/not-found',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/not-found',
            builder: (_, __) => const NotFoundScreen(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });
  });
}
