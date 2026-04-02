import 'package:go_router/go_router.dart';

import '../../core/widgets/not_found_screen.dart';
import '../../features/messaging/screens/group_form_screen.dart';
import '../../features/messaging/screens/message_detail_screen.dart';
import '../../features/messaging/screens/messages_screen.dart';
import '../../features/messaging/screens/new_dm_screen.dart';
import '../route_names.dart';
import '../route_utils.dart';

List<RouteBase> buildMessagingRoutes() => [
      GoRoute(
        path: AppRoutes.messages,
        builder: (context, state) => const MessagesScreen(),
        routes: [
          // Specific paths BEFORE parameterized paths
          GoRoute(
            path: 'new',
            builder: (context, state) => const NewDmScreen(),
          ),
          GoRoute(
            path: 'group/form',
            builder: (context, state) => const GroupFormScreen(),
          ),
          // Parameterized paths AFTER specific paths
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              if (!isValidRouteId(id)) return const NotFoundScreen();
              return MessageDetailScreen(conversationId: id);
            },
          ),
        ],
      ),
    ];
