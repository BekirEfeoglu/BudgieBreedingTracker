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
    test('preserves the feed notifier order for newest (no re-sort)', () {
      // The notifier delivers posts newest-first (+ pinned-first); the visible
      // provider must preserve that order rather than re-sorting by createdAt
      // (re-sorting is wasted per-tap work and would drop the pinned-first
      // prefix). Input is newest-first here to mirror what the notifier emits.
      final posts = [
        makePost('p3', createdAt: now),
        makePost('p2', createdAt: now.subtract(const Duration(hours: 1))),
        makePost('p1', createdAt: now.subtract(const Duration(hours: 2))),
      ];

      final container = createContainer(posts: posts);
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      final visible = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.explore),
      );

      expect(visible.map((p) => p.id).toList(), ['p3', 'p2', 'p1']);
    });

    test('sorts by trending when explore sort is trending', () {
      final posts = [
        makePost(
          'low',
          likeCount: 1,
          commentCount: 0,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        makePost(
          'high',
          likeCount: 50,
          commentCount: 10,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
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
        makePost(
          'older',
          likeCount: 5,
          commentCount: 0,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        makePost(
          'newer',
          likeCount: 5,
          commentCount: 0,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
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
        makePost(
          'followed',
          userId: 'u1',
          isFollowingAuthor: true,
          createdAt: now,
        ),
        makePost(
          'not-followed',
          userId: 'u2',
          isFollowingAuthor: false,
          createdAt: now,
        ),
        makePost('own', userId: 'me', isFollowingAuthor: false, createdAt: now),
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

    test('ignores the explore trending setting (keeps newest order)', () {
      // Input is newest-first (p2 newer than p1) as the notifier delivers it.
      // p1 has far higher engagement, so if the trending comparator leaked into
      // the following tab it would jump to the front. It must not — following
      // uses the newest branch, which preserves the notifier's order.
      final posts = [
        makePost(
          'p2',
          userId: 'u1',
          isFollowingAuthor: true,
          likeCount: 1,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        makePost(
          'p1',
          userId: 'u1',
          isFollowingAuthor: true,
          likeCount: 100,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
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

      // Newest (p2) stays first; trending did not reorder p1 to the front.
      expect(visible.first.id, 'p2');
    });
  });

  group('communityVisiblePostsProvider - guides tab', () {
    test('shows only guide-type posts', () {
      final posts = [
        makePost('guide1', postType: CommunityPostType.guide, createdAt: now),
        makePost(
          'general',
          postType: CommunityPostType.general,
          createdAt: now,
        ),
        makePost(
          'guide2',
          postType: CommunityPostType.guide,
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
      ];

      final container = createContainer(posts: posts);
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      final visible = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.guides),
      );

      expect(visible.length, 2);
      expect(
        visible.every((p) => p.postType == CommunityPostType.guide),
        isTrue,
      );
    });
  });

  group('communityVisiblePostsProvider - questions tab', () {
    test('shows only question-type posts', () {
      final posts = [
        makePost('q1', postType: CommunityPostType.question, createdAt: now),
        makePost(
          'general',
          postType: CommunityPostType.general,
          createdAt: now,
        ),
      ];

      final container = createContainer(posts: posts);
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      final visible = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.marketplace),
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
        makePost('p2', createdAt: now.subtract(const Duration(hours: 1))),
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

    test('welcome empty state is shown only on explore', () {
      final container = createContainer(posts: []);
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      expect(
        container.read(
          communityShowWelcomeEmptyProvider(CommunityFeedTab.explore),
        ),
        isTrue,
      );
      expect(
        container.read(
          communityShowWelcomeEmptyProvider(CommunityFeedTab.following),
        ),
        isFalse,
      );
    });

    test('explore welcome empty state handles filtered-out visible posts', () {
      final container = createContainer(
        posts: [
          makePost(
            'guide-only',
            postType: CommunityPostType.guide,
            createdAt: now,
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      expect(
        container.read(
          communityShowWelcomeEmptyProvider(CommunityFeedTab.explore),
        ),
        isTrue,
      );
    });

    test('returns empty list when all posts are from blocked users', () {
      final posts = [makePost('p1', userId: 'blocked', createdAt: now)];

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

  group('communityVisiblePostsProvider - select optimization', () {
    test('does not recompute when only isLoading changes', () {
      final posts = [makePost('p1', createdAt: now)];

      final container = ProviderContainer(
        overrides: [
          communityFeedProvider.overrideWith(
            () => _StatefulFakeFeedNotifier(posts: posts),
          ),
          currentUserIdProvider.overrideWithValue('me'),
          blockedUsersProvider.overrideWith(
            () => _FakeBlockedUsersNotifier([]),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Initial read
      container.read(communityFeedProvider);
      final first = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.explore),
      );

      // Simulate loading state change (no post change)
      (container.read(communityFeedProvider.notifier)
              as _StatefulFakeFeedNotifier)
          .setLoading(true);
      final second = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.explore),
      );

      // Should be identical lists (select filters out isLoading changes)
      expect(first.length, second.length);
      expect(first.first.id, second.first.id);
    });
  });

  group('communityVisiblePostsProvider - null createdAt handling', () {
    test('posts with null createdAt are kept (order preserved)', () {
      // Input mirrors the notifier's newest-first delivery. The newest branch
      // preserves order, so a null createdAt no longer needs a sort fallback —
      // it just must not be dropped from the visible list.
      final posts = [
        CommunityPost(
          id: 'has-date',
          userId: 'u1',
          username: 'user',
          createdAt: now,
        ),
        const CommunityPost(
          id: 'no-date',
          userId: 'u1',
          username: 'user',
          // createdAt is null
        ),
      ];

      final container = createContainer(posts: posts);
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      final visible = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.explore),
      );

      expect(visible.map((p) => p.id).toList(), ['has-date', 'no-date']);
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

class _StatefulFakeFeedNotifier extends CommunityFeedNotifier {
  final List<CommunityPost> _posts;

  _StatefulFakeFeedNotifier({List<CommunityPost>? posts})
    : _posts = posts ?? const [];

  @override
  FeedState build() => FeedState(posts: _posts, isLoading: false);

  @override
  Future<void> fetchInitial() async {}

  @override
  Future<void> fetchMore() async {}

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}
