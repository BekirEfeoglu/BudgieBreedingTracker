@Tags(['community'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_social_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/community_social_repository.dart';

class MockCommunitySocialRemoteSource extends Mock
    implements CommunitySocialRemoteSource {}

void main() {
  late MockCommunitySocialRemoteSource mockSource;
  late CommunitySocialRepository repository;

  const userId = 'user-1';
  const postId = 'post-1';
  const commentId = 'comment-1';
  const targetUserId = 'target-user-1';

  setUpAll(() {
    registerFallbackValue(CommunityReportReason.unknown);
  });

  setUp(() {
    mockSource = MockCommunitySocialRemoteSource();
    repository = CommunitySocialRepository(source: mockSource);
  });

  group('toggleLike', () {
    test('calls unlikePost when post is already liked', () async {
      when(
        () => mockSource.isPostLiked(userId, postId),
      ).thenAnswer((_) async => true);
      when(
        () => mockSource.unlikePost(userId, postId),
      ).thenAnswer((_) async {});

      await repository.toggleLike(userId: userId, postId: postId);

      verify(() => mockSource.isPostLiked(userId, postId)).called(1);
      verify(() => mockSource.unlikePost(userId, postId)).called(1);
      verifyNever(() => mockSource.likePost(any(), any()));
    });

    test('calls likePost when post is not liked', () async {
      when(
        () => mockSource.isPostLiked(userId, postId),
      ).thenAnswer((_) async => false);
      when(() => mockSource.likePost(userId, postId)).thenAnswer((_) async {});

      await repository.toggleLike(userId: userId, postId: postId);

      verify(() => mockSource.isPostLiked(userId, postId)).called(1);
      verify(() => mockSource.likePost(userId, postId)).called(1);
      verifyNever(() => mockSource.unlikePost(any(), any()));
    });
  });

  group('toggleBookmark', () {
    test('calls unbookmarkPost when post is already bookmarked', () async {
      when(
        () => mockSource.isPostBookmarked(userId, postId),
      ).thenAnswer((_) async => true);
      when(
        () => mockSource.unbookmarkPost(userId, postId),
      ).thenAnswer((_) async {});

      await repository.toggleBookmark(userId: userId, postId: postId);

      verify(() => mockSource.isPostBookmarked(userId, postId)).called(1);
      verify(() => mockSource.unbookmarkPost(userId, postId)).called(1);
      verifyNever(() => mockSource.bookmarkPost(any(), any()));
    });

    test('calls bookmarkPost when post is not bookmarked', () async {
      when(
        () => mockSource.isPostBookmarked(userId, postId),
      ).thenAnswer((_) async => false);
      when(
        () => mockSource.bookmarkPost(userId, postId),
      ).thenAnswer((_) async {});

      await repository.toggleBookmark(userId: userId, postId: postId);

      verify(() => mockSource.isPostBookmarked(userId, postId)).called(1);
      verify(() => mockSource.bookmarkPost(userId, postId)).called(1);
      verifyNever(() => mockSource.unbookmarkPost(any(), any()));
    });
  });

  group('toggleCommentLike', () {
    test('calls unlikeComment when comment is already liked', () async {
      when(
        () => mockSource.isCommentLiked(userId, commentId),
      ).thenAnswer((_) async => true);
      when(
        () => mockSource.unlikeComment(userId, commentId),
      ).thenAnswer((_) async {});

      await repository.toggleCommentLike(userId: userId, commentId: commentId);

      verify(() => mockSource.isCommentLiked(userId, commentId)).called(1);
      verify(() => mockSource.unlikeComment(userId, commentId)).called(1);
      verifyNever(() => mockSource.likeComment(any(), any()));
    });

    test('calls likeComment when comment is not liked', () async {
      when(
        () => mockSource.isCommentLiked(userId, commentId),
      ).thenAnswer((_) async => false);
      when(
        () => mockSource.likeComment(userId, commentId),
      ).thenAnswer((_) async {});

      await repository.toggleCommentLike(userId: userId, commentId: commentId);

      verify(() => mockSource.isCommentLiked(userId, commentId)).called(1);
      verify(() => mockSource.likeComment(userId, commentId)).called(1);
      verifyNever(() => mockSource.unlikeComment(any(), any()));
    });
  });

  group('toggleFollow', () {
    test('calls unfollowUser when already following', () async {
      when(
        () => mockSource.isFollowing(userId, targetUserId),
      ).thenAnswer((_) async => true);
      when(
        () => mockSource.unfollowUser(userId, targetUserId),
      ).thenAnswer((_) async {});

      await repository.toggleFollow(userId: userId, targetUserId: targetUserId);

      verify(() => mockSource.isFollowing(userId, targetUserId)).called(1);
      verify(() => mockSource.unfollowUser(userId, targetUserId)).called(1);
      verifyNever(() => mockSource.followUser(any(), any()));
    });

    test('calls followUser when not following', () async {
      when(
        () => mockSource.isFollowing(userId, targetUserId),
      ).thenAnswer((_) async => false);
      when(
        () => mockSource.followUser(userId, targetUserId),
      ).thenAnswer((_) async {});

      await repository.toggleFollow(userId: userId, targetUserId: targetUserId);

      verify(() => mockSource.isFollowing(userId, targetUserId)).called(1);
      verify(() => mockSource.followUser(userId, targetUserId)).called(1);
      verifyNever(() => mockSource.unfollowUser(any(), any()));
    });
  });

  group('reportContent', () {
    test('forwards all parameters to remote source', () async {
      when(
        () => mockSource.reportContent(
          userId: any(named: 'userId'),
          targetId: any(named: 'targetId'),
          targetType: any(named: 'targetType'),
          reason: any(named: 'reason'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async {});

      await repository.reportContent(
        userId: userId,
        targetId: postId,
        targetType: 'post',
        reason: CommunityReportReason.spam,
        description: 'This is spam content',
      );

      verify(
        () => mockSource.reportContent(
          userId: userId,
          targetId: postId,
          targetType: 'post',
          reason: CommunityReportReason.spam,
          description: 'This is spam content',
        ),
      ).called(1);
    });

    test('forwards without description when null', () async {
      when(
        () => mockSource.reportContent(
          userId: any(named: 'userId'),
          targetId: any(named: 'targetId'),
          targetType: any(named: 'targetType'),
          reason: any(named: 'reason'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async {});

      await repository.reportContent(
        userId: userId,
        targetId: commentId,
        targetType: 'comment',
        reason: CommunityReportReason.harassment,
      );

      verify(
        () => mockSource.reportContent(
          userId: userId,
          targetId: commentId,
          targetType: 'comment',
          reason: CommunityReportReason.harassment,
          description: null,
        ),
      ).called(1);
    });
  });
}
