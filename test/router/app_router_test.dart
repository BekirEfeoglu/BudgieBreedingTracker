import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_reward_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/router/app_router.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

class _MockGoRouterState extends Mock implements GoRouterState {}

/// Test notifier for InitSkippedNotifier that returns a fixed value.
class _TestInitSkippedNotifier extends InitSkippedNotifier {
  final bool _initial;
  _TestInitSkippedNotifier(this._initial);

  @override
  bool build() => _initial;
}

class _FalseGeneticsRewardNotifier extends GeneticsRewardNotifier {
  @override
  bool build() => false;
}

class _FalseStatisticsRewardNotifier extends StatisticsRewardNotifier {
  @override
  bool build() => false;
}

class _TestPendingMfaNotifier extends PendingMfaFactorIdNotifier {
  final String? _initial;
  _TestPendingMfaNotifier(this._initial);

  @override
  String? build() => _initial;
}

class _TestSessionLockedNotifier extends SessionLockedNotifier {
  final bool _initial;
  _TestSessionLockedNotifier(this._initial);

  @override
  bool build() => _initial;
}

class _MockAdService extends Mock implements AdService {
  @override
  Future<void> ensureSdkInitialized() async {}
}

ProviderContainer _createContainer({
  required bool isLoggedIn,
  required bool isPremium,
  FutureOr<bool> Function(Ref ref)? isAdminBuilder,
  FutureOr<void> Function(Ref ref)? appInitBuilder,
  bool initSkipped = false,
  String? pendingMfaFactorId,
  bool sessionLocked = false,
}) {
  return ProviderContainer(
    overrides: [
      isAuthenticatedProvider.overrideWithValue(isLoggedIn),
      sessionLockedProvider.overrideWith(
        () => _TestSessionLockedNotifier(sessionLocked),
      ),
      isAdminProvider.overrideWith(isAdminBuilder ?? (_) => false),
      isPremiumProvider.overrideWithValue(isPremium),
      effectivePremiumProvider.overrideWithValue(isPremium),
      appInitializationProvider.overrideWith(appInitBuilder ?? (_) {}),
      initSkippedProvider.overrideWith(
        () => _TestInitSkippedNotifier(initSkipped),
      ),
      isGeneticsRewardActiveProvider.overrideWith(
        _FalseGeneticsRewardNotifier.new,
      ),
      isStatisticsRewardActiveProvider.overrideWith(
        _FalseStatisticsRewardNotifier.new,
      ),
      adServiceProvider.overrideWithValue(_MockAdService()),
      deferredNotificationPermissionProvider.overrideWith((_) async {}),
      periodicSyncProvider.overrideWith((ref) {}),
      networkAwareSyncProvider.overrideWith((ref) {}),
      unweanedChicksCountProvider.overrideWith((ref, userId) {
        return Stream<int>.value(0);
      }),
      if (pendingMfaFactorId != null)
        pendingMfaFactorIdProvider.overrideWith(
          () => _TestPendingMfaNotifier(pendingMfaFactorId),
        ),
    ],
  );
}

