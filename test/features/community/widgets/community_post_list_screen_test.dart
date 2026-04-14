@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_post_list_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CommunityPost _testPost({
  String id = 'post-1',
  String content = 'Test content',
}) {
  return CommunityPost(
    id: id,
    userId: 'user-1',
    username: 'TestUser',
    avatarUrl: null,
    title: null,
    content: content,
    imageUrl: null,
    postType: CommunityPostType.general,
    likeCount: 0,
    commentCount: 0,
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
  );
}

class _FakeFeedNotifier extends CommunityFeedNotifier {
  @override
  FeedState build() => const FeedState(isLoading: false);

  @override
  Future<void> fetchInitial() async {}

  @override
  Future<void> fetchMore() async {}
}

GoRouter _buildRouter(Widget child) {
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

Widget _buildSubject({
  required AsyncValue<List<CommunityPost>> postsAsync,
  Future<void> Function()? onRefresh,
}) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      communityFeedProvider.overrideWith(() => _FakeFeedNotifier()),
    ],
    child: MaterialApp.router(
      routerConfig: _buildRouter(
        CommunityPostListScreen(
          appBarTitle: 'Test Title',
          postsAsync: postsAsync,
          onRefresh: onRefresh ?? () async {},
          emptyIcon: const Icon(Icons.list),
          emptyTitle: 'Nothing here',
          emptySubtitle: 'Check back later',
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CommunityPostListScreen', () {
    testWidgets('renders app bar title', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          postsAsync: const AsyncData(<CommunityPost>[]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('shows empty state when list is empty', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          postsAsync: const AsyncData(<CommunityPost>[]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Check back later'), findsOneWidget);
    });

    testWidgets('shows post cards when list has data', (tester) async {
      final posts = [_testPost(id: 'p1', content: 'Hello budgie')];
      await tester.pumpWidget(
        _buildSubject(
          postsAsync: AsyncData(posts),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello budgie'), findsOneWidget);
      expect(find.text('Nothing here'), findsNothing);
    });

    testWidgets('shows error state on failure', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          postsAsync: AsyncError(Exception('network error'), StackTrace.empty),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(l10n('common.data_load_error')),
        findsOneWidget,
      );
    });

    testWidgets('shows skeleton while loading', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          postsAsync: const AsyncLoading<List<CommunityPost>>(),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('community_feed_skeleton')), findsOneWidget);
    });
  });
}
