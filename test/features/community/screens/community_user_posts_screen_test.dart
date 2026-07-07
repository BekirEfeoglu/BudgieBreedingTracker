@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_post_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_providers.dart';
import 'package:budgie_breeding_tracker/features/community/screens/community_user_posts_screen.dart';
import 'package:budgie_breeding_tracker/shared/providers/gamification.dart';

class _EmptyMutedUsersNotifier extends MutedUsersNotifier {
  @override
  List<String> build() => [];
}

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
        GoRoute(
          path: '/profile',
          builder: (_, __) => const Scaffold(body: Text('profile_route')),
        ),
      ],
    );
  }

  overridesFor({
    List<CommunityPost> posts = const [],
    String currentUserId = 'me',
  }) {
    return [
      currentUserIdProvider.overrideWithValue(currentUserId),
      publicUserProfileProvider('target-user').overrideWith(
        (ref) async => {
          'display_name': 'Ada',
          'avatar_url': null,
          'is_verified_breeder': false,
        },
      ),
      followedUsersProvider.overrideWith(
        (ref) async => <Map<String, dynamic>>[],
      ),
      badgesProvider.overrideWith((ref) async => const []),
      userBadgesProvider('target-user').overrideWith((ref) async => const []),
      mutedUsersProvider.overrideWith(_EmptyMutedUsersNotifier.new),
      userPostsProvider('target-user').overrideWith((ref) async => posts),
    ];
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    List<CommunityPost> posts = const [],
    String currentUserId = 'me',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesFor(posts: posts, currentUserId: currentUserId),
        child: MaterialApp.router(
          routerConfig: buildRouter(
            const CommunityUserPostsScreen(userId: 'target-user'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  }

  group('CommunityUserPostsScreen', () {
    testWidgets('shows app bar with user profile title', (tester) async {
      await pumpScreen(tester);

      expect(find.text(l10n('community.user_profile')), findsOneWidget);
    });

    testWidgets('uses profile-style sliver app bar and card header', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(SliverAppBar), findsOneWidget);
      expect(
        find.ancestor(of: find.text('Ada'), matching: find.byType(Card)),
        findsOneWidget,
      );
    });

    testWidgets('opens the normal profile route for the current user', (
      tester,
    ) async {
      await pumpScreen(tester, currentUserId: 'target-user');
      await tester.pumpAndSettle();

      expect(find.text('profile_route'), findsOneWidget);
      expect(find.text(l10n('community.user_profile')), findsNothing);
    });

    testWidgets('shows empty state when no posts', (tester) async {
      await pumpScreen(tester);

      expect(find.text(l10n('community.no_user_posts')), findsOneWidget);
    });

    testWidgets('renders posts from userPostsProvider', (tester) async {
      await pumpScreen(
        tester,
        posts: const [
          CommunityPost(
            id: 'post-1',
            userId: 'target-user',
            username: 'Ada',
            content: 'Merhaba topluluk',
          ),
        ],
      );

      await tester.scrollUntilVisible(
        find.text('Merhaba topluluk'),
        300,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('Merhaba topluluk'), findsOneWidget);
    });
  });
}
