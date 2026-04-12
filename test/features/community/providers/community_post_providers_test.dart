@Tags(['community'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';

void main() {
  group('FeedState', () {
    test('initial state has sensible defaults', () {
      const state = FeedState();
      expect(state.posts, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.hasMore, isTrue);
      expect(state.error, isNull);
      expect(state.cursor, isNull);
    });

    test('copyWith updates fields', () {
      const state = FeedState();
      final updated = state.copyWith(
        isLoading: true,
        hasMore: false,
        error: 'network error',
      );

      expect(updated.isLoading, isTrue);
      expect(updated.hasMore, isFalse);
      expect(updated.error, 'network error');
    });

    test('copyWith clears error when null passed', () {
      final state = const FeedState().copyWith(error: 'err');
      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });
  });

  group('CommunityFeedNotifier optimistic methods', () {
    late ProviderContainer container;

    final testPosts = [
      const CommunityPost(
        id: 'p1',
        userId: 'u1',
        username: 'Ali',
        likeCount: 5,
        commentCount: 2,
        isLikedByMe: false,
        isBookmarkedByMe: false,
        isFollowingAuthor: false,
      ),
      const CommunityPost(
        id: 'p2',
        userId: 'u2',
        username: 'Veli',
        likeCount: 10,
        commentCount: 3,
        isLikedByMe: true,
        isBookmarkedByMe: true,
        isFollowingAuthor: true,
      ),
    ];

    setUp(() {
      container = ProviderContainer(
        overrides: [
          communityFeedProvider.overrideWith(
            () => _FakeFeedNotifier(posts: testPosts),
          ),
        ],
      );
      // Access provider to trigger build
      container.read(communityFeedProvider);
    });

    tearDown(() => container.dispose());

    test('optimisticLikeToggle toggles like state', () {
      container.read(communityFeedProvider.notifier).optimisticLikeToggle('p1');
      final posts = container.read(communityFeedProvider).posts;
      final p1 = posts.firstWhere((p) => p.id == 'p1');
      expect(p1.isLikedByMe, isTrue);
      expect(p1.likeCount, 6);
    });

    test('optimisticLikeToggle decrements when already liked', () {
      container.read(communityFeedProvider.notifier).optimisticLikeToggle('p2');
      final posts = container.read(communityFeedProvider).posts;
      final p2 = posts.firstWhere((p) => p.id == 'p2');
      expect(p2.isLikedByMe, isFalse);
      expect(p2.likeCount, 9);
    });

    test('optimisticBookmarkToggle toggles bookmark state', () {
      container
          .read(communityFeedProvider.notifier)
          .optimisticBookmarkToggle('p1');
      final posts = container.read(communityFeedProvider).posts;
      final p1 = posts.firstWhere((p) => p.id == 'p1');
      expect(p1.isBookmarkedByMe, isTrue);
    });

    test('incrementCommentCount adds one', () {
      container
          .read(communityFeedProvider.notifier)
          .incrementCommentCount('p1');
      final posts = container.read(communityFeedProvider).posts;
      final p1 = posts.firstWhere((p) => p.id == 'p1');
      expect(p1.commentCount, 3);
    });

    test('decrementCommentCount subtracts one', () {
      container
          .read(communityFeedProvider.notifier)
          .decrementCommentCount('p2');
      final posts = container.read(communityFeedProvider).posts;
      final p2 = posts.firstWhere((p) => p.id == 'p2');
      expect(p2.commentCount, 2);
    });

    test('decrementCommentCount does not go below zero', () {
      container
          .read(communityFeedProvider.notifier)
          .decrementCommentCount('p1');
      container
          .read(communityFeedProvider.notifier)
          .decrementCommentCount('p1');
      container
          .read(communityFeedProvider.notifier)
          .decrementCommentCount('p1');
      final posts = container.read(communityFeedProvider).posts;
      final p1 = posts.firstWhere((p) => p.id == 'p1');
      expect(p1.commentCount, 0);
    });

    test('optimisticFollowToggle toggles follow for all posts of user', () {
      container
          .read(communityFeedProvider.notifier)
          .optimisticFollowToggle('u1');
      final posts = container.read(communityFeedProvider).posts;
      final u1Posts = posts.where((p) => p.userId == 'u1');
      for (final p in u1Posts) {
        expect(p.isFollowingAuthor, isTrue);
      }
    });

    test('removePost removes post from list', () {
      container.read(communityFeedProvider.notifier).removePost('p1');
      final posts = container.read(communityFeedProvider).posts;
      expect(posts.length, 1);
      expect(posts.first.id, 'p2');
    });
  });

  group('CommunityPost model', () {
    test('allImageUrls combines imageUrl and imageUrls', () {
      const post = CommunityPost(
        id: 'p1',
        userId: 'u1',
        imageUrl: 'img0.jpg',
        imageUrls: ['img1.jpg', 'img2.jpg'],
      );
      expect(post.allImageUrls, ['img0.jpg', 'img1.jpg', 'img2.jpg']);
    });

    test('allImageUrls excludes null imageUrl', () {
      const post = CommunityPost(
        id: 'p1',
        userId: 'u1',
        imageUrls: ['img1.jpg'],
      );
      expect(post.allImageUrls, ['img1.jpg']);
    });

    test('primaryImageUrl returns first image', () {
      const post = CommunityPost(id: 'p1', userId: 'u1', imageUrl: 'first.jpg');
      expect(post.primaryImageUrl, 'first.jpg');
    });

    test('primaryImageUrl returns null when no images', () {
      const post = CommunityPost(id: 'p1', userId: 'u1');
      expect(post.primaryImageUrl, isNull);
    });
  });
}

class _FakeFeedNotifier extends CommunityFeedNotifier {
  final List<CommunityPost> _posts;

  _FakeFeedNotifier({List<CommunityPost>? posts}) : _posts = posts ?? const [];

  @override
  FeedState build() => FeedState(posts: _posts, isLoading: false);

  @override
  Future<void> fetchInitial() async {}

  @override
  Future<void> fetchMore() async {}
}
