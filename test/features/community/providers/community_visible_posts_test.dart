import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_providers.dart';

void main() {
  final now = DateTime.now();

  final testPosts = [
    CommunityPost(
      id: 'p1',
      userId: 'u1',
      username: 'Ali',
      postType: CommunityPostType.general,
      likeCount: 20,
      commentCount: 5,
      isFollowingAuthor: true,
      createdAt: now.subtract(const Duration(hours: 1)),
    ),
    CommunityPost(
      id: 'p2',
      userId: 'u2',
      username: 'Veli',
      postType: CommunityPostType.guide,
      likeCount: 2,
      commentCount: 1,
      isFollowingAuthor: false,
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    CommunityPost(
      id: 'p3',
      userId: 'u1',
      username: 'Ali',
      postType: CommunityPostType.question,
      likeCount: 50,
      commentCount: 10,
      isFollowingAuthor: true,
      createdAt: now.subtract(const Duration(hours: 3)),
    ),
    CommunityPost(
      id: 'p4',
      userId: 'me',
      username: 'Ben',
      postType: CommunityPostType.general,
      likeCount: 1,
      commentCount: 0,
      isFollowingAuthor: false,
      createdAt: now,
    ),
  ];

  ProviderContainer createContainer({
    List<CommunityPost>? posts,
    String currentUserId = 'me',
  }) {
    return ProviderContainer(overrides: [
      communityFeedProvider.overrideWith(
          () => _FakeFeedNotifier(posts: posts ?? testPosts)),
      currentUserIdProvider.overrideWithValue(currentUserId),
    ]);
  }

  group('communityVisiblePostsProvider', () {
    group('explore tab', () {
      test('returns all posts', () {
        final container = createContainer();
        addTearDown(container.dispose);
        container.read(communityFeedProvider);

        final visible = container.read(
          communityVisiblePostsProvider(CommunityFeedTab.explore),
        );
        expect(visible.length, testPosts.length);
      });

      test('sorts by newest by default', () {
        final container = createContainer();
        addTearDown(container.dispose);
        container.read(communityFeedProvider);

        final visible = container.read(
          communityVisiblePostsProvider(CommunityFeedTab.explore),
        );
        // p4 is newest (now), then p1, p2, p3
        expect(visible.first.id, 'p4');
        expect(visible.last.id, 'p3');
      });

      test('sorts by trending when selected', () {
        final container = createContainer();
        addTearDown(container.dispose);
        container.read(communityFeedProvider);

        // Set sort to trending
        container.read(exploreSortProvider.notifier).state =
            CommunityExploreSort.trending;

        final visible = container.read(
          communityVisiblePostsProvider(CommunityFeedTab.explore),
        );
        // p3 has highest engagement: 50*2 + 10 = 110
        // p1: 20*2 + 5 = 45
        // p2: 2*2 + 1 = 5
        // p4: 1*2 + 0 = 2
        expect(visible.first.id, 'p3');
        expect(visible[1].id, 'p1');
      });
    });

    group('following tab', () {
      test('only shows posts from followed users (excludes own)', () {
        final container = createContainer();
        addTearDown(container.dispose);
        container.read(communityFeedProvider);

        final visible = container.read(
          communityVisiblePostsProvider(CommunityFeedTab.following),
        );
        // p1 and p3 are from u1 (isFollowingAuthor=true, not own)
        // p4 is own (userId='me'), excluded
        expect(visible.length, 2);
        expect(visible.every((p) => p.isFollowingAuthor), isTrue);
        expect(visible.every((p) => p.userId != 'me'), isTrue);
      });

      test('always sorts by newest regardless of explore sort', () {
        final container = createContainer();
        addTearDown(container.dispose);
        container.read(communityFeedProvider);
        container.read(exploreSortProvider.notifier).state =
            CommunityExploreSort.trending;

        final visible = container.read(
          communityVisiblePostsProvider(CommunityFeedTab.following),
        );
        // Should be newest first: p1 then p3
        expect(visible.first.id, 'p1');
        expect(visible.last.id, 'p3');
      });
    });

    group('guides tab', () {
      test('only shows guide posts', () {
        final container = createContainer();
        addTearDown(container.dispose);
        container.read(communityFeedProvider);

        final visible = container.read(
          communityVisiblePostsProvider(CommunityFeedTab.guides),
        );
        expect(visible.length, 1);
        expect(visible.first.postType, CommunityPostType.guide);
        expect(visible.first.id, 'p2');
      });
    });

    group('questions tab', () {
      test('only shows question posts', () {
        final container = createContainer();
        addTearDown(container.dispose);
        container.read(communityFeedProvider);

        final visible = container.read(
          communityVisiblePostsProvider(CommunityFeedTab.questions),
        );
        expect(visible.length, 1);
        expect(visible.first.postType, CommunityPostType.question);
        expect(visible.first.id, 'p3');
      });
    });

    test('returns empty list when no posts match tab', () {
      final container = createContainer(posts: [
        CommunityPost(
          id: 'p1',
          userId: 'u1',
          username: 'Ali',
          postType: CommunityPostType.general,
          createdAt: now,
        ),
      ]);
      addTearDown(container.dispose);
      container.read(communityFeedProvider);

      final visible = container.read(
        communityVisiblePostsProvider(CommunityFeedTab.guides),
      );
      expect(visible, isEmpty);
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
