import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/remote/api/community_comment_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_social_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/community_comment_repository.dart';

class MockCommunityCommentRemoteSource extends Mock
    implements CommunityCommentRemoteSource {}

class MockCommunitySocialRemoteSource extends Mock
    implements CommunitySocialRemoteSource {}

void main() {
  late MockCommunityCommentRemoteSource commentSource;
  late MockCommunitySocialRemoteSource socialSource;
  late CommunityCommentRepository repository;

  setUp(() {
    commentSource = MockCommunityCommentRemoteSource();
    socialSource = MockCommunitySocialRemoteSource();

    repository = CommunityCommentRepository(
      commentSource: commentSource,
      socialSource: socialSource,
    );
  });

  group('create', () {
    test(
      'calls insert with correct post_id, user_id, and trimmed content',
      () async {
        when(() => commentSource.insert(any())).thenAnswer((_) async {});

        await repository.create(
          postId: 'p1',
          userId: 'u1',
          content: '  Hello World  ',
        );

        final captured =
            verify(() => commentSource.insert(captureAny())).captured.single
                as Map<String, dynamic>;

        expect(captured['post_id'], 'p1');
        expect(captured['user_id'], 'u1');
        expect(captured['content'], 'Hello World');
        expect(captured['id'], isNotEmpty);
      },
    );
  });

  group('delete', () {
    test('calls softDelete with correct commentId and userId', () async {
      when(
        () => commentSource.softDelete(any(), any()),
      ).thenAnswer((_) async {});

      await repository.delete(commentId: 'c1', userId: 'u1');

      verify(() => commentSource.softDelete('c1', 'u1')).called(1);
    });
  });

  group('getByPost', () {
    test('returns parsed comments with like status', () async {
      when(() => commentSource.fetchByPost(any())).thenAnswer(
        (_) async => [
          {
            'id': 'c1',
            'post_id': 'p1',
            'user_id': 'u1',
            'content': 'Nice post!',
            'like_count': 2,
            'username': 'TestUser',
            'avatar_url': null,
            'created_at': '2026-03-15T10:00:00Z',
          },
          {
            'id': 'c2',
            'post_id': 'p1',
            'user_id': 'u2',
            'content': 'Thanks!',
            'like_count': 0,
            'username': 'OtherUser',
            'avatar_url': null,
            'created_at': '2026-03-15T10:05:00Z',
          },
        ],
      );

      when(
        () => socialSource.fetchLikedCommentIds(any(), any()),
      ).thenAnswer((_) async => {'c1'});

      final comments = await repository.getByPost(
        postId: 'p1',
        currentUserId: 'u1',
      );

      expect(comments, hasLength(2));
      expect(comments[0].content, 'Nice post!');
      expect(comments[0].isLikedByMe, isTrue);
      expect(comments[1].content, 'Thanks!');
      expect(comments[1].isLikedByMe, isFalse);
    });

    test('skips like check for anonymous user', () async {
      when(() => commentSource.fetchByPost(any())).thenAnswer(
        (_) async => [
          {
            'id': 'c1',
            'post_id': 'p1',
            'user_id': 'u1',
            'content': 'Hello',
            'like_count': 0,
            'username': 'User',
            'avatar_url': null,
            'created_at': '2026-03-15T10:00:00Z',
          },
        ],
      );

      final comments = await repository.getByPost(
        postId: 'p1',
        currentUserId: 'anonymous',
      );

      expect(comments, hasLength(1));
      expect(comments[0].isLikedByMe, isFalse);
      verifyNever(() => socialSource.fetchLikedCommentIds(any(), any()));
    });

    test('returns empty list when no comments', () async {
      when(() => commentSource.fetchByPost(any())).thenAnswer((_) async => []);

      final comments = await repository.getByPost(
        postId: 'p1',
        currentUserId: 'u1',
      );

      expect(comments, isEmpty);
    });

    test('handles like fetch failure gracefully', () async {
      when(() => commentSource.fetchByPost(any())).thenAnswer(
        (_) async => [
          {
            'id': 'c1',
            'post_id': 'p1',
            'user_id': 'u1',
            'content': 'Hi',
            'like_count': 0,
            'username': 'User',
            'avatar_url': null,
            'created_at': '2026-03-15T10:00:00Z',
          },
        ],
      );

      when(
        () => socialSource.fetchLikedCommentIds(any(), any()),
      ).thenThrow(Exception('Network error'));

      final comments = await repository.getByPost(
        postId: 'p1',
        currentUserId: 'u1',
      );

      expect(comments, hasLength(1));
      expect(comments[0].isLikedByMe, isFalse);
    });
  });
}
