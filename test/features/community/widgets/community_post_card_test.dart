@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_post_card.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_post_card_parts.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_user_header.dart';

import '../../../helpers/mocks.dart';

CommunityPost _testPost({
  String id = 'post-1',
  String userId = 'user-1',
  String username = 'TestUser',
  String? avatarUrl,
  String? title,
  String content = 'Test content',
  String? imageUrl,
  CommunityPostType postType = CommunityPostType.general,
  int likeCount = 5,
  int commentCount = 2,
  DateTime? createdAt,
  DateTime? editedAt,
}) {
  return CommunityPost(
    id: id,
    userId: userId,
    username: username,
    avatarUrl: avatarUrl,
    title: title,
    content: content,
    imageUrl: imageUrl,
    postType: postType,
    likeCount: likeCount,
    commentCount: commentCount,
    createdAt: createdAt ?? DateTime.now().subtract(const Duration(hours: 2)),
    editedAt: editedAt,
  );
}

class _FakeFeedNotifier extends CommunityFeedNotifier {
  @override
  FeedState build() => const FeedState(isLoading: false);

  @override
  Future<void> fetchInitial() async {}

  @override
  Future<void> fetchMore() async {}
}

void main() {
  Widget createSubject(
    CommunityPost post, {
    String currentUserId = 'other-user',
    bool isInteractive = true,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(currentUserId),
        communityFeedProvider.overrideWith(() => _FakeFeedNotifier()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CommunityPostCard(post: post, isInteractive: isInteractive),
          ),
        ),
      ),
    );
  }

  group('CommunityPostCard', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(createSubject(_testPost()));
      await tester.pump();

      expect(find.byType(CommunityPostCard), findsOneWidget);
    });

    testWidgets('shows Card widget', (tester) async {
      await tester.pumpWidget(createSubject(_testPost()));
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows post content', (tester) async {
      await tester.pumpWidget(
        createSubject(_testPost(content: 'Hello World!')),
      );
      await tester.pump();

      expect(find.text('Hello World!'), findsOneWidget);
    });

    testWidgets('shows post title when provided', (tester) async {
      await tester.pumpWidget(
        createSubject(_testPost(title: 'My First Budgie')),
      );
      await tester.pump();

      expect(find.text('My First Budgie'), findsOneWidget);
    });

    testWidgets('does not show title section when title is null and type '
        'is general', (tester) async {
      await tester.pumpWidget(createSubject(_testPost(title: null)));
      await tester.pump();

      // Only content is shown, no title text
      expect(find.text('Test content'), findsOneWidget);
    });

    testWidgets('shows author username via CommunityUserHeader', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(_testPost(username: 'JohnDoe')));
      await tester.pump();

      expect(find.byType(CommunityUserHeader), findsOneWidget);
      expect(find.text('JohnDoe'), findsOneWidget);
    });

    testWidgets('shows avatar initial when no avatarUrl', (tester) async {
      await tester.pumpWidget(createSubject(_testPost(username: 'Alice')));
      await tester.pump();

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('shows question mark when username is empty', (tester) async {
      await tester.pumpWidget(createSubject(_testPost(username: '')));
      await tester.pump();

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('shows like count in engagement summary', (tester) async {
      await tester.pumpWidget(createSubject(_testPost(likeCount: 42)));
      await tester.pump();

      expect(find.text('42'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows comment count in engagement summary', (tester) async {
      await tester.pumpWidget(createSubject(_testPost(commentCount: 7)));
      await tester.pump();

      expect(find.text('7'), findsAtLeastNWidgets(1));
    });

    testWidgets('hides engagement summary when both counts are zero', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(_testPost(likeCount: 0, commentCount: 0)),
      );
      await tester.pump();

      expect(find.byType(EngagementSummary), findsNothing);
    });

    testWidgets('shows engagement summary when likeCount > 0', (tester) async {
      await tester.pumpWidget(
        createSubject(_testPost(likeCount: 3, commentCount: 0)),
      );
      await tester.pump();

      expect(find.byType(EngagementSummary), findsOneWidget);
    });

    testWidgets('shows post type badge for non-general types', (tester) async {
      await tester.pumpWidget(
        createSubject(_testPost(postType: CommunityPostType.question)),
      );
      await tester.pump();

      expect(find.byType(PostTypeBadge), findsOneWidget);
    });

    testWidgets('hides post type badge for general type without title', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(
          _testPost(postType: CommunityPostType.general, title: null),
        ),
      );
      await tester.pump();

      expect(find.byType(PostTypeBadge), findsNothing);
    });

    testWidgets('renders guide lead treatment for guide posts', (tester) async {
      await tester.pumpWidget(
        createSubject(
          _testPost(
            title: 'Guide title',
            content: 'Detailed guide content for budgie feeding and care.',
            postType: CommunityPostType.guide,
          ),
        ),
      );
      await tester.pump();

      expect(find.text(l10n('community.guide_badge')), findsWidgets);
      expect(find.text(l10n('community.guide_open_hint')), findsOneWidget);
    });

    testWidgets('shows relative timestamp', (tester) async {
      await tester.pumpWidget(createSubject(_testPost()));
      await tester.pump();

      // 2 hours ago produces a relative time string containing "2"
      expect(find.textContaining('2'), findsWidgets);
    });

    testWidgets('shows InkWell for tap interaction', (tester) async {
      await tester.pumpWidget(createSubject(_testPost()));
      await tester.pump();

      expect(find.byKey(CommunityPostCard.interactionKey), findsOneWidget);
    });

    testWidgets('omits InkWell when interaction is disabled', (tester) async {
      await tester.pumpWidget(createSubject(_testPost(), isInteractive: false));
      await tester.pump();

      expect(find.byKey(CommunityPostCard.interactionKey), findsNothing);
    });

    testWidgets('does not show content section when content is empty', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(_testPost(content: '')));
      await tester.pump();

      expect(find.byType(ContentText), findsNothing);
    });

    testWidgets('shows ContentText when content is not empty', (tester) async {
      await tester.pumpWidget(
        createSubject(_testPost(content: 'Some text here')),
      );
      await tester.pump();

      expect(find.byType(ContentText), findsOneWidget);
      expect(find.text('Some text here'), findsOneWidget);
    });

    testWidgets('shows my_post badge when post belongs to current user', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(_testPost(userId: 'my-user'), currentUserId: 'my-user'),
      );
      await tester.pump();

      // CommunityUserHeader shows "my_post" badge for own posts
      expect(find.text(l10n('community.my_post')), findsOneWidget);
    });

    testWidgets('does not show my_post badge for other users posts', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(_testPost(userId: 'user-1'), currentUserId: 'other-user'),
      );
      await tester.pump();

      expect(find.text(l10n('community.my_post')), findsNothing);
    });

    testWidgets('own fresh post shows edit menu item', (tester) async {
      final post = _testPost(
        userId: 'me',
        createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );
      await tester.pumpWidget(createSubject(post, currentUserId: 'me'));
      await tester.pump();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.edit_post')), findsOneWidget);
    });

    testWidgets('own stale post hides edit menu item', (tester) async {
      final post = _testPost(
        userId: 'me',
        createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 6)),
      );
      await tester.pumpWidget(createSubject(post, currentUserId: 'me'));
      await tester.pump();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.edit_post')), findsNothing);
    });

    testWidgets('edited post shows edited badge', (tester) async {
      final post = _testPost(editedAt: DateTime.utc(2026, 7, 3));
      await tester.pumpWidget(createSubject(post));
      await tester.pump();

      expect(
        find.textContaining(l10n('community.edited_badge')),
        findsOneWidget,
      );
    });

    testWidgets('tapping Edit in the popup menu opens the edit sheet', (
      tester,
    ) async {
      // Self-contained: builds its own ProviderScope (with a
      // communityPostRepositoryProvider mock override) instead of reusing
      // createSubject, since none of the other 25 tests in this file need
      // a repository override.
      final mockRepo = MockCommunityPostRepository();
      when(
        () => mockRepo.update(
          postId: any(named: 'postId'),
          content: any(named: 'content'),
        ),
      ).thenAnswer((_) async {});

      final post = _testPost(
        userId: 'me',
        createdAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('me'),
            communityPostRepositoryProvider.overrideWithValue(mockRepo),
            communityFeedProvider.overrideWith(() => _FakeFeedNotifier()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: CommunityPostCard(post: post)),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('community.edit_post')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text(l10n('community.edit_post_title')), findsOneWidget);
    });
  });
}
