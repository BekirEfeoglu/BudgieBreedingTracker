import 'package:go_router/go_router.dart';

import '../../features/community/screens/community_bookmarks_screen.dart';
import '../../features/community/screens/community_create_post_screen.dart';
import '../../features/community/screens/community_post_detail_screen.dart';
import '../../features/community/screens/community_screen.dart';
import '../../features/community/screens/community_search_screen.dart';
import '../../features/community/screens/community_user_posts_screen.dart';
import '../route_names.dart';

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
        builder: (context, state) =>
            CommunityPostDetailScreen(postId: state.pathParameters['postId']!),
      ),
      GoRoute(
        path: 'user/:userId',
        builder: (context, state) =>
            CommunityUserPostsScreen(userId: state.pathParameters['userId']!),
      ),
    ],
  ),
];
