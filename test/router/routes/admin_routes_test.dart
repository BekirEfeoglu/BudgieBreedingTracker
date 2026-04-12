import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/router/routes/admin_routes.dart';

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

    group('route structure', () {
      test('contains all expected admin route paths', () {
        final goRoutes = adminShellRoute.routes.whereType<GoRoute>().toList();
        final paths = _extractPaths(adminShellRoute.routes);
        expect(goRoutes, isNotEmpty);
        expect(
          paths,
          containsAll([
            AppRoutes.adminDashboard,
            AppRoutes.adminUsers,
            AppRoutes.adminMonitoring,
            AppRoutes.adminDatabase,
            AppRoutes.adminAudit,
            AppRoutes.adminSecurity,
            AppRoutes.adminSettings,
            AppRoutes.adminFeedback,
          ]),
        );
        expect(paths.toSet().length, paths.length);
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
  });
}

List<String> _extractPaths(List<RouteBase> routes) {
  return routes.whereType<GoRoute>().map((r) => r.path).toList();
}
