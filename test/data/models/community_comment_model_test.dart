@Tags(['community'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/community_comment_model.dart';

void main() {
  group('CommunityComment model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final now = DateTime.utc(2026, 3, 15, 10, 30);
        final comment = CommunityComment(
          id: 'comment-1',
          postId: 'post-1',
          userId: 'user-1',
          username: 'TestUser',
          avatarUrl: 'https://example.com/avatar.png',
          content: 'Great post!',
          likeCount: 5,
          needsReview: true,
          createdAt: now,
        );

        final json = comment.toJson();
        final restored = CommunityComment.fromJson(json);

        expect(restored.id, comment.id);
        expect(restored.postId, comment.postId);
        expect(restored.userId, comment.userId);
        expect(restored.username, comment.username);
        expect(restored.avatarUrl, comment.avatarUrl);
        expect(restored.content, comment.content);
        expect(restored.likeCount, comment.likeCount);
        expect(restored.needsReview, comment.needsReview);
        expect(restored.createdAt, comment.createdAt);
      });

      test('handles null optional fields', () {
        const comment = CommunityComment(
          id: 'comment-1',
          postId: 'post-1',
          userId: 'user-1',
          content: 'Hello',
        );

        final json = comment.toJson();
        final restored = CommunityComment.fromJson(json);

        expect(restored.avatarUrl, isNull);
        expect(restored.createdAt, isNull);
      });

      test('defaults are correct', () {
        final comment = CommunityComment.fromJson(const {
          'id': 'comment-1',
          'post_id': 'post-1',
          'user_id': 'user-1',
          'content': 'Hello',
        });

        expect(comment.username, '');
        expect(comment.likeCount, 0);
        expect(comment.isLikedByMe, false);
        expect(comment.needsReview, false);
      });

      test('toJson produces snake_case keys', () {
        const comment = CommunityComment(
          id: 'c1',
          postId: 'p1',
          userId: 'u1',
          content: 'text',
          avatarUrl: 'url',
        );
        final json = comment.toJson();

        expect(json.containsKey('post_id'), isTrue);
        expect(json.containsKey('user_id'), isTrue);
        expect(json.containsKey('avatar_url'), isTrue);
        expect(json.containsKey('like_count'), isTrue);
        expect(json.containsKey('needs_review'), isTrue);
        expect(json.containsKey('created_at'), isTrue);
      });

      test('isLikedByMe is excluded from fromJson (includeFromJson: false)',
          () {
        final comment = CommunityComment.fromJson(const {
          'id': 'c1',
          'post_id': 'p1',
          'user_id': 'u1',
          'content': 'text',
          'is_liked_by_me': true,
        });

        // isLikedByMe should always be false from JSON because of
        // @JsonKey(includeFromJson: false)
        expect(comment.isLikedByMe, false);
      });

      test('fromJson parses DateTime strings', () {
        final comment = CommunityComment.fromJson(const {
          'id': 'c1',
          'post_id': 'p1',
          'user_id': 'u1',
          'content': 'text',
          'created_at': '2026-01-15T08:00:00.000Z',
        });

        expect(comment.createdAt, isNotNull);
        expect(comment.createdAt!.year, 2026);
        expect(comment.createdAt!.month, 1);
        expect(comment.createdAt!.day, 15);
      });
    });

    group('copyWith', () {
      test('creates new instance with changed field', () {
        const comment = CommunityComment(
          id: 'c1',
          postId: 'p1',
          userId: 'u1',
          content: 'Original',
        );
        final updated = comment.copyWith(content: 'Updated');

        expect(updated.content, 'Updated');
        expect(comment.content, 'Original');
      });

      test('preserves unchanged fields', () {
        const comment = CommunityComment(
          id: 'c1',
          postId: 'p1',
          userId: 'u1',
          username: 'User1',
          content: 'Hello',
          likeCount: 3,
        );
        final updated = comment.copyWith(content: 'Goodbye');

        expect(updated.id, 'c1');
        expect(updated.postId, 'p1');
        expect(updated.userId, 'u1');
        expect(updated.username, 'User1');
        expect(updated.likeCount, 3);
      });
    });

    group('equality', () {
      test('two comments with same fields are equal', () {
        const c1 = CommunityComment(
          id: 'c1',
          postId: 'p1',
          userId: 'u1',
          content: 'Hello',
        );
        const c2 = CommunityComment(
          id: 'c1',
          postId: 'p1',
          userId: 'u1',
          content: 'Hello',
        );

        expect(c1, equals(c2));
        expect(c1.hashCode, equals(c2.hashCode));
      });

      test('two comments with different fields are not equal', () {
        const c1 = CommunityComment(
          id: 'c1',
          postId: 'p1',
          userId: 'u1',
          content: 'Hello',
        );
        const c2 = CommunityComment(
          id: 'c2',
          postId: 'p1',
          userId: 'u1',
          content: 'Hello',
        );

        expect(c1, isNot(equals(c2)));
      });
    });
  });
}
