import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/router/routes/community_routes.dart';

void main() {
  group('buildCommunityRoutes', () {
    late List<RouteBase> communityRoutes;

    setUp(() {
      communityRoutes = buildCommunityRoutes();
    });

    test('returns a list of RouteBase', () {
      expect(communityRoutes, isA<List<RouteBase>>());
    });

    test('top-level route is the community path', () {
      final topRoute = communityRoutes.first as GoRoute;
      expect(topRoute.path, AppRoutes.community);
    });

    group('nested routes', () {
      late List<RouteBase> nestedRoutes;

      setUp(() {
        final topRoute = communityRoutes.first as GoRoute;
        nestedRoutes = topRoute.routes;
      });

      test('contains expected nested paths without duplicates', () {
        final paths = _extractPaths(nestedRoutes);
        expect(
          paths,
          containsAll([
            'create',
            'bookmarks',
            'search',
            'post/:postId',
            'user/:userId',
          ]),
        );
        expect(paths.toSet().length, paths.length);
      });
    });

    group('route ordering — specific before parameterized', () {
      test('create comes before post/:postId', () {
        final topRoute = communityRoutes.first as GoRoute;
        final paths = _extractPaths(topRoute.routes);

        final createIndex = paths.indexOf('create');
        final postDetailIndex = paths.indexOf('post/:postId');

        expect(
          createIndex,
          lessThan(postDetailIndex),
          reason:
              'Specific path "create" must come before parameterized "post/:postId"',
        );
      });

      test('bookmarks comes before user/:userId', () {
        final topRoute = communityRoutes.first as GoRoute;
        final paths = _extractPaths(topRoute.routes);

        final bookmarksIndex = paths.indexOf('bookmarks');
        final userPostsIndex = paths.indexOf('user/:userId');

        expect(
          bookmarksIndex,
          lessThan(userPostsIndex),
          reason:
              'Specific path "bookmarks" must come before parameterized "user/:userId"',
        );
      });

      test('search comes before parameterized routes', () {
        final topRoute = communityRoutes.first as GoRoute;
        final paths = _extractPaths(topRoute.routes);

        final searchIndex = paths.indexOf('search');
        final postDetailIndex = paths.indexOf('post/:postId');
        final userPostsIndex = paths.indexOf('user/:userId');

        expect(
          searchIndex,
          lessThan(postDetailIndex),
          reason: 'Specific path "search" must come before "post/:postId"',
        );
        expect(
          searchIndex,
          lessThan(userPostsIndex),
          reason: 'Specific path "search" must come before "user/:userId"',
        );
      });
    });

    group('parameterized routes', () {
      test('post/:postId has :postId parameter in path', () {
        final topRoute = communityRoutes.first as GoRoute;
        final postRoute = topRoute.routes.whereType<GoRoute>().firstWhere(
          (r) => r.path == 'post/:postId',
        );
        expect(postRoute.path, contains(':postId'));
      });

      test('user/:userId has :userId parameter in path', () {
        final topRoute = communityRoutes.first as GoRoute;
        final userRoute = topRoute.routes.whereType<GoRoute>().firstWhere(
          (r) => r.path == 'user/:userId',
        );
        expect(userRoute.path, contains(':userId'));
      });
    });
  });
}

List<String> _extractPaths(List<RouteBase> routes) {
  return routes.whereType<GoRoute>().map((r) => r.path).toList();
}
