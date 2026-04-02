import 'package:go_router/go_router.dart';

import '../../core/widgets/not_found_screen.dart';
import '../../features/gamification/screens/badge_detail_screen.dart';
import '../../features/gamification/screens/badges_screen.dart';
import '../../features/gamification/screens/leaderboard_screen.dart';
import '../route_names.dart';
import '../route_utils.dart';

List<RouteBase> buildGamificationRoutes() => [
      GoRoute(
        path: AppRoutes.badges,
        builder: (context, state) => const BadgesScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              if (!isValidRouteId(id)) return const NotFoundScreen();
              return BadgeDetailScreen(badgeId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        builder: (context, state) => const LeaderboardScreen(),
      ),
    ];
