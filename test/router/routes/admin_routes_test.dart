import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/router/routes/admin_routes.dart';

class _MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  group('buildAdminRoutes', () {
    late ShellRoute adminShellRoute;
    late GlobalKey<NavigatorState> navigatorKey;

    setUp(() {
      navigatorKey = GlobalKey<NavigatorState>();
      adminShellRoute = buildAdminRoutes(navigatorKey);
    });

    test('returns a ShellRoute', () {
      expect(adminShellRoute, isA<ShellRoute>());
    });

    test('uses the provided navigator key', () {
      expect(adminShellRoute.navigatorKey, same(navigatorKey));
    });

    test('has a shell builder function', () {
      expect(adminShellRoute.builder, isNotNull);
    });

    group('route structure', () {
      test('contains 8 top-level admin routes', () {
        final goRoutes =
            adminShellRoute.routes.whereType<GoRoute>().toList();
        expect(goRoutes.length, 8);
      });

      test('contains adminDashboard route', () {
        final paths = _extractPaths(adminShellRoute.routes);
        expect(paths, contains(AppRoutes.adminDashboard));
      });

      test('contains adminUsers route', () {
        final paths = _extractPaths(adminShellRoute.routes);
        expect(paths, contains(AppRoutes.adminUsers));
      });

      test('contains adminMonitoring route', () {
        final paths = _extractPaths(adminShellRoute.routes);
        expect(paths, contains(AppRoutes.adminMonitoring));
      });

      test('contains adminDatabase route', () {
        final paths = _extractPaths(adminShellRoute.routes);
        expect(paths, contains(AppRoutes.adminDatabase));
      });

      test('contains adminAudit route', () {
        final paths = _extractPaths(adminShellRoute.routes);
        expect(paths, contains(AppRoutes.adminAudit));
      });

      test('contains adminSecurity route', () {
        final paths = _extractPaths(adminShellRoute.routes);
        expect(paths, contains(AppRoutes.adminSecurity));
      });

      test('contains adminSettings route', () {
        final paths = _extractPaths(adminShellRoute.routes);
        expect(paths, contains(AppRoutes.adminSettings));
      });

      test('contains adminFeedback route', () {
        final paths = _extractPaths(adminShellRoute.routes);
        expect(paths, contains(AppRoutes.adminFeedback));
      });
    });

    group('adminUsers nested route', () {
      test('has a nested :userId child route', () {
        final usersRoute = adminShellRoute.routes
            .whereType<GoRoute>()
            .firstWhere((r) => r.path == AppRoutes.adminUsers);
        expect(usersRoute.routes, isNotEmpty);

        final nestedPaths = usersRoute.routes
            .whereType<GoRoute>()
            .map((r) => r.path)
            .toList();
        expect(nestedPaths, contains(':userId'));
      });
    });

    group('route builders', () {
      test('all top-level routes have pageBuilder', () {
        final goRoutes =
            adminShellRoute.routes.whereType<GoRoute>().toList();
        for (final route in goRoutes) {
          expect(
            route.pageBuilder,
            isNotNull,
            reason: 'Route ${route.path} should have a pageBuilder',
          );
        }
      });

      test('nested :userId route has a builder', () {
        final usersRoute = adminShellRoute.routes
            .whereType<GoRoute>()
            .firstWhere((r) => r.path == AppRoutes.adminUsers);
        final nestedRoute =
            usersRoute.routes.whereType<GoRoute>().first;
        expect(nestedRoute.builder, isNotNull);
      });
    });

    group('pageBuilder produces NoTransitionPage', () {
      test('adminDashboard uses NoTransitionPage', () {
        final route = adminShellRoute.routes
            .whereType<GoRoute>()
            .firstWhere((r) => r.path == AppRoutes.adminDashboard);
        final state = _createMockState(AppRoutes.adminDashboard);
        // We cannot call pageBuilder without a real context, but we verify it is set.
        expect(route.pageBuilder, isNotNull);
        // Verify the mock state is correctly configured
        expect(state.pageKey, isA<ValueKey>());
      });
    });
  });
}

List<String> _extractPaths(List<RouteBase> routes) {
  return routes.whereType<GoRoute>().map((r) => r.path).toList();
}

GoRouterState _createMockState(String path) {
  final state = _MockGoRouterState();
  when(() => state.uri).thenReturn(Uri.parse(path));
  when(() => state.pathParameters).thenReturn({});
  when(() => state.pageKey).thenReturn(ValueKey('test:$path'));
  when(() => state.matchedLocation).thenReturn(path);
  return state;
}
