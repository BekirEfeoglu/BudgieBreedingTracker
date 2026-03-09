import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_search_providers.dart';

void main() {
  group('CommunitySearchState', () {
    test('initial state has empty query', () {
      const state = CommunitySearchState();
      expect(state.query, '');
      expect(state.hasQuery, isFalse);
    });

    test('hasQuery returns true for non-empty query', () {
      const state = CommunitySearchState(query: 'budgie');
      expect(state.hasQuery, isTrue);
    });

    test('hasQuery returns false for whitespace-only query', () {
      const state = CommunitySearchState(query: '   ');
      expect(state.hasQuery, isFalse);
    });

    test('copyWith updates query', () {
      const state = CommunitySearchState(query: 'old');
      final updated = state.copyWith(query: 'new');
      expect(updated.query, 'new');
    });
  });

  group('CommunitySearchUserResult', () {
    test('copyWith updates fields', () {
      const user = CommunitySearchUserResult(
        userId: 'u1',
        username: 'Ali',
        avatarUrl: null,
        postCount: 3,
        totalLikes: 10,
      );

      final updated = user.copyWith(postCount: 5, totalLikes: 20);
      expect(updated.postCount, 5);
      expect(updated.totalLikes, 20);
      expect(updated.username, 'Ali');
    });
  });

  group('CommunitySearchNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(overrides: [
        communityFeedProvider.overrideWith(() => _FakeFeedNotifier()),
      ]);
    });

    tearDown(() => container.dispose());

    test('initial state is empty', () {
      final state = container.read(communitySearchProvider);
      expect(state.query, '');
    });

    test('setQuery updates state', () {
      container.read(communitySearchProvider.notifier).setQuery('budgie');
      final state = container.read(communitySearchProvider);
      expect(state.query, 'budgie');
    });

    test('clear resets state', () {
      container.read(communitySearchProvider.notifier).setQuery('budgie');
      container.read(communitySearchProvider.notifier).clear();
      final state = container.read(communitySearchProvider);
      expect(state.query, '');
    });
  });

  group('communitySearchUsersProvider', () {
    late ProviderContainer container;

    final testPosts = [
      const CommunityPost(
        id: 'p1',
        userId: 'u1',
        username: 'AliKus',
        likeCount: 10,
      ),
      const CommunityPost(
        id: 'p2',
        userId: 'u1',
        username: 'AliKus',
        likeCount: 5,
      ),
      const CommunityPost(
        id: 'p3',
        userId: 'u2',
        username: 'VeliBudgie',
        likeCount: 20,
      ),
    ];

    setUp(() {
      container = ProviderContainer(overrides: [
        communityFeedProvider
            .overrideWith(() => _FakeFeedNotifier(posts: testPosts)),
      ]);
    });

    tearDown(() => container.dispose());

    test('returns empty list when query is empty', () {
      final users = container.read(communitySearchUsersProvider);
      expect(users, isEmpty);
    });

    test('filters users by username', () {
      container.read(communitySearchProvider.notifier).setQuery('ali');
      final users = container.read(communitySearchUsersProvider);
      expect(users.length, 1);
      expect(users.first.username, 'AliKus');
    });

    test('aggregates user post count and likes', () {
      container.read(communitySearchProvider.notifier).setQuery('alik');
      final users = container.read(communitySearchUsersProvider);
      expect(users.first.postCount, 2);
      expect(users.first.totalLikes, 15);
    });
  });

  group('communitySearchTagsProvider', () {
    late ProviderContainer container;

    final taggedPosts = [
      const CommunityPost(
        id: 'p1',
        userId: 'u1',
        username: 'Ali',
        tags: ['budgerigar', 'breeding'],
        mutationTags: ['lutino'],
      ),
      const CommunityPost(
        id: 'p2',
        userId: 'u2',
        username: 'Veli',
        tags: ['budgerigar', 'health'],
      ),
    ];

    setUp(() {
      container = ProviderContainer(overrides: [
        communityFeedProvider
            .overrideWith(() => _FakeFeedNotifier(posts: taggedPosts)),
      ]);
    });

    tearDown(() => container.dispose());

    test('returns empty when no query', () {
      final tags = container.read(communitySearchTagsProvider);
      expect(tags, isEmpty);
    });

    test('filters tags by query', () {
      container.read(communitySearchProvider.notifier).setQuery('budge');
      final tags = container.read(communitySearchTagsProvider);
      expect(tags, contains('budgerigar'));
      expect(tags, isNot(contains('health')));
    });

    test('includes mutation tags', () {
      container.read(communitySearchProvider.notifier).setQuery('lut');
      final tags = container.read(communitySearchTagsProvider);
      expect(tags, contains('lutino'));
    });
  });

  group('communityPopularTagsProvider', () {
    late ProviderContainer container;

    setUp(() {
      final posts = [
        const CommunityPost(
          id: 'p1',
          userId: 'u1',
          username: 'Ali',
          tags: ['budgie', 'breeding'],
          mutationTags: ['lutino'],
        ),
        const CommunityPost(
          id: 'p2',
          userId: 'u2',
          username: 'Veli',
          tags: ['budgie'],
          mutationTags: ['albino'],
        ),
      ];
      container = ProviderContainer(overrides: [
        communityFeedProvider
            .overrideWith(() => _FakeFeedNotifier(posts: posts)),
      ]);
    });

    tearDown(() => container.dispose());

    test('returns popular tags sorted by frequency', () {
      final tags = container.read(communityPopularTagsProvider);
      expect(tags.first, 'budgie'); // appears 2 times
    });

    test('limits to 12 tags', () {
      final posts = List.generate(
        20,
        (i) => CommunityPost(
          id: 'p$i',
          userId: 'u$i',
          username: 'User$i',
          tags: ['tag$i'],
        ),
      );
      final c = ProviderContainer(overrides: [
        communityFeedProvider
            .overrideWith(() => _FakeFeedNotifier(posts: posts)),
      ]);
      addTearDown(c.dispose);

      final tags = c.read(communityPopularTagsProvider);
      expect(tags.length, 12);
    });
  });

  group('communitySuggestedUsersProvider', () {
    late ProviderContainer container;

    setUp(() {
      final posts = List.generate(
        20,
        (i) => CommunityPost(
          id: 'p$i',
          userId: 'u${i % 10}',
          username: 'User${i % 10}',
          likeCount: i,
        ),
      );
      container = ProviderContainer(overrides: [
        communityFeedProvider
            .overrideWith(() => _FakeFeedNotifier(posts: posts)),
      ]);
    });

    tearDown(() => container.dispose());

    test('returns max 8 users', () {
      final users = container.read(communitySuggestedUsersProvider);
      expect(users.length, 8);
    });

    test('sorts by post count then likes', () {
      final users = container.read(communitySuggestedUsersProvider);
      // All have 2 posts each; should sort by totalLikes descending
      for (var i = 0; i < users.length - 1; i++) {
        final current = users[i];
        final next = users[i + 1];
        if (current.postCount == next.postCount) {
          expect(current.totalLikes, greaterThanOrEqualTo(next.totalLikes));
        }
      }
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
