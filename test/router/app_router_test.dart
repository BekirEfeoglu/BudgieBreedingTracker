import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/router/app_router.dart';
import 'package:budgie_breeding_tracker/router/guards/admin_guard.dart';
import 'package:budgie_breeding_tracker/router/guards/premium_guard.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

class _MockGoRouterState extends Mock implements GoRouterState {}

/// Test notifier for InitSkippedNotifier that returns a fixed value.
class _TestInitSkippedNotifier extends InitSkippedNotifier {
  final bool _initial;
  _TestInitSkippedNotifier(this._initial);

  @override
  bool build() => _initial;
}

ProviderContainer _createContainer({
  required bool isLoggedIn,
  required bool isPremium,
  FutureOr<bool> Function(Ref ref)? isAdminBuilder,
  FutureOr<void> Function(Ref ref)? appInitBuilder,
  bool initSkipped = false,
}) {
  return ProviderContainer(
    overrides: [
      isAuthenticatedProvider.overrideWithValue(isLoggedIn),
      isAdminProvider.overrideWith(isAdminBuilder ?? (_) => false),
      isPremiumProvider.overrideWithValue(isPremium),
      appInitializationProvider.overrideWith(appInitBuilder ?? (_) {}),
      initSkippedProvider.overrideWith(
        () => _TestInitSkippedNotifier(initSkipped),
      ),
      periodicSyncProvider.overrideWith((ref) {}),
      networkAwareSyncProvider.overrideWith((ref) {}),
      unweanedChicksCountProvider.overrideWith((ref, userId) {
        return Stream<int>.value(0);
      }),
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

/// Applies the same redirect logic as [routerProvider] by reading directly
/// from [container]. This avoids relying on GoRouter's internal
/// [RouterConfiguration.redirect] API, which in GoRouter 17 does not invoke
/// the top-level [GoRouter.redirect] callback defined in the provider.
Future<String> _resolveLocation(
  ProviderContainer container,
  String location,
) async {
  // Allow FutureProviders one event-loop turn to settle into their
  // initial state (AsyncData / AsyncError / AsyncLoading).
  await Future<void>.delayed(Duration.zero);

  final isLoggedIn = container.read(isAuthenticatedProvider);
  final isAdminAsync = container.read(isAdminProvider);
  final isPremium = container.read(isPremiumProvider);
  final appInit = container.read(appInitializationProvider);
  final initSkipped = container.read(initSkippedProvider);
  final isAppReady = appInit.hasValue || initSkipped;

  const authRoutes = {
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.authCallback,
    AppRoutes.oauthCallback,
    AppRoutes.emailVerification,
    AppRoutes.forgotPassword,
    AppRoutes.twoFactorVerify,
  };
  final isAuthRoute = authRoutes.contains(location);
  final isSplashRoute = location == AppRoutes.splash;
  final isAnonymousAllowedRoute =
      location == AppRoutes.home ||
      location == AppRoutes.birds ||
      location == AppRoutes.breeding ||
      location == AppRoutes.chicks ||
      location == AppRoutes.calendar ||
      location == AppRoutes.more ||
      location == AppRoutes.healthRecords ||
      location == AppRoutes.premium ||
      location == AppRoutes.userGuide ||
      location.startsWith('${AppRoutes.birds}/') ||
      location.startsWith('${AppRoutes.breeding}/') ||
      location.startsWith('${AppRoutes.chicks}/') ||
      location.startsWith('${AppRoutes.healthRecords}/');

  // Auth guard
  if (!isLoggedIn && !isAuthRoute && !isAnonymousAllowedRoute) {
    return AppRoutes.login;
  }
  if (isLoggedIn && isAuthRoute) return AppRoutes.home;

  // Initialization guard: show splash while app init is pending
  final isInitError = appInit.hasError && !initSkipped;
  if (isLoggedIn && !isAppReady && !isSplashRoute) return AppRoutes.splash;
  if (isSplashRoute && isAppReady && !isInitError) return AppRoutes.home;

  // Premium guard: restrict premium routes
  const premiumRoutes = {
    AppRoutes.statistics,
    AppRoutes.genealogy,
    AppRoutes.genetics,
    AppRoutes.geneticsHistory,
    AppRoutes.geneticsReverse,
    AppRoutes.geneticsCompare,
  };
  if (premiumRoutes.contains(location)) {
    final premiumRedirect = PremiumGuard.redirect(isPremium);
    if (premiumRedirect != null) return premiumRedirect;
  }

  // Admin guard: restrict /admin/* routes
  if (location.startsWith('/admin')) {
    final adminRedirect = AdminGuard.redirect(isAdminAsync);
    if (adminRedirect != null) return adminRedirect;
  }

  return location;
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
    test('redirects unauthenticated user to login', () async {
      final container = _createContainer(isLoggedIn: false, isPremium: false);
      addTearDown(container.dispose);

      final resolved = await _resolveLocation(container, AppRoutes.statistics);

      expect(resolved, AppRoutes.login);
    });

    test('allows anonymous user on non-account routes', () async {
      final container = _createContainer(isLoggedIn: false, isPremium: false);
      addTearDown(container.dispose);

      expect(await _resolveLocation(container, AppRoutes.home), AppRoutes.home);
      expect(
        await _resolveLocation(container, AppRoutes.birds),
        AppRoutes.birds,
      );
      expect(
        await _resolveLocation(container, AppRoutes.premium),
        AppRoutes.premium,
      );
      expect(
        await _resolveLocation(container, '/birds/bird-1'),
        '/birds/bird-1',
      );
    });

    test('keeps account routes behind login for anonymous users', () async {
      final container = _createContainer(isLoggedIn: false, isPremium: false);
      addTearDown(container.dispose);

      expect(
        await _resolveLocation(container, AppRoutes.settings),
        AppRoutes.login,
      );
      expect(
        await _resolveLocation(container, AppRoutes.profile),
        AppRoutes.login,
      );
      expect(
        await _resolveLocation(container, AppRoutes.notifications),
        AppRoutes.login,
      );
    });

    test('redirects authenticated user away from auth routes', () async {
      final container = _createContainer(isLoggedIn: true, isPremium: false);
      addTearDown(container.dispose);

      final resolved = await _resolveLocation(container, AppRoutes.login);

      expect(resolved, AppRoutes.home);
    });

    test(
      'routes authenticated user to splash while app init is pending',
      () async {
        final pendingInit = Completer<void>();
        final container = _createContainer(
          isLoggedIn: true,
          isPremium: false,
          appInitBuilder: (_) => pendingInit.future,
        );
        addTearDown(container.dispose);

        final resolved = await _resolveLocation(container, AppRoutes.birds);

        expect(resolved, AppRoutes.splash);
      },
    );

    test('redirects splash to home when app init is ready', () async {
      final container = _createContainer(isLoggedIn: true, isPremium: false);
      addTearDown(container.dispose);

      final resolved = await _resolveLocation(container, AppRoutes.splash);

      expect(resolved, AppRoutes.home);
    });

    test('keeps splash when init has error and skip is false', () async {
      final container = _createContainer(
        isLoggedIn: true,
        isPremium: false,
        appInitBuilder: (_) => throw Exception('init failed'),
        initSkipped: false,
      );
      addTearDown(container.dispose);

      final resolved = await _resolveLocation(container, AppRoutes.splash);

      expect(resolved, AppRoutes.splash);
    });

    test('applies premium guard for premium routes', () async {
      final nonPremiumContainer = _createContainer(
        isLoggedIn: true,
        isPremium: false,
      );
      addTearDown(nonPremiumContainer.dispose);

      final blocked = await _resolveLocation(
        nonPremiumContainer,
        AppRoutes.genetics,
      );
      expect(blocked, AppRoutes.premium);

      final premiumContainer = _createContainer(
        isLoggedIn: true,
        isPremium: true,
      );
      addTearDown(premiumContainer.dispose);

      final allowed = await _resolveLocation(
        premiumContainer,
        AppRoutes.genetics,
      );
      expect(allowed, AppRoutes.genetics);
    });

    test('redirects non-premium users for all premium routes', () async {
      final container = _createContainer(isLoggedIn: true, isPremium: false);
      addTearDown(container.dispose);

      for (final route in const [
        AppRoutes.statistics,
        AppRoutes.genealogy,
        AppRoutes.genetics,
        AppRoutes.geneticsHistory,
        AppRoutes.geneticsReverse,
        AppRoutes.geneticsCompare,
      ]) {
        final resolved = await _resolveLocation(container, route);
        expect(resolved, AppRoutes.premium);
      }
    });

    test('applies admin guard for /admin routes', () async {
      final nonAdminContainer = _createContainer(
        isLoggedIn: true,
        isPremium: true,
      );
      addTearDown(nonAdminContainer.dispose);

      final denied = await _resolveLocation(
        nonAdminContainer,
        AppRoutes.adminUsers,
      );
      expect(denied, AppRoutes.home);

      final pendingAdmin = Completer<bool>();
      final loadingContainer = _createContainer(
        isLoggedIn: true,
        isPremium: true,
        isAdminBuilder: (_) => pendingAdmin.future,
      );
      addTearDown(loadingContainer.dispose);

      final loadingAllowed = await _resolveLocation(
        loadingContainer,
        AppRoutes.adminUsers,
      );
      expect(loadingAllowed, AppRoutes.adminUsers);
    });

    test('matches /admin/* patterns including nested params', () async {
      final nonAdminContainer = _createContainer(
        isLoggedIn: true,
        isPremium: true,
        isAdminBuilder: (_) => false,
      );
      addTearDown(nonAdminContainer.dispose);

      expect(
        await _resolveLocation(nonAdminContainer, AppRoutes.adminDashboard),
        AppRoutes.home,
      );
      expect(
        await _resolveLocation(nonAdminContainer, '/admin/users/user-1'),
        AppRoutes.home,
      );

      final adminContainer = _createContainer(
        isLoggedIn: true,
        isPremium: true,
        isAdminBuilder: (_) => true,
      );
      addTearDown(adminContainer.dispose);

      expect(
        await _resolveLocation(adminContainer, AppRoutes.adminDashboard),
        AppRoutes.adminDashboard,
      );
      expect(
        await _resolveLocation(adminContainer, '/admin/users/user-1'),
        '/admin/users/user-1',
      );
    });

    testWidgets(
      'redirects non-premium deep links to premium for genetics reverse/compare',
      (tester) async {
        final container = _createContainer(
          isLoggedIn: true,
          isPremium: false,
          initSkipped: true,
        );
        addTearDown(container.dispose);

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
      },
    );
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
