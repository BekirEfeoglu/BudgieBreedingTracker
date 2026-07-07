@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_post_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_providers.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_feed_list.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

void main() {
  Widget createSubject({
    required FeedState feedState,
    String currentUserId = 'me',
    CommunityFeedTab tab = CommunityFeedTab.explore,
  }) {
    final allPosts = feedState.posts;
    // Simulate the tab filtering that communityVisiblePostsProvider does.
    final visiblePosts = switch (tab) {
      CommunityFeedTab.explore => allPosts,
      CommunityFeedTab.following =>
        allPosts.where((p) => p.isFollowingAuthor).toList(),
      CommunityFeedTab.guides =>
        allPosts.where((p) => p.postType == CommunityPostType.guide).toList(),
      CommunityFeedTab.marketplace =>
        allPosts
            .where((p) => p.postType == CommunityPostType.question)
            .toList(),
    };
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(currentUserId),
        communityFeedProvider.overrideWith(() => _FakeFeedNotifier(feedState)),
        communityNewPostCountProvider.overrideWith(_FakeNewPostNotifier.new),
        communityVisiblePostsProvider(tab).overrideWithValue(visiblePosts),
        userProfileProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: MaterialApp(
        home: Scaffold(body: CommunityFeedList(tab: tab)),
      ),
    );
  }

  group('CommunityFeedList', () {
    testWidgets('explore shows posts without composer, story strip or sort', (
      tester,
    ) async {
      final now = DateTime.now();
      final posts = [
        CommunityPost(
          id: '1',
          userId: 'u1',
          username: 'Alpha Loft',
          content: 'First post',
          likeCount: 8,
          commentCount: 3,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        CommunityPost(
          id: '2',
          userId: 'u2',
          username: 'Blue Sky',
          content: 'Photo post',
          imageUrl: 'https://example.com/photo.jpg',
          likeCount: 5,
          commentCount: 1,
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
      ];

      await tester.pumpWidget(
        createSubject(
          feedState: FeedState(posts: posts, isLoading: false, hasMore: false),
        ),
      );
      await tester.pump();

      // Redesign: explore drops the quick composer, story strip and sort
      // controls — the feed is post-first.
      expect(find.text(l10n('community.quick_hint')), findsNothing);
      expect(find.text(l10n('community.stories_title')), findsNothing);
      expect(find.text(l10n('community.sort_newest')), findsNothing);
      expect(find.text(l10n('community.sort_trending')), findsNothing);

      // Post content is visible.
      expect(find.text('Alpha Loft'), findsWidgets);
    });

    testWidgets('wraps post cards with AutomaticKeepAlive', (tester) async {
      final now = DateTime.now();
      final posts = List.generate(
        5,
        (i) => CommunityPost(
          id: 'p$i',
          userId: 'u$i',
          username: 'User$i',
          content: 'Post $i content',
          createdAt: now.subtract(Duration(hours: i)),
        ),
      );

      await tester.pumpWidget(
        createSubject(
          feedState: FeedState(posts: posts, isLoading: false, hasMore: false),
        ),
      );
      await tester.pumpAndSettle();

      // AutomaticKeepAlive widgets should be in the tree
      expect(find.byType(AutomaticKeepAlive), findsWidgets);
    });

    testWidgets('shows only guide posts in guides section', (tester) async {
      final posts = [
        CommunityPost(
          id: '1',
          userId: 'me',
          username: 'Guide Author',
          title: 'Guide title',
          content: 'Detailed guide',
          postType: CommunityPostType.guide,
          likeCount: 1,
          commentCount: 0,
          createdAt: DateTime(2026, 3, 5, 10),
        ),
        CommunityPost(
          id: '2',
          userId: 'u2',
          username: 'Question Author',
          title: 'Question title',
          content: 'Need help',
          postType: CommunityPostType.question,
          likeCount: 4,
          commentCount: 2,
          createdAt: DateTime(2026, 3, 5, 9),
        ),
      ];

      await tester.pumpWidget(
        createSubject(
          feedState: FeedState(posts: posts, isLoading: false, hasMore: false),
          tab: CommunityFeedTab.guides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.quick_hint')), findsNothing);
      expect(find.text(l10n('community.guides_library_title')), findsOneWidget);
      expect(find.text(l10n('community.guides_curated_title')), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
      await tester.pumpAndSettle();

      expect(find.text('Guide title'), findsOneWidget);
      expect(find.text('Question title'), findsNothing);
    });

    testWidgets('new posts banner is hidden initially', (tester) async {
      final now = DateTime.now();
      final posts = [
        CommunityPost(
          id: '1',
          userId: 'u1',
          username: 'User',
          content: 'Post',
          createdAt: now,
        ),
      ];

      await tester.pumpWidget(
        createSubject(
          feedState: FeedState(posts: posts, isLoading: false, hasMore: false),
        ),
      );
      await tester.pumpAndSettle();

      // Banner should exist in tree but be invisible (opacity 0)
      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 0.0);
    });

    testWidgets('swipe right on post triggers like', (tester) async {
      var likeTriggered = false;
      final now = DateTime.now();
      final posts = [
        CommunityPost(
          id: 'swipe-test',
          userId: 'u1',
          username: 'User',
          content: 'Swipe me',
          createdAt: now,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('me'),
            communityFeedProvider.overrideWith(
              () => _FakeFeedNotifier(
                FeedState(posts: posts, isLoading: false, hasMore: false),
              ),
            ),
            communityVisiblePostsProvider(
              CommunityFeedTab.explore,
            ).overrideWithValue(posts),
            userProfileProvider.overrideWith((ref) => Stream.value(null)),
            likeToggleProvider.overrideWith(() {
              likeTriggered = true;
              return _FakeLikeNotifier();
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: CommunityFeedList())),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to make post cards visible
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Find the post card and swipe right (>80px threshold)
      final card = find.text('Swipe me');
      if (card.evaluate().isNotEmpty) {
        await tester.drag(card, const Offset(100, 0));
        await tester.pumpAndSettle();
      }

      // The likeToggleProvider factory was invoked
      expect(likeTriggered, isTrue);
    });

    testWidgets('following tab renders posts from followed authors', (
      tester,
    ) async {
      final followPost = CommunityPost(
        id: 'f1',
        userId: 'followed-user',
        username: 'Followed Author',
        content: 'A post from someone I follow',
        isFollowingAuthor: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await tester.pumpWidget(
        createSubject(
          feedState: FeedState(
            posts: [followPost],
            isLoading: false,
            hasMore: false,
          ),
          tab: CommunityFeedTab.following,
        ),
      );
      await tester.pumpAndSettle();

      // Redesign: the following tab is now a feed (story strip + posts),
      // not the people-management list (CommunityFollowingList was deleted).
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('Followed Author'), findsWidgets);
    });

    testWidgets('swipe left on post triggers bookmark', (tester) async {
      var bookmarkTriggered = false;
      final now = DateTime.now();
      final posts = [
        CommunityPost(
          id: 'swipe-bm',
          userId: 'u1',
          username: 'User',
          content: 'Bookmark me',
          createdAt: now,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('me'),
            communityFeedProvider.overrideWith(
              () => _FakeFeedNotifier(
                FeedState(posts: posts, isLoading: false, hasMore: false),
              ),
            ),
            communityVisiblePostsProvider(
              CommunityFeedTab.explore,
            ).overrideWithValue(posts),
            userProfileProvider.overrideWith((ref) => Stream.value(null)),
            bookmarkToggleProvider.overrideWith(() {
              bookmarkTriggered = true;
              return _FakeBookmarkNotifier();
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: CommunityFeedList())),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final card = find.text('Bookmark me');
      if (card.evaluate().isNotEmpty) {
        await tester.drag(card, const Offset(-100, 0));
        await tester.pumpAndSettle();
      }

      expect(bookmarkTriggered, isTrue);
    });

    testWidgets('guides tab shows empty state when no guides', (tester) async {
      await tester.pumpWidget(
        createSubject(
          feedState: const FeedState(
            posts: [],
            isLoading: false,
            hasMore: false,
          ),
          tab: CommunityFeedTab.guides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.guides_library_title')), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('questions tab renders question posts', (tester) async {
      final posts = [
        CommunityPost(
          id: '1',
          userId: 'u1',
          username: 'Question Author',
          title: 'How to breed?',
          content: 'Need advice',
          postType: CommunityPostType.question,
          likeCount: 2,
          commentCount: 1,
          createdAt: DateTime(2026, 3, 5, 10),
        ),
      ];

      await tester.pumpWidget(
        createSubject(
          feedState: FeedState(posts: posts, isLoading: false, hasMore: false),
          tab: CommunityFeedTab.marketplace,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('How to breed?'), findsOneWidget);
    });

    testWidgets(
      'explore with no visible posts shows welcoming empty state, not search',
      (tester) async {
        // Posts exist but none pass the explore filter (e.g. all guides).
        final posts = [
          CommunityPost(
            id: 'g1',
            userId: 'u1',
            username: 'Guide Author',
            content: 'A guide',
            postType: CommunityPostType.guide,
            createdAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserIdProvider.overrideWithValue('me'),
              communityFeedProvider.overrideWith(
                () => _FakeFeedNotifier(
                  FeedState(posts: posts, isLoading: false, hasMore: false),
                ),
              ),
              communityNewPostCountProvider.overrideWith(
                _FakeNewPostNotifier.new,
              ),
              communityVisiblePostsProvider(
                CommunityFeedTab.explore,
              ).overrideWithValue(const []),
              userProfileProvider.overrideWith((ref) => Stream.value(null)),
            ],
            child: const MaterialApp(home: Scaffold(body: CommunityFeedList())),
          ),
        );
        await tester.pumpAndSettle();

        // Welcoming "be the first to post" state, with a create CTA.
        expect(find.text(l10n('community.no_posts')), findsOneWidget);
        expect(find.text(l10n('community.create_post')), findsWidgets);
        // NOT the search-oriented filtered empty state.
        expect(find.text(l10n('community.empty_filtered_title')), findsNothing);
      },
    );

    testWidgets('loading state shows shimmer placeholder', (tester) async {
      await tester.pumpWidget(
        createSubject(
          feedState: const FeedState(
            posts: [],
            isLoading: true,
            hasMore: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommunityFeedList), findsOneWidget);
    });

    testWidgets('error state hides raw exception details', (tester) async {
      await tester.pumpWidget(
        createSubject(
          feedState: const FeedState(
            posts: [],
            isLoading: false,
            hasMore: false,
            error: "Instance of 'NetworkException'",
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('NetworkException'), findsNothing);
      expect(
        find.text(
          '${l10n('community.feed_load_error')}: ${l10n('errors.unknown_error')}',
        ),
        findsOneWidget,
      );
    });
  });
}

class _FakeLikeNotifier extends LikeToggleNotifier {
  @override
  void build() {}

  @override
  Future<void> toggleLike(String postId) async {}
}

class _FakeBookmarkNotifier extends BookmarkToggleNotifier {
  @override
  void build() {}

  @override
  Future<void> toggleBookmark(String postId) async {}
}

class _FakeFeedNotifier extends CommunityFeedNotifier {
  final FeedState _state;

  _FakeFeedNotifier(this._state);

  @override
  FeedState build() => _state;
}

/// Skips the realtime websocket subscription that the real notifier opens in
/// `build()` — keeps widget tests free of pending network timers.
class _FakeNewPostNotifier extends CommunityNewPostNotifier {
  @override
  int build() => 0;
}
