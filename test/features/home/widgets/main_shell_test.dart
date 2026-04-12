import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/main_shell.dart';

Widget _createSubject({required Size size}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const Placeholder(),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('test-user'),
      syncStatusProvider.overrideWithValue(SyncDisplayStatus.synced),
      periodicSyncProvider.overrideWith((_) {}),
      networkAwareSyncProvider.overrideWith((_) {}),
    ],
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  group('MainShell responsive navigation', () {
    testWidgets('shows NavigationBar on narrow screens (phone)', (
      tester,
    ) async {
      await tester.pumpWidget(_createSubject(size: const Size(375, 812)));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('shows NavigationRail on wide screens (tablet)', (
      tester,
    ) async {
      await tester.pumpWidget(_createSubject(size: const Size(768, 1024)));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('shows NavigationBar at exactly 599px (below breakpoint)', (
      tester,
    ) async {
      await tester.pumpWidget(_createSubject(size: const Size(599, 800)));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('shows NavigationRail at exactly 600px (at breakpoint)', (
      tester,
    ) async {
      await tester.pumpWidget(_createSubject(size: const Size(600, 800)));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('NavigationRail has 5 destinations', (tester) async {
      await tester.pumpWidget(_createSubject(size: const Size(768, 1024)));
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations.length, 5);
    });

    testWidgets('NavigationBar has 5 destinations', (tester) async {
      await tester.pumpWidget(_createSubject(size: const Size(375, 812)));
      await tester.pumpAndSettle();

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.destinations.length, 5);
    });

    testWidgets('shows VerticalDivider in wide layout', (tester) async {
      await tester.pumpWidget(_createSubject(size: const Size(768, 1024)));
      await tester.pumpAndSettle();

      expect(find.byType(VerticalDivider), findsOneWidget);
    });

    testWidgets('does not overflow on small phone widths', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_createSubject(size: const Size(320, 640)));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
