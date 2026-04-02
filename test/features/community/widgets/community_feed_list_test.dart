import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';
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
        allPosts
            .where((p) => p.postType == CommunityPostType.guide)
            .toList(),
      CommunityFeedTab.questions =>
        allPosts
            .where((p) => p.postType == CommunityPostType.question)
            .toList(),
    };
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(currentUserId),
        communityFeedProvider.overrideWith(() => _FakeFeedNotifier(feedState)),
        communityVisiblePostsProvider(tab).overrideWithValue(visiblePosts),
        userProfileProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: MaterialApp(
        home: Scaffold(body: CommunityFeedList(tab: tab)),
      ),
    );
  }

  group('CommunityFeedList', () {
    testWidgets('shows explore sort controls and story strip', (
      tester,
    ) async {
      final posts = [
        CommunityPost(
          id: '1',
          userId: 'u1',
          username: 'Alpha Loft',
          content: 'First post',
          likeCount: 8,
          commentCount: 3,
          createdAt: DateTime(2026, 3, 5, 10),
        ),
        CommunityPost(
          id: '2',
          userId: 'u2',
          username: 'Blue Sky',
          content: 'Photo post',
          imageUrl: 'https://example.com/photo.jpg',
          likeCount: 5,
          commentCount: 1,
          createdAt: DateTime(2026, 3, 5, 9),
        ),
      ];

      await tester.pumpWidget(
        createSubject(
          feedState: FeedState(posts: posts, isLoading: false, hasMore: false),
        ),
      );
      await tester.pumpAndSettle();

      // Quick composer hint visible
      expect(find.text(l10n('community.quick_hint')), findsOneWidget);
      // Story strip title visible
      expect(find.text(l10n('community.stories_title')), findsOneWidget);
      // Sort controls visible (no scroll needed — hero removed)
      expect(find.text(l10n('community.sort_newest')), findsOneWidget);
      expect(find.text(l10n('community.sort_trending')), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Post content visible after scroll
      expect(find.text('Alpha Loft'), findsWidgets);
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

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
      await tester.pumpAndSettle();

      expect(find.text('Guide title'), findsOneWidget);
      expect(find.text('Question title'), findsNothing);
    });
  });
}

class _FakeFeedNotifier extends CommunityFeedNotifier {
  final FeedState _state;

  _FakeFeedNotifier(this._state);

  @override
  FeedState build() => _state;
}