Future<BuildContext> _createContext(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(
        builder: (ctx) {
          context = ctx;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return context;
}

/// Pumps a [MaterialApp.router] backed by the real [routerProvider] and
/// navigates to [location]. Returns the resolved path after redirect settles.
///
/// Replaces the widget tree with a plain widget and disposes the container
/// before returning to cancel Riverpod-internal retry timers that would
/// otherwise trigger the "Timer is still pending" assertion.
Future<String> _navigateAndResolve(
  WidgetTester tester,
  ProviderContainer container,
  String location,
) async {
  final router = container.read(routerProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));

  router.go(location);
  await tester.pump(const Duration(milliseconds: 200));

  final resolvedPath = router.routeInformationProvider.value.uri.path;

  // Replace the widget tree to unmount the Riverpod scope, then dispose the
  // container. Pump with enough duration to flush any Riverpod retry timers
  // created during FutureProvider lifecycle.
  await tester.pumpWidget(const SizedBox.shrink());
  container.dispose();
  await tester.pump(const Duration(seconds: 1));

  return resolvedPath;
}

List<String> _collectPaths(List<RouteBase> routes) {
  final paths = <String>[];

  void visit(List<RouteBase> nodes) {
    for (final route in nodes) {
      if (route is GoRoute) {
        paths.add(route.path);
        visit(route.routes);
      } else if (route is ShellRouteBase) {
        visit(route.routes);
      }
    }
  }

  visit(routes);
  return paths;
}

GoRouterState _stateForRoutePath(
  String path, {
  Map<String, String> inheritedPathParameters = const {},
  Map<String, String> extraQuery = const {},
}) {
  final state = _MockGoRouterState();

  final pathParameters = <String, String>{...inheritedPathParameters};
  for (final segment in path.split('/')) {
    if (!segment.startsWith(':')) continue;
    final key = segment.substring(1);
    pathParameters.putIfAbsent(key, () => '$key-1');
  }

  final query = <String, String>{...extraQuery};
  if (path == AppRoutes.emailVerification) {
    query.putIfAbsent('email', () => 'user@test.com');
  }
  if (path == AppRoutes.twoFactorVerify) {
    query.putIfAbsent('factorId', () => 'factor-1');
  }
  if (path == 'form') {
    query.putIfAbsent('editId', () => 'edit-1');
    query.putIfAbsent('birdId', () => 'bird-1');
  }

  final normalizedPath = path.startsWith('/') ? path : '/$path';
  final uri = Uri(
    path: normalizedPath,
    queryParameters: query.isEmpty ? null : query,
  );

  when(() => state.uri).thenReturn(uri);
  when(() => state.pathParameters).thenReturn(pathParameters);
  when(() => state.pageKey).thenReturn(ValueKey('k:$normalizedPath:$query'));
  when(() => state.matchedLocation).thenReturn(normalizedPath);

  return state;
}

void main() {
  group('router redirect', () {
    testWidgets('forces login when session is locally locked', (tester) async {
      final container = _createContainer(
        isLoggedIn: true,
        isPremium: true,
        initSkipped: true,
        sessionLocked: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.home,
      );

      expect(resolved, AppRoutes.login);
    });

    testWidgets('redirects unauthenticated user to login', (tester) async {
      final container = _createContainer(
        isLoggedIn: false,
        isPremium: false,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.statistics,
      );

      expect(resolved, AppRoutes.login);
    });

    testWidgets('allows anonymous user on premium route', (tester) async {
      final container = _createContainer(
        isLoggedIn: false,
        isPremium: false,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.premium,
      );
      expect(resolved, AppRoutes.premium);
    });

    testWidgets('allows anonymous user on user guide route', (tester) async {
      final container = _createContainer(
        isLoggedIn: false,
        isPremium: false,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.userGuide,
      );
      expect(resolved, AppRoutes.userGuide);
    });

    testWidgets('allows anonymous user on privacy policy route',
        (tester) async {
      final container = _createContainer(
        isLoggedIn: false,
        isPremium: false,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.privacyPolicy,
      );
      expect(resolved, AppRoutes.privacyPolicy);
    });

    testWidgets('allows anonymous user on terms of service route',
        (tester) async {
      final container = _createContainer(
        isLoggedIn: false,
        isPremium: false,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.termsOfService,
      );
      expect(resolved, AppRoutes.termsOfService);
    });

    testWidgets('allows anonymous user on community guidelines route',
        (tester) async {
      final container = _createContainer(
        isLoggedIn: false,
        isPremium: false,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.communityGuidelines,
      );
      expect(resolved, AppRoutes.communityGuidelines);
    });

    testWidgets('redirects anonymous user from home to login',
        (tester) async {
      final container = _createContainer(
        isLoggedIn: false,
        isPremium: false,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.home,
      );
      expect(resolved, AppRoutes.login);
    });

    testWidgets('redirects anonymous user from birds to login',
        (tester) async {
      final container = _createContainer(
        isLoggedIn: false,
        isPremium: false,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.birds,
      );
      expect(resolved, AppRoutes.login);
    });

    testWidgets('redirects anonymous user from settings to login',
        (tester) async {
      final container = _createContainer(
        isLoggedIn: false,
        isPremium: false,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.settings,
      );
      expect(resolved, AppRoutes.login);
    });

    testWidgets('redirects authenticated user away from login',
        (tester) async {
      final container = _createContainer(
        isLoggedIn: true,
        isPremium: false,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.login,
      );
      expect(resolved, AppRoutes.home);
    });

    testWidgets(
      'routes authenticated user to splash while app init is pending',
      (tester) async {
        final pendingInit = Completer<void>();
        final container = _createContainer(
          isLoggedIn: true,
          isPremium: false,
          appInitBuilder: (_) => pendingInit.future,
        );
        final resolved = await _navigateAndResolve(
          tester,
          container,
          AppRoutes.birds,
        );
        expect(resolved, AppRoutes.splash);
      },
    );

    testWidgets('redirects splash to home when app init is ready',
        (tester) async {
      final container = _createContainer(
        isLoggedIn: true,
        isPremium: false,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.splash,
      );
      expect(resolved, AppRoutes.home);
    });

    testWidgets('keeps splash when init has error and skip is false',
        (tester) async {
      final container = _createContainer(
        isLoggedIn: true,
        isPremium: false,
        appInitBuilder: (_) => throw Exception('init failed'),
        initSkipped: false,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.splash,
      );
      expect(resolved, AppRoutes.splash);
    });

    testWidgets('blocks non-premium user from genetics route',
        (tester) async {
      final container = _createContainer(
        isLoggedIn: true,
        isPremium: false,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.genetics,
      );
      expect(resolved, AppRoutes.premium);
    });

    testWidgets('allows premium user on genetics route', (tester) async {
      final container = _createContainer(
        isLoggedIn: true,
        isPremium: true,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.genetics,
      );
      expect(resolved, AppRoutes.genetics);
    });

    testWidgets('redirects non-premium users for statistics route',
        (tester) async {
      final container = _createContainer(
        isLoggedIn: true,
        isPremium: false,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.statistics,
      );
      expect(resolved, AppRoutes.premium);
    });

    testWidgets('redirects non-premium users for genealogy route',
        (tester) async {
      final container = _createContainer(
        isLoggedIn: true,
        isPremium: false,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.genealogy,
      );
      expect(resolved, AppRoutes.premium);
    });

    testWidgets(
      'redirects non-premium deep links for genetics reverse/compare',
      (tester) async {
        final container = _createContainer(
          isLoggedIn: true,
          isPremium: false,
          initSkipped: true,
        );

        final router = container.read(routerProvider);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        router.go(AppRoutes.geneticsReverse);
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.premium,
        );

        router.go(AppRoutes.geneticsCompare);
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.premium,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        await tester.pump(const Duration(seconds: 1));
      },
    );

    testWidgets('blocks non-admin user from admin routes', (tester) async {
      final container = _createContainer(
        isLoggedIn: true,
        isPremium: true,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.adminDashboard,
      );
      expect(resolved, AppRoutes.home);
    });

    testWidgets('allows admin user on admin routes', (tester) async {
      final container = _createContainer(
        isLoggedIn: true,
        isPremium: true,
        isAdminBuilder: (_) => true,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        AppRoutes.adminDashboard,
      );
      expect(resolved, AppRoutes.adminDashboard);
    });

    testWidgets('blocks non-admin from nested admin user detail route',
        (tester) async {
      final container = _createContainer(
        isLoggedIn: true,
        isPremium: true,
        isAdminBuilder: (_) => false,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        '/admin/users/user-1',
      );
      expect(resolved, AppRoutes.home);
    });

    testWidgets('allows admin on nested admin user detail route',
        (tester) async {
      final container = _createContainer(
        isLoggedIn: true,
        isPremium: true,
        isAdminBuilder: (_) => true,
        initSkipped: true,
      );
      final resolved = await _navigateAndResolve(
        tester,
        container,
        '/admin/users/user-1',
      );
      expect(resolved, '/admin/users/user-1');
    });
  });

  group('router configuration', () {
    test('contains expected route tree and shell routes', () {
      final container = _createContainer(isLoggedIn: true, isPremium: true);
      addTearDown(container.dispose);
      final router = container.read(routerProvider);

      final topLevelRoutes = router.configuration.routes;
      final paths = _collectPaths(topLevelRoutes);

      expect(topLevelRoutes.whereType<ShellRoute>().length, 2);
      expect(
        paths,
        containsAll([
          AppRoutes.splash,
          AppRoutes.login,
          AppRoutes.home,
          AppRoutes.birds,
          AppRoutes.breeding,
          AppRoutes.chicks,
          AppRoutes.statistics,
          AppRoutes.geneticsReverse,
          AppRoutes.geneticsCompare,
          AppRoutes.healthRecords,
          AppRoutes.adminDashboard,
          AppRoutes.adminUsers,
          'form',
          ':id',
          ':userId',
        ]),
      );
    });

    testWidgets('executes all route builders/pageBuilders', (tester) async {
      final context = await _createContext(tester);
      final container = _createContainer(
        isLoggedIn: true,
        isPremium: true,
        isAdminBuilder: (_) => true,
        initSkipped: true,
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      final widgets = <Widget>[];
      final pages = <Page<void>>[];

      void visit(
        List<RouteBase> routes, {
        Map<String, String> inheritedPathParameters = const {},
      }) {
        for (final route in routes) {
          if (route is GoRoute) {
            final nextPathParameters = <String, String>{
              ...inheritedPathParameters,
            };
            for (final segment in route.path.split('/')) {
              if (!segment.startsWith(':')) continue;
              final key = segment.substring(1);
              nextPathParameters.putIfAbsent(key, () => '$key-1');
            }

            final state = _stateForRoutePath(
              route.path,
              inheritedPathParameters: nextPathParameters,
            );
            final builder = route.builder;
            if (builder != null) {
              widgets.add(builder(context, state));
            }
            final pageBuilder = route.pageBuilder;
            if (pageBuilder != null) {
              pages.add(pageBuilder(context, state));
            }
            visit(route.routes, inheritedPathParameters: nextPathParameters);
          } else if (route is ShellRoute) {
            final shellState = _stateForRoutePath('/shell');
            widgets.add(
              route.builder!(context, shellState, const SizedBox.shrink()),
            );
            visit(route.routes);
          } else if (route is ShellRouteBase) {
            visit(route.routes);
          }
        }
      }

      visit(router.configuration.routes);

      // Exercise additional null-query branches that rely on fallback values.
      final twoFactorRoute = router.configuration.routes
          .whereType<GoRoute>()
          .firstWhere((r) => r.path == AppRoutes.twoFactorVerify);
      widgets.add(
        twoFactorRoute.builder!(
          context,
          _stateForRoutePath(AppRoutes.twoFactorVerify, extraQuery: const {}),
        ),
      );

      final emailVerifyRoute = router.configuration.routes
          .whereType<GoRoute>()
          .firstWhere((r) => r.path == AppRoutes.emailVerification);
      widgets.add(
        emailVerifyRoute.builder!(
          context,
          _stateForRoutePath(AppRoutes.emailVerification, extraQuery: const {}),
        ),
      );

      expect(widgets, isNotEmpty);
      expect(pages, isNotEmpty);
    });
  });
}
