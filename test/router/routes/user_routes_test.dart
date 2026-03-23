import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/router/routes/user_routes.dart';

void main() {
  group('buildUserRoutes', () {
    late List<RouteBase> userRoutes;

    setUp(() {
      userRoutes = buildUserRoutes();
    });

    test('returns a list of RouteBase', () {
      expect(userRoutes, isA<List<RouteBase>>());
    });

    test('returns a non-empty list', () {
      expect(userRoutes, isNotEmpty);
    });

    group('premium-gated routes', () {
      test('contains statistics route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.statistics));
      });

      test('contains genealogy route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.genealogy));
      });

      test('contains genetics route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.genetics));
      });

      test('contains geneticsHistory route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.geneticsHistory));
      });

      test('contains geneticsReverse route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.geneticsReverse));
      });

      test('contains geneticsCompare route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.geneticsCompare));
      });
    });

    group('user routes', () {
      test('contains profile route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.profile));
      });

      test('contains settings route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.settings));
      });

      test('contains premium route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.premium));
      });

      test('contains userGuide route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.userGuide));
      });

      test('contains notifications route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.notifications));
      });

      test('contains notificationSettings route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.notificationSettings));
      });

      test('contains backup route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.backup));
      });

      test('contains feedback route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.feedback));
      });
    });

    group('legal routes', () {
      test('contains privacyPolicy route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.privacyPolicy));
      });

      test('contains termsOfService route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.termsOfService));
      });

      test('contains communityGuidelines route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.communityGuidelines));
      });
    });

    group('two-factor authentication routes', () {
      test('contains twoFactorSetup route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.twoFactorSetup));
      });

      test('contains twoFactorVerify route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.twoFactorVerify));
      });
    });

    group('health record routes', () {
      test('contains healthRecords route', () {
        final paths = _extractTopLevelPaths(userRoutes);
        expect(paths, contains(AppRoutes.healthRecords));
      });

      test('healthRecords route has nested routes', () {
        final healthRoute = userRoutes
            .whereType<GoRoute>()
            .firstWhere((r) => r.path == AppRoutes.healthRecords);
        expect(healthRoute.routes, isNotEmpty);
      });

      test('healthRecords has form and :id nested routes', () {
        final healthRoute = userRoutes
            .whereType<GoRoute>()
            .firstWhere((r) => r.path == AppRoutes.healthRecords);
        final nestedPaths =
            healthRoute.routes.whereType<GoRoute>().map((r) => r.path).toList();
        expect(nestedPaths, contains('form'));
        expect(nestedPaths, contains(':id'));
      });

      test('form route comes before :id route (specific before parameterized)', () {
        final healthRoute = userRoutes
            .whereType<GoRoute>()
            .firstWhere((r) => r.path == AppRoutes.healthRecords);
        final nestedPaths =
            healthRoute.routes.whereType<GoRoute>().map((r) => r.path).toList();

        final formIndex = nestedPaths.indexOf('form');
        final idIndex = nestedPaths.indexOf(':id');

        expect(
          formIndex,
          lessThan(idIndex),
          reason: 'form must come before :id to prevent route capture',
        );
      });
    });

    group('all routes have builders', () {
      test('all top-level GoRoutes have builder or pageBuilder', () {
        for (final route in userRoutes.whereType<GoRoute>()) {
          final hasBuilder = route.builder != null || route.pageBuilder != null;
          expect(
            hasBuilder,
            isTrue,
            reason: 'Route ${route.path} should have a builder or pageBuilder',
          );
        }
      });
    });

    group('all top-level routes start with /', () {
      test('every top-level route path is absolute', () {
        for (final route in userRoutes.whereType<GoRoute>()) {
          expect(
            route.path,
            startsWith('/'),
            reason: 'Route ${route.path} should be an absolute path',
          );
        }
      });
    });

    group('geneticsCompare route handles extra parameter', () {
      test('geneticsCompare route has a builder', () {
        final compareRoute = userRoutes
            .whereType<GoRoute>()
            .firstWhere((r) => r.path == AppRoutes.geneticsCompare);
        expect(compareRoute.builder, isNotNull);
      });
    });

    group('twoFactorVerify route handles query parameters', () {
      test('twoFactorVerify route has a builder', () {
        final verifyRoute = userRoutes
            .whereType<GoRoute>()
            .firstWhere((r) => r.path == AppRoutes.twoFactorVerify);
        expect(verifyRoute.builder, isNotNull);
      });

      test('twoFactorVerify path does not contain inline params', () {
        final verifyRoute = userRoutes
            .whereType<GoRoute>()
            .firstWhere((r) => r.path == AppRoutes.twoFactorVerify);
        expect(verifyRoute.path, isNot(contains(':factorId')));
      });
    });
  });
}

List<String> _extractTopLevelPaths(List<RouteBase> routes) {
  return routes.whereType<GoRoute>().map((r) => r.path).toList();
}
