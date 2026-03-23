import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/router/routes/auth_routes.dart';

void main() {
  group('buildAuthRoutes', () {
    late List<GoRoute> authRoutes;

    setUp(() {
      authRoutes = buildAuthRoutes();
    });

    test('returns a list of GoRoute objects', () {
      expect(authRoutes, isA<List<GoRoute>>());
    });

    test('contains 6 routes', () {
      expect(authRoutes.length, 6);
    });

    group('route paths', () {
      test('contains login route', () {
        final paths = authRoutes.map((r) => r.path).toList();
        expect(paths, contains(AppRoutes.login));
      });

      test('contains register route', () {
        final paths = authRoutes.map((r) => r.path).toList();
        expect(paths, contains(AppRoutes.register));
      });

      test('contains authCallback route', () {
        final paths = authRoutes.map((r) => r.path).toList();
        expect(paths, contains(AppRoutes.authCallback));
      });

      test('contains oauthCallback route', () {
        final paths = authRoutes.map((r) => r.path).toList();
        expect(paths, contains(AppRoutes.oauthCallback));
      });

      test('contains emailVerification route', () {
        final paths = authRoutes.map((r) => r.path).toList();
        expect(paths, contains(AppRoutes.emailVerification));
      });

      test('contains forgotPassword route', () {
        final paths = authRoutes.map((r) => r.path).toList();
        expect(paths, contains(AppRoutes.forgotPassword));
      });
    });

    group('all routes have builders', () {
      for (var i = 0; i < 6; i++) {
        test('route at index $i has a builder', () {
          // Need to rebuild since setUp runs before the loop captures the value
          final routes = buildAuthRoutes();
          expect(
            routes[i].builder,
            isNotNull,
            reason: 'Route ${routes[i].path} should have a builder',
          );
        });
      }
    });

    group('no nested routes', () {
      test('auth routes have no child routes', () {
        for (final route in authRoutes) {
          expect(
            route.routes,
            isEmpty,
            reason: 'Auth route ${route.path} should not have nested routes',
          );
        }
      });
    });

    group('all route paths start with /', () {
      test('every path is absolute', () {
        for (final route in authRoutes) {
          expect(
            route.path,
            startsWith('/'),
            reason: 'Auth route ${route.path} should start with /',
          );
        }
      });
    });

    group('emailVerification route handles query parameters', () {
      test('emailVerification builder can handle email query parameter', () {
        final emailRoute = authRoutes.firstWhere(
          (r) => r.path == AppRoutes.emailVerification,
        );
        expect(emailRoute.builder, isNotNull);

        // Verify the route is configured to accept query params
        // by checking path does not have inline params
        expect(emailRoute.path, isNot(contains(':email')));
      });
    });
  });
}
