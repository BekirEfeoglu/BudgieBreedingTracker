import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/main_shell.dart';

Widget _createSubject({required Size size}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (_, __) => const _StatefulTabProbe()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/birds',
                builder: (_, __) => const Text('birds-tab'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/breeding',
                builder: (_, __) => const Text('breeding-tab'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (_, __) => const Text('calendar-tab'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (_, __) => const Text('more-tab'),
              ),
            ],
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
      // Stub the profile sync side-effect so the shell does not kick off a
      // real network sync (which leaves pumpAndSettle hanging).
      profileSyncProvider('test-user').overrideWith((_) async {}),
    ],
    child: MediaQuery(
      // disableAnimations keeps the shimmer nav-icon animation static so
      // pumpAndSettle settles (this MediaQueryData would otherwise default it
      // to false, shadowing the global test config).
      data: MediaQueryData(size: size, disableAnimations: true),
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

    testWidgets('preserves local widget state across tab switches', (
      tester,
    ) async {
      await tester.pumpWidget(_createSubject(size: const Size(375, 812)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('increment-home-state')));
      await tester.pump();
      expect(find.text('home-state:1'), findsOneWidget);

      tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .onDestinationSelected!(1);
      await tester.pumpAndSettle();
      expect(find.text('birds-tab'), findsOneWidget);

      tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .onDestinationSelected!(0);
      await tester.pumpAndSettle();

      expect(find.text('home-state:1'), findsOneWidget);
    });
  });
}

class _StatefulTabProbe extends StatefulWidget {
  const _StatefulTabProbe();

  @override
  State<_StatefulTabProbe> createState() => _StatefulTabProbeState();
}

class _StatefulTabProbeState extends State<_StatefulTabProbe> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: const Key('increment-home-state'),
      onPressed: () => setState(() => _count++),
      child: Text('home-state:$_count'),
    );
  }
}
