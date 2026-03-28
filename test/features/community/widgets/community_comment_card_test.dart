import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/data/models/community_comment_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/community_comment_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/community_social_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_comment_tile.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/action_feedback_providers.dart';

class MockCommunityCommentRepository extends Mock
    implements CommunityCommentRepository {}

class MockCommunitySocialRepository extends Mock
    implements CommunitySocialRepository {}

class _FakeFeedNotifier extends CommunityFeedNotifier {
  @override
  FeedState build() => const FeedState(isLoading: false);

  @override
  Future<void> fetchInitial() async {}

  @override
  Future<void> fetchMore() async {}
}

CommunityComment _testComment({
  String id = 'comment-1',
  String postId = 'post-1',
  String userId = 'user-1',
  String username = 'TestUser',
  String? avatarUrl,
  String content = 'Test comment content',
  int likeCount = 0,
  bool isLikedByMe = false,
  DateTime? createdAt,
}) {
  return CommunityComment(
    id: id,
    postId: postId,
    userId: userId,
    username: username,
    avatarUrl: avatarUrl,
    content: content,
    likeCount: likeCount,
    isLikedByMe: isLikedByMe,
    createdAt: createdAt ?? DateTime.now().subtract(const Duration(minutes: 5)),
  );
}

void main() {
  late MockCommunityCommentRepository mockCommentRepo;
  late MockCommunitySocialRepository mockSocialRepo;

  setUp(() {
    mockCommentRepo = MockCommunityCommentRepository();
    mockSocialRepo = MockCommunitySocialRepository();

    registerFallbackValue(CommunityReportReason.spam);
  });

  Widget createSubject(
    CommunityComment comment, {
    String currentUserId = 'other-user',
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(currentUserId),
        communityCommentRepositoryProvider.overrideWithValue(mockCommentRepo),
        communitySocialRepositoryProvider.overrideWithValue(mockSocialRepo),
        communityFeedProvider.overrideWith(() => _FakeFeedNotifier()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ListView(children: [CommunityCommentTile(comment: comment)]),
        ),
      ),
    );
  }

  group('CommunityCommentTile — rendering', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(createSubject(_testComment()));
      await tester.pump();

      expect(find.byType(CommunityCommentTile), findsOneWidget);
    });

    testWidgets('shows comment content', (tester) async {
      await tester.pumpWidget(
        createSubject(_testComment(content: 'Great budgie!')),
      );
      await tester.pump();

      expect(find.text('Great budgie!'), findsOneWidget);
    });

    testWidgets('shows author username', (tester) async {
      await tester.pumpWidget(
        createSubject(_testComment(username: 'BirdLover')),
      );
      await tester.pump();

      expect(find.text('BirdLover'), findsOneWidget);
    });

    testWidgets('shows CircleAvatar with initial when no avatarUrl', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(_testComment(username: 'Charlie', avatarUrl: null)),
      );
      await tester.pump();

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('shows question mark when username is empty', (tester) async {
      await tester.pumpWidget(createSubject(_testComment(username: '')));
      await tester.pump();

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('shows relative timestamp', (tester) async {
      await tester.pumpWidget(createSubject(_testComment()));
      await tester.pump();

      // formatCommunityDate produces localized relative time key
      // In test environment without EasyLocalization, the raw key is shown
      expect(find.textContaining('community.'), findsWidgets);
    });
  });

  group('CommunityCommentTile — like button', () {
    testWidgets('shows like count when > 0', (tester) async {
      await tester.pumpWidget(createSubject(_testComment(likeCount: 12)));
      await tester.pump();

      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('hides like count when 0', (tester) async {
      await tester.pumpWidget(createSubject(_testComment(likeCount: 0)));
      await tester.pump();

      expect(find.text('0'), findsNothing);
    });

    testWidgets('renders like button as InkWell', (tester) async {
      await tester.pumpWidget(createSubject(_testComment()));
      await tester.pump();

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('tap like button calls toggleCommentLike', (tester) async {
      when(
        () => mockSocialRepo.toggleCommentLike(
          userId: any(named: 'userId'),
          commentId: any(named: 'commentId'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        createSubject(
          _testComment(id: 'c-42', postId: 'p-99'),
          currentUserId: 'liker-user',
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      verify(
        () => mockSocialRepo.toggleCommentLike(
          userId: 'liker-user',
          commentId: 'c-42',
        ),
      ).called(1);
    });
  });

  group('CommunityCommentTile — long press interactions', () {
    testWidgets('long press shows report dialog for other user comments', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(
          _testComment(userId: 'author-user'),
          currentUserId: 'viewer-user',
        ),
      );
      await tester.pump();

      await tester.longPress(find.text('Test comment content'));
      await tester.pumpAndSettle();

      expect(find.byType(SimpleDialog), findsOneWidget);
      expect(find.text('community.report_comment'), findsOneWidget);
    });

    testWidgets('report dialog shows all reason options', (tester) async {
      await tester.pumpWidget(
        createSubject(
          _testComment(userId: 'author-user'),
          currentUserId: 'viewer-user',
        ),
      );
      await tester.pump();

      await tester.longPress(find.text('Test comment content'));
      await tester.pumpAndSettle();

      expect(find.text('community.report_reason_spam'), findsOneWidget);
      expect(find.text('community.report_reason_harassment'), findsOneWidget);
      expect(
        find.text('community.report_reason_inappropriate'),
        findsOneWidget,
      );
      expect(
        find.text('community.report_reason_misinformation'),
        findsOneWidget,
      );
      expect(find.text('community.report_reason_other'), findsOneWidget);
    });

    testWidgets('long press shows delete dialog for own comment', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(
          _testComment(userId: 'my-user'),
          currentUserId: 'my-user',
        ),
      );
      await tester.pump();

      await tester.longPress(find.text('Test comment content'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('cancel button dismisses delete dialog', (tester) async {
      await tester.pumpWidget(
        createSubject(
          _testComment(userId: 'my-user'),
          currentUserId: 'my-user',
        ),
      );
      await tester.pump();

      await tester.longPress(find.text('Test comment content'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'common.cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('report submits and shows success snackbar', (tester) async {
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
          _testComment(userId: 'author-user', id: 'c-report'),
          currentUserId: 'reporter-user',
        ),
      );
      await tester.pump();

      await tester.longPress(find.text('Test comment content'));
      await tester.pumpAndSettle();

      // Select spam reason
      await tester.tap(find.text('community.report_reason_spam'));
      await tester.pump();
      await tester.pump();

      // Success goes through ActionFeedbackService
      expect(received, hasLength(1));
      expect(received.first.message, 'community.report_submitted');

      verify(
        () => mockSocialRepo.reportContent(
          userId: 'reporter-user',
          targetId: 'c-report',
          targetType: 'comment',
          reason: CommunityReportReason.spam,
        ),
      ).called(1);
    });
  });
}
