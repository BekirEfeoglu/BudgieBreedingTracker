@Tags(['community'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_providers.dart';

import '../../../helpers/mocks.dart';

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
    CommunityPost makePost(
      String id, {
      bool liked = false,
      bool bookmarked = false,
    }) {
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
          communityFeedProvider.overrideWith(
            () => _TestFeedNotifier([makePost('1'), makePost('2')]),
          ),
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
          communityFeedProvider.overrideWith(
            () => _TestFeedNotifier([makePost('1')]),
          ),
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
          communityFeedProvider.overrideWith(
            () => _TestFeedNotifier([makePost('1'), makePost('2')]),
          ),
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
          communityFeedProvider.overrideWith(
            () => _TestFeedNotifier([
              makePost('1'),
              makePost('2'),
              makePost('3'),
            ]),
          ),
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

  group('CommunityFeedNotifier fetch flows', () {
    CommunityPost makePost(String id, {DateTime? createdAt}) {
      return CommunityPost(
        id: id,
        userId: 'u1',
        username: 'user',
        content: 'Post $id',
        createdAt: createdAt ?? DateTime(2024, 1, 1),
      );
    }

    Future<void> flushAsync() async {
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
    }

    test('fetchInitial populates posts, cursor and hasMore', () async {
      final repo = MockCommunityPostRepository();
      final posts = List.generate(
        20,
        (i) => makePost('p$i', createdAt: DateTime(2024, 1, 20 - i)),
      );
      when(
        () => repo.getFeed(currentUserId: 'user-1', limit: 20),
      ).thenAnswer((_) async => posts);

      final container = ProviderContainer(
        overrides: [
          communityPostRepositoryProvider.overrideWithValue(repo),
          currentUserIdProvider.overrideWithValue('user-1'),
        ],
      );
      addTearDown(container.dispose);

      container.listen(communityFeedProvider, (_, __) {});
      await flushAsync();

      final state = container.read(communityFeedProvider);
      expect(state.isLoading, isFalse);
      expect(state.posts, hasLength(20));
      expect(state.hasMore, isTrue);
      expect(state.cursor, posts.last.createdAt);
      verify(() => repo.getFeed(currentUserId: 'user-1', limit: 20)).called(1);
    });

    test(
      'fetchMore appends posts and updates hasMore when page is short',
      () async {
        final repo = MockCommunityPostRepository();
        final firstPage = List.generate(
          20,
          (i) => makePost('p$i', createdAt: DateTime(2024, 1, 20 - i)),
        );
        final secondPage = [
          makePost('p20', createdAt: DateTime(2023, 12, 31)),
          makePost('p21', createdAt: DateTime(2023, 12, 30)),
        ];
        when(
          () => repo.getFeed(currentUserId: 'user-1', limit: 20),
        ).thenAnswer((_) async => firstPage);
        when(
          () => repo.getFeed(
            currentUserId: 'user-1',
            limit: 20,
            before: firstPage.last.createdAt,
          ),
        ).thenAnswer((_) async => secondPage);

        final container = ProviderContainer(
          overrides: [
            communityPostRepositoryProvider.overrideWithValue(repo),
            currentUserIdProvider.overrideWithValue('user-1'),
          ],
        );
        addTearDown(container.dispose);

        container.listen(communityFeedProvider, (_, __) {});
        await flushAsync();
        await container.read(communityFeedProvider.notifier).fetchMore();

        final state = container.read(communityFeedProvider);
        expect(state.posts, hasLength(22));
        expect(state.posts.last.id, 'p21');
        expect(state.hasMore, isFalse);
        expect(state.cursor, secondPage.last.createdAt);
        verify(
          () => repo.getFeed(
            currentUserId: 'user-1',
            limit: 20,
            before: firstPage.last.createdAt,
          ),
        ).called(1);
      },
    );

    test('fetchInitial handles supabase unavailable errors gracefully', () async {
      final repo = MockCommunityPostRepository();
      when(() => repo.getFeed(currentUserId: 'user-1', limit: 20)).thenThrow(
        StateError(
          'You must initialize the supabase instance before calling Supabase.instance',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          communityPostRepositoryProvider.overrideWithValue(repo),
          currentUserIdProvider.overrideWithValue('user-1'),
        ],
      );
      addTearDown(container.dispose);

      container.listen(communityFeedProvider, (_, __) {});
      await flushAsync();

      final state = container.read(communityFeedProvider);
      expect(state.posts, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.hasMore, isFalse);
      expect(state.error, isNull);
    });

    test('fetchMore stores generic errors and keeps existing posts', () async {
      final repo = MockCommunityPostRepository();
      final firstPage = List.generate(
        20,
        (i) => makePost('p$i', createdAt: DateTime(2024, 1, 20 - i)),
      );
      when(
        () => repo.getFeed(currentUserId: 'user-1', limit: 20),
      ).thenAnswer((_) async => firstPage);
      when(
        () => repo.getFeed(
          currentUserId: 'user-1',
          limit: 20,
          before: firstPage.last.createdAt,
        ),
      ).thenThrow(Exception('pagination failed'));

      final container = ProviderContainer(
        overrides: [
          communityPostRepositoryProvider.overrideWithValue(repo),
          currentUserIdProvider.overrideWithValue('user-1'),
        ],
      );
      addTearDown(container.dispose);

      container.listen(communityFeedProvider, (_, __) {});
      await flushAsync();
      await container.read(communityFeedProvider.notifier).fetchMore();

      final state = container.read(communityFeedProvider);
      expect(state.posts, hasLength(20));
      expect(state.isLoading, isFalse);
      expect(state.error, contains('pagination failed'));
      expect(state.hasMore, isTrue);
    });
  });
}

/// Test notifier that skips Supabase calls and just sets initial posts.
class _TestFeedNotifier extends CommunityFeedNotifier {
  final List<CommunityPost> _initialPosts;

  _TestFeedNotifier(this._initialPosts);

  @override
  FeedState build() =>
      FeedState(posts: _initialPosts, isLoading: false, hasMore: false);
}
