import 'package:go_router/go_router.dart';

import '../../core/widgets/not_found_screen.dart';
import '../../features/community/screens/community_bookmarks_screen.dart';
import '../../features/community/screens/community_create_post_screen.dart';
import '../../features/community/screens/community_post_detail_screen.dart';
import '../../features/community/screens/community_screen.dart';
import '../../features/community/screens/community_search_screen.dart';
import '../../features/community/screens/community_user_posts_screen.dart';
import '../route_names.dart';
import '../route_utils.dart';

/// Community feature routes (feed, posts, comments, bookmarks, search).
List<RouteBase> buildCommunityRoutes() => [
  GoRoute(
    path: AppRoutes.community,
    builder: (context, state) => const CommunityScreen(),
    routes: [
      // Specific paths BEFORE parameterized paths
      GoRoute(
        path: 'create',
        builder: (context, state) => const CommunityCreatePostScreen(),
      ),
      GoRoute(
        path: 'bookmarks',
        builder: (context, state) => const CommunityBookmarksScreen(),
      ),
      GoRoute(
        path: 'search',
        builder: (context, state) => const CommunitySearchScreen(),
      ),
      // Parameterized paths AFTER specific paths
      GoRoute(
        path: 'post/:postId',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          if (!isValidRouteId(postId)) return const NotFoundScreen();
          return CommunityPostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: 'user/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          if (!isValidRouteId(userId)) return const NotFoundScreen();
          return CommunityUserPostsScreen(userId: userId);
        },
      ),
    ],
  ),
];
