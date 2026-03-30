import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_post_providers.dart';
import 'package:budgie_breeding_tracker/features/community/screens/community_user_posts_screen.dart';

void main() {
  GoRouter buildRouter(Widget child) {
    return GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(path: '/test', builder: (_, __) => child),
        GoRoute(
          path: '/community/post/:postId',
          builder: (_, __) => const Scaffold(body: Text('post_detail')),
        ),
      ],
    );
  }

  group('CommunityUserPostsScreen', () {
    testWidgets('shows app bar with user posts title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('me'),
            userPostsProvider(
              'target-user',
            ).overrideWith((ref) async => <CommunityPost>[]),
          ],
          child: MaterialApp.router(
            routerConfig: buildRouter(
              const CommunityUserPostsScreen(userId: 'target-user'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.user_posts')), findsOneWidget);
    });

    testWidgets('shows empty state when no posts', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('me'),
            userPostsProvider(
              'target-user',
            ).overrideWith((ref) async => <CommunityPost>[]),
          ],
          child: MaterialApp.router(
            routerConfig: buildRouter(
              const CommunityUserPostsScreen(userId: 'target-user'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.no_user_posts')), findsOneWidget);
    });
  });
}
