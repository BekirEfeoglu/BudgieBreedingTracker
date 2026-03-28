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

    group('route paths', () {
      test('contains all expected auth paths without duplicates', () {
        final paths = authRoutes.map((r) => r.path).toList();
        expect(
          paths,
          containsAll([
            AppRoutes.login,
            AppRoutes.register,
            AppRoutes.authCallback,
            AppRoutes.oauthCallback,
            AppRoutes.emailVerification,
            AppRoutes.forgotPassword,
          ]),
        );
        expect(paths.toSet().length, paths.length);
      });
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
      test('emailVerification path does not use inline email params', () {
        final emailRoute = authRoutes.firstWhere(
          (r) => r.path == AppRoutes.emailVerification,
        );
        expect(emailRoute.path, isNot(contains(':email')));
      });
    });
  });
}
