import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_providers.dart';

void main() {
  final now = DateTime.now();

  CommunityPost makePost(
    String id, {
    String userId = 'u1',
    CommunityPostType postType = CommunityPostType.general,
    int likeCount = 0,
    int commentCount = 0,
    bool isFollowingAuthor = false,
    DateTime? createdAt,
  }) {
    return CommunityPost(
      id: id,
      userId: userId,
      username: 'user-$userId',
      postType: postType,
      likeCount: likeCount,
      commentCount: commentCount,
      isFollowingAuthor: isFollowingAuthor,
      createdAt: createdAt ?? now,
    );
  }

  ProviderContainer createContainer({
    required List<CommunityPost> posts,
    String currentUserId = 'me',
    List<String> blockedUserIds = const [],
  }) {
    return ProviderContainer(
      overrides: [
        communityFeedProvider.overrideWith(
          () => _FakeFeedNotifier(posts: posts),
        ),
        currentUserIdProvider.overrideWithValue(currentUserId),
        blockedUsersProvider.overrideWith(
          () => _FakeBlockedUsersNotifier(blockedUserIds),
        ),
      ],
    );
  }

  group('communityVisiblePostsProvider - explore tab', () {
    test('returns all posts sorted by newest', () {
      final posts = [
        makePost('p1', createdAt: now.subtract(const Duration(hours: 2))),
        makePost('p2', createdAt: now.subtract(const Duration(hours: 1))),
        makePost('p3', createdAt: now),
      ];

      final container = createContainer(posts: posts);
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      final visible = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.explore),
      );

      expect(visible.length, 3);
      expect(visible.first.id, 'p3');
      expect(visible.last.id, 'p1');
    });

    test('sorts by trending when explore sort is trending', () {
      final posts = [
        makePost('low', likeCount: 1, commentCount: 0,
            createdAt: now.subtract(const Duration(hours: 1))),
        makePost('high', likeCount: 50, commentCount: 10,
            createdAt: now.subtract(const Duration(hours: 2))),
      ];

      final container = createContainer(posts: posts);
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      container.read(exploreSortProvider.notifier).state =
          CommunityExploreSort.trending;

      final visible = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.explore),
      );

      // 'high' engagement: 50*2 + 10 = 110, 'low': 1*2 + 0 = 2
      expect(visible.first.id, 'high');
      expect(visible.last.id, 'low');
    });

    test('trending sort falls back to newest on tie', () {
      final posts = [
        makePost('older', likeCount: 5, commentCount: 0,
            createdAt: now.subtract(const Duration(hours: 2))),
        makePost('newer', likeCount: 5, commentCount: 0,
            createdAt: now.subtract(const Duration(hours: 1))),
      ];

      final container = createContainer(posts: posts);
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      container.read(exploreSortProvider.notifier).state =
          CommunityExploreSort.trending;

      final visible = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.explore),
      );

      // Same engagement, newer first
      expect(visible.first.id, 'newer');
    });
  });

  group('communityVisiblePostsProvider - following tab', () {
    test('shows only followed authors, excludes own posts', () {
      final posts = [
        makePost('followed', userId: 'u1', isFollowingAuthor: true,
            createdAt: now),
        makePost('not-followed', userId: 'u2', isFollowingAuthor: false,
            createdAt: now),
        makePost('own', userId: 'me', isFollowingAuthor: false,
            createdAt: now),
      ];

      final container = createContainer(posts: posts);
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      final visible = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.following),
      );

      expect(visible.length, 1);
      expect(visible.first.id, 'followed');
    });

    test('always sorts by newest regardless of explore sort setting', () {
      final posts = [
        makePost('p1', userId: 'u1', isFollowingAuthor: true,
            likeCount: 100,
            createdAt: now.subtract(const Duration(hours: 2))),
        makePost('p2', userId: 'u1', isFollowingAuthor: true,
            likeCount: 1,
            createdAt: now.subtract(const Duration(hours: 1))),
      ];

      final container = createContainer(posts: posts);
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      // Set trending sort
      container.read(exploreSortProvider.notifier).state =
          CommunityExploreSort.trending;

      final visible = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.following),
      );

      // Should still be newest first, not trending
      expect(visible.first.id, 'p2');
    });
  });

  group('communityVisiblePostsProvider - guides tab', () {
    test('shows only guide-type posts', () {
      final posts = [
        makePost('guide1', postType: CommunityPostType.guide, createdAt: now),
        makePost('general', postType: CommunityPostType.general,
            createdAt: now),
        makePost('guide2', postType: CommunityPostType.guide,
            createdAt: now.subtract(const Duration(hours: 1))),
      ];

      final container = createContainer(posts: posts);
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      final visible = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.guides),
      );

      expect(visible.length, 2);
      expect(visible.every((p) => p.postType == CommunityPostType.guide),
          isTrue);
    });
  });

  group('communityVisiblePostsProvider - questions tab', () {
    test('shows only question-type posts', () {
      final posts = [
        makePost('q1', postType: CommunityPostType.question, createdAt: now),
        makePost('general', postType: CommunityPostType.general,
            createdAt: now),
      ];

      final container = createContainer(posts: posts);
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      final visible = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.questions),
      );

      expect(visible.length, 1);
      expect(visible.first.id, 'q1');
    });
  });

  group('communityVisiblePostsProvider - blocked users', () {
    test('filters out posts from blocked users', () {
      final posts = [
        makePost('p1', userId: 'blocked-user', createdAt: now),
        makePost('p2', userId: 'normal-user', createdAt: now),
      ];

      final container = createContainer(
        posts: posts,
        blockedUserIds: ['blocked-user'],
      );
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      final visible = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.explore),
      );

      expect(visible.length, 1);
      expect(visible.first.id, 'p2');
    });

    test('returns all posts when no users are blocked', () {
      final posts = [
        makePost('p1', createdAt: now),
        makePost('p2',
            createdAt: now.subtract(const Duration(hours: 1))),
      ];

      final container = createContainer(posts: posts, blockedUserIds: []);
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      final visible = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.explore),
      );

      expect(visible.length, 2);
    });

    test('handles multiple blocked users', () {
      final posts = [
        makePost('p1', userId: 'bad1', createdAt: now),
        makePost('p2', userId: 'bad2', createdAt: now),
        makePost('p3', userId: 'good', createdAt: now),
      ];

      final container = createContainer(
        posts: posts,
        blockedUserIds: ['bad1', 'bad2'],
      );
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      final visible = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.explore),
      );

      expect(visible.length, 1);
      expect(visible.first.userId, 'good');
    });
  });

  group('communityVisiblePostsProvider - empty states', () {
    test('returns empty list when feed has no posts', () {
      final container = createContainer(posts: []);
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      final visible = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.explore),
      );

      expect(visible, isEmpty);
    });

    test('returns empty list when all posts are from blocked users', () {
      final posts = [
        makePost('p1', userId: 'blocked', createdAt: now),
      ];

      final container = createContainer(
        posts: posts,
        blockedUserIds: ['blocked'],
      );
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      final visible = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.explore),
      );

      expect(visible, isEmpty);
    });
  });

  group('communityVisiblePostsProvider - null createdAt handling', () {
    test('posts with null createdAt use fallback date for sorting', () {
      final posts = [
        const CommunityPost(
          id: 'no-date',
          userId: 'u1',
          username: 'user',
          // createdAt is null
        ),
        CommunityPost(
          id: 'has-date',
          userId: 'u1',
          username: 'user',
          createdAt: now,
        ),
      ];

      final container = createContainer(posts: posts);
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      final visible = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.explore),
      );

      // Both posts should be present; null createdAt falls back to DateTime(2000)
      expect(visible, hasLength(2));
      // The post with `now` should come first (newest), null-date uses fallback year 2000
      expect(visible.first.id, 'has-date');
    });
  });
}

class _FakeBlockedUsersNotifier extends BlockedUsersNotifier {
  final List<String> _initial;

  _FakeBlockedUsersNotifier(this._initial);

  @override
  List<String> build() => _initial;
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
