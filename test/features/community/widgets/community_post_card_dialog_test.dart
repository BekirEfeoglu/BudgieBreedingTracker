@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/community_social_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_post_card.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/action_feedback_providers.dart';

import '../../../helpers/mocks.dart';

class MockCommunitySocialRepository extends Mock
    implements CommunitySocialRepository {}

CommunityPost _testPost({
  String id = 'post-1',
  String userId = 'user-1',
  String username = 'TestUser',
  String content = 'Hello world',
  String? title,
  CommunityPostType postType = CommunityPostType.general,
  int likeCount = 0,
  int commentCount = 0,
  List<String> tags = const [],
}) {
  return CommunityPost(
    id: id,
    userId: userId,
    username: username,
    content: content,
    title: title,
    postType: postType,
    likeCount: likeCount,
    commentCount: commentCount,
    tags: tags,
    createdAt: DateTime(2026, 1, 15),
  );
}

void main() {
  late MockCommunityPostRepository mockPostRepo;
  late MockCommunitySocialRepository mockSocialRepo;

  setUp(() {
    mockPostRepo = MockCommunityPostRepository();
    mockSocialRepo = MockCommunitySocialRepository();

    registerFallbackValue(CommunityReportReason.spam);
  });

  GoRouter buildRouter(Widget child) {
    return GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(path: '/test', builder: (_, __) => child),
        GoRoute(
          path: '/community/post/:postId',
          builder: (_, __) => const Scaffold(body: Text('post_detail')),
        ),
        GoRoute(
          path: '/community/user/:userId',
          builder: (_, __) => const Scaffold(body: Text('user_posts')),
        ),
        GoRoute(
          path: '/birds/:id',
          builder: (_, __) => const Scaffold(body: Text('bird_detail')),
        ),
      ],
    );
  }

  Widget createSubject(
    CommunityPost post, {
    String currentUserId = 'other-user',
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(currentUserId),
        communityPostRepositoryProvider.overrideWithValue(mockPostRepo),
        communitySocialRepositoryProvider.overrideWithValue(mockSocialRepo),
        communityFeedProvider.overrideWith(() => _FakeFeedNotifier()),
      ],
      child: MaterialApp.router(
        routerConfig: buildRouter(
          Scaffold(
            body: ListView(children: [CommunityPostCard(post: post)]),
          ),
        ),
      ),
    );
  }

  group('CommunityPostCard', () {
    testWidgets('renders username and content', (tester) async {
      await tester.pumpWidget(
        createSubject(_testPost(username: 'Alice', content: 'My budgie')),
      );
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('My budgie'), findsOneWidget);
    });

    testWidgets('renders title when present', (tester) async {
      await tester.pumpWidget(
        createSubject(
          _testPost(title: 'Big News', postType: CommunityPostType.guide),
        ),
      );
      await tester.pump();

      expect(find.text('Big News'), findsOneWidget);
    });

    testWidgets('renders tags', (tester) async {
      await tester.pumpWidget(
        createSubject(_testPost(tags: ['budgie', 'breeding'])),
      );
      await tester.pump();

      expect(find.text('#budgie'), findsOneWidget);
      expect(find.text('#breeding'), findsOneWidget);
    });

    testWidgets('shows engagement summary when likes > 0', (tester) async {
      await tester.pumpWidget(
        createSubject(_testPost(likeCount: 5, commentCount: 3)),
      );
      await tester.pump();

      expect(find.text('5'), findsAtLeastNWidgets(1));
      expect(find.text('3'), findsAtLeastNWidgets(1));
    });

    testWidgets('hides engagement summary when no engagement', (tester) async {
      await tester.pumpWidget(
        createSubject(_testPost(likeCount: 0, commentCount: 0)),
      );
      await tester.pump();

      // EngagementSummary should not render any metric badges
      expect(find.text(l10n('community.like')), findsNothing);
    });

    testWidgets('shows delete option in popup for own post', (tester) async {
      await tester.pumpWidget(
        createSubject(_testPost(userId: 'me'), currentUserId: 'me'),
      );
      await tester.pump();

      // Tap popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.delete_post')), findsOneWidget);
    });

    testWidgets('shows report option for other user post', (tester) async {
      await tester.pumpWidget(
        createSubject(_testPost(userId: 'someone'), currentUserId: 'me'),
      );
      await tester.pump();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.report_post')), findsOneWidget);
    });

    testWidgets('delete dialog appears and cancel dismisses', (tester) async {
      await tester.pumpWidget(
        createSubject(_testPost(userId: 'me'), currentUserId: 'me'),
      );
      await tester.pump();

      // Open popup and tap delete
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n('community.delete_post')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(l10n('community.confirm_delete_post')), findsOneWidget);

      // Cancel
      await tester.tap(find.widgetWithText(TextButton, l10n('common.cancel')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('delete dialog confirm calls deletePost', (tester) async {
      when(
        () => mockPostRepo.delete(
          postId: any(named: 'postId'),
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        createSubject(
          _testPost(id: 'p-del', userId: 'me'),
          currentUserId: 'me',
        ),
      );
      await tester.pump();

      // Open popup -> delete -> confirm
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n('community.delete_post')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, l10n('common.delete')));
      await tester.pumpAndSettle();

      verify(
        () => mockPostRepo.delete(postId: 'p-del', userId: 'me'),
      ).called(1);
    });

    testWidgets('report dialog shows reason options', (tester) async {
      await tester.pumpWidget(
        createSubject(_testPost(userId: 'someone'), currentUserId: 'me'),
      );
      await tester.pump();

      // Open popup -> report
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n('community.report_post')));
      await tester.pumpAndSettle();

      expect(find.byType(SimpleDialog), findsOneWidget);
      expect(find.text(l10n('community.report_reason_spam')), findsOneWidget);
      expect(find.text(l10n('community.report_reason_harassment')), findsOneWidget);
    });

    testWidgets('report submits and shows snackbar on success', (tester) async {
      ActionFeedbackService.resetForTesting();
      final received = <ActionFeedback>[];
      final sub = ActionFeedbackService.stream.listen(received.add);
      addTearDown(sub.cancel);

      when(
        () => mockSocialRepo.reportContent(
          userId: any(named: 'userId'),
          targetId: any(named: 'targetId'),
          targetType: any(named: 'targetType'),
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        createSubject(
          _testPost(id: 'p-rep', userId: 'someone'),
          currentUserId: 'me',
        ),
      );
      await tester.pump();

      // Open popup -> report -> select reason
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n('community.report_post')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n('community.report_reason_spam')));
      await tester.pump();
      await tester.pump();

      // Success goes through ActionFeedbackService
      expect(received, hasLength(1));
      expect(received.first.message, 'community.report_submitted');

      verify(
        () => mockSocialRepo.reportContent(
          userId: 'me',
          targetId: 'p-rep',
          targetType: 'post',
          reason: CommunityReportReason.spam,
        ),
      ).called(1);
    });
  });
}

class _FakeFeedNotifier extends CommunityFeedNotifier {
  @override
  FeedState build() => const FeedState(isLoading: false);

  @override
  Future<void> fetchInitial() async {}

  @override
  Future<void> fetchMore() async {}
}
