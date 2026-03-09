import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_providers.dart';

void main() {
  group('FeedState', () {
    test('has sensible defaults', () {
      const state = FeedState();

      expect(state.posts, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.hasMore, isTrue);
      expect(state.error, isNull);
      expect(state.cursor, isNull);
    });

    test('copyWith updates specified fields', () {
      const state = FeedState();

      final updated = state.copyWith(
        isLoading: true,
        hasMore: false,
        error: 'test error',
      );

      expect(updated.isLoading, isTrue);
      expect(updated.hasMore, isFalse);
      expect(updated.error, 'test error');
      expect(updated.posts, isEmpty);
    });

    test('copyWith with posts', () {
      const state = FeedState();

      final posts = [
        CommunityPost(
          id: '1',
          userId: 'u1',
          username: 'alice',
          content: 'Hello',
          createdAt: DateTime(2024),
        ),
      ];

      final updated = state.copyWith(posts: posts);

      expect(updated.posts.length, 1);
      expect(updated.posts.first.id, '1');
    });

    test('copyWith clears error when set to null', () {
      final state = const FeedState().copyWith(error: 'oops');
      expect(state.error, 'oops');

      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });
  });

  group('CommunityFeedNotifier (unit)', () {
    CommunityPost makePost(String id, {bool liked = false, bool bookmarked = false}) {
      return CommunityPost(
        id: id,
        userId: 'u1',
        username: 'user',
        content: 'Post $id',
        likeCount: liked ? 1 : 0,
        isLikedByMe: liked,
        isBookmarkedByMe: bookmarked,
        createdAt: DateTime(2024),
      );
    }

    test('optimisticLikeToggle toggles like state and count', () {
      final container = ProviderContainer(
        overrides: [
          communityFeedProvider.overrideWith(() => _TestFeedNotifier([
                makePost('1'),
                makePost('2'),
              ])),
        ],
      );
      addTearDown(container.dispose);

      // Read to trigger build
      container.read(communityFeedProvider);

      // Toggle like on post 1
      container.read(communityFeedProvider.notifier).optimisticLikeToggle('1');

      final state = container.read(communityFeedProvider);
      final post1 = state.posts.firstWhere((p) => p.id == '1');
      expect(post1.isLikedByMe, isTrue);
      expect(post1.likeCount, 1);

      // Toggle back
      container.read(communityFeedProvider.notifier).optimisticLikeToggle('1');
      final state2 = container.read(communityFeedProvider);
      final post1b = state2.posts.firstWhere((p) => p.id == '1');
      expect(post1b.isLikedByMe, isFalse);
      expect(post1b.likeCount, 0);
    });

    test('optimisticBookmarkToggle toggles bookmark state', () {
      final container = ProviderContainer(
        overrides: [
          communityFeedProvider.overrideWith(() => _TestFeedNotifier([
                makePost('1'),
              ])),
        ],
      );
      addTearDown(container.dispose);

      container.read(communityFeedProvider);

      container
          .read(communityFeedProvider.notifier)
          .optimisticBookmarkToggle('1');

      final state = container.read(communityFeedProvider);
      expect(state.posts.first.isBookmarkedByMe, isTrue);
    });

    test('incrementCommentCount increments for correct post', () {
      final container = ProviderContainer(
        overrides: [
          communityFeedProvider.overrideWith(() => _TestFeedNotifier([
                makePost('1'),
                makePost('2'),
              ])),
        ],
      );
      addTearDown(container.dispose);

      container.read(communityFeedProvider);

      container.read(communityFeedProvider.notifier).incrementCommentCount('2');

      final state = container.read(communityFeedProvider);
      expect(state.posts[0].commentCount, 0);
      expect(state.posts[1].commentCount, 1);
    });

    test('removePost removes post from list', () {
      final container = ProviderContainer(
        overrides: [
          communityFeedProvider.overrideWith(() => _TestFeedNotifier([
                makePost('1'),
                makePost('2'),
                makePost('3'),
              ])),
        ],
      );
      addTearDown(container.dispose);

      container.read(communityFeedProvider);

      container.read(communityFeedProvider.notifier).removePost('2');

      final state = container.read(communityFeedProvider);
      expect(state.posts.length, 2);
      expect(state.posts.map((p) => p.id).toList(), ['1', '3']);
    });
  });
}

/// Test notifier that skips Supabase calls and just sets initial posts.
class _TestFeedNotifier extends CommunityFeedNotifier {
  final List<CommunityPost> _initialPosts;

  _TestFeedNotifier(this._initialPosts);

  @override
  FeedState build() => FeedState(
        posts: _initialPosts,
        isLoading: false,
        hasMore: false,
      );
}
