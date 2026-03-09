import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_providers.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_feed_list.dart';

void main() {
  Widget createSubject({
    required FeedState feedState,
    String currentUserId = 'me',
    CommunityFeedTab tab = CommunityFeedTab.explore,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(currentUserId),
        communityFeedProvider.overrideWith(() => _FakeFeedNotifier(feedState)),
      ],
      child: MaterialApp(
        home: Scaffold(body: CommunityFeedList(tab: tab)),
      ),
    );
  }

  group('CommunityFeedList', () {
    testWidgets('shows explore sort controls and featured creators', (
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

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('community.sort_newest'), findsOneWidget);
      expect(find.text('community.sort_trending'), findsOneWidget);
      expect(find.text('community.top_creators'), findsOneWidget);
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

      expect(find.text('Detailed guide'), findsOneWidget);
      expect(find.text('Need help'), findsNothing);
    });
  });
}

class _FakeFeedNotifier extends CommunityFeedNotifier {
  final FeedState _state;

  _FakeFeedNotifier(this._state);

  @override
  FeedState build() => _state;
}
