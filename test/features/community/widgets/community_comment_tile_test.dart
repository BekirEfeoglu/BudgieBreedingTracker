import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/models/community_comment_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/data/repositories/community_comment_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/community_social_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_comment_tile.dart';

class MockCommunityCommentRepository extends Mock
    implements CommunityCommentRepository {}

class MockCommunitySocialRepository extends Mock
    implements CommunitySocialRepository {}

CommunityComment _testComment({
  String id = 'comment-1',
  String postId = 'post-1',
  String userId = 'user-1',
  String username = 'TestUser',
  String content = 'Test comment',
  int likeCount = 0,
  bool isLikedByMe = false,
}) {
  return CommunityComment(
    id: id,
    postId: postId,
    userId: userId,
    username: username,
    content: content,
    likeCount: likeCount,
    isLikedByMe: isLikedByMe,
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
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
        communityCommentRepositoryProvider
            .overrideWithValue(mockCommentRepo),
        communitySocialRepositoryProvider
            .overrideWithValue(mockSocialRepo),
        communityFeedProvider
            .overrideWith(() => _FakeFeedNotifier()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [CommunityCommentTile(comment: comment)],
          ),
        ),
      ),
    );
  }

  group('CommunityCommentTile', () {
    testWidgets('renders username and content', (tester) async {
      await tester.pumpWidget(createSubject(
        _testComment(username: 'Alice', content: 'Hello world'),
      ));
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('shows avatar initial when no avatarUrl', (tester) async {
      await tester.pumpWidget(createSubject(
        _testComment(username: 'Bob'),
      ));
      await tester.pump();

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('shows like count when > 0', (tester) async {
      await tester.pumpWidget(createSubject(
        _testComment(likeCount: 3),
      ));
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('renders like button', (tester) async {
      await tester.pumpWidget(createSubject(
        _testComment(isLikedByMe: false),
      ));
      await tester.pump();

      // Like button is the InkWell in the tile
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('hides like count when 0', (tester) async {
      await tester.pumpWidget(createSubject(
        _testComment(likeCount: 0),
      ));
      await tester.pump();

      expect(find.text('0'), findsNothing);
    });

    testWidgets('long press shows report dialog for other user comments',
        (tester) async {
      await tester.pumpWidget(createSubject(
        _testComment(userId: 'user-1'),
        currentUserId: 'other-user',
      ));
      await tester.pump();

      await tester.longPress(find.text('Test comment'));
      await tester.pumpAndSettle();

      // Report dialog should appear (SimpleDialog, not AlertDialog)
      expect(find.byType(SimpleDialog), findsOneWidget);
      expect(find.text('community.report_comment'), findsOneWidget);
    });

    testWidgets('long press shows delete dialog for own comment',
        (tester) async {
      await tester.pumpWidget(createSubject(
        _testComment(userId: 'my-user'),
        currentUserId: 'my-user',
      ));
      await tester.pump();

      await tester.longPress(find.text('Test comment'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('cancel button dismisses delete dialog', (tester) async {
      await tester.pumpWidget(createSubject(
        _testComment(userId: 'my-user'),
        currentUserId: 'my-user',
      ));
      await tester.pump();

      await tester.longPress(find.text('Test comment'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.widgetWithText(TextButton, 'common.cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('confirm delete calls notifier and shows snackbar on error',
        (tester) async {
      when(() => mockCommentRepo.delete(
            commentId: any(named: 'commentId'),
            userId: any(named: 'userId'),
          )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(createSubject(
        _testComment(userId: 'my-user', id: 'c-1', postId: 'p-1'),
        currentUserId: 'my-user',
      ));
      await tester.pump();

      // Long press to show dialog
      await tester.longPress(find.text('Test comment'));
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.widgetWithText(TextButton, 'common.delete'));
      await tester.pumpAndSettle();

      // SnackBar should appear with error message
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('community.delete_comment_error'), findsOneWidget);
    });

    testWidgets('confirm delete succeeds silently', (tester) async {
      when(() => mockCommentRepo.delete(
            commentId: any(named: 'commentId'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(createSubject(
        _testComment(userId: 'my-user', id: 'c-2', postId: 'p-2'),
        currentUserId: 'my-user',
      ));
      await tester.pump();

      await tester.longPress(find.text('Test comment'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'common.delete'));
      await tester.pumpAndSettle();

      // No error snackbar
      expect(find.byType(SnackBar), findsNothing);

      verify(() => mockCommentRepo.delete(
            commentId: 'c-2',
            userId: 'my-user',
          )).called(1);
    });

    testWidgets('report dialog shows reason options', (tester) async {
      await tester.pumpWidget(createSubject(
        _testComment(userId: 'user-1'),
        currentUserId: 'other-user',
      ));
      await tester.pump();

      await tester.longPress(find.text('Test comment'));
      await tester.pumpAndSettle();

      expect(find.text('community.report_reason_spam'), findsOneWidget);
      expect(find.text('community.report_reason_harassment'), findsOneWidget);
      expect(
          find.text('community.report_reason_inappropriate'), findsOneWidget);
      expect(
          find.text('community.report_reason_misinformation'), findsOneWidget);
      expect(find.text('community.report_reason_other'), findsOneWidget);
    });

    testWidgets('report submits and shows snackbar on success',
        (tester) async {
      when(() => mockSocialRepo.reportContent(
            userId: any(named: 'userId'),
            targetId: any(named: 'targetId'),
            targetType: any(named: 'targetType'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(createSubject(
        _testComment(userId: 'user-1', id: 'c-rep'),
        currentUserId: 'reporter',
      ));
      await tester.pump();

      await tester.longPress(find.text('Test comment'));
      await tester.pumpAndSettle();

      // Select spam reason
      await tester.tap(find.text('community.report_reason_spam'));
      await tester.pumpAndSettle();

      expect(find.text('community.report_submitted'), findsOneWidget);

      verify(() => mockSocialRepo.reportContent(
            userId: 'reporter',
            targetId: 'c-rep',
            targetType: 'comment',
            reason: CommunityReportReason.spam,
          )).called(1);
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
