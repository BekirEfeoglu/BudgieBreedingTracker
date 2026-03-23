import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';

void main() {
  group('CommunityPost model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final now = DateTime.utc(2026, 3, 15, 10, 30);
        final post = CommunityPost(
          id: 'post-1',
          userId: 'user-1',
          username: 'TestUser',
          avatarUrl: 'https://example.com/avatar.png',
          postType: CommunityPostType.photo,
          title: 'My Budgie',
          content: 'Look at my budgie!',
          imageUrl: 'https://example.com/img.png',
          imageUrls: const ['https://example.com/img1.png'],
          birdId: 'bird-1',
          birdName: 'Mavi',
          mutationTags: const ['lutino', 'albino'],
          tags: const ['budgie', 'pet'],
          likeCount: 10,
          commentCount: 3,
          isDeleted: false,
          needsReview: true,
          createdAt: now,
          updatedAt: now,
        );

        final json = post.toJson();
        final restored = CommunityPost.fromJson(json);

        expect(restored.id, post.id);
        expect(restored.userId, post.userId);
        expect(restored.username, post.username);
        expect(restored.avatarUrl, post.avatarUrl);
        expect(restored.postType, post.postType);
        expect(restored.title, post.title);
        expect(restored.content, post.content);
        expect(restored.imageUrl, post.imageUrl);
        expect(restored.imageUrls, post.imageUrls);
        expect(restored.birdId, post.birdId);
        expect(restored.birdName, post.birdName);
        expect(restored.mutationTags, post.mutationTags);
        expect(restored.tags, post.tags);
        expect(restored.likeCount, post.likeCount);
        expect(restored.commentCount, post.commentCount);
        expect(restored.isDeleted, post.isDeleted);
        expect(restored.needsReview, post.needsReview);
        expect(restored.createdAt, post.createdAt);
        expect(restored.updatedAt, post.updatedAt);
      });

      test('handles null optional fields', () {
        const post = CommunityPost(
          id: 'post-1',
          userId: 'user-1',
          content: 'Hello',
        );

        final json = post.toJson();
        final restored = CommunityPost.fromJson(json);

        expect(restored.avatarUrl, isNull);
        expect(restored.title, isNull);
        expect(restored.imageUrl, isNull);
        expect(restored.birdId, isNull);
        expect(restored.birdName, isNull);
        expect(restored.createdAt, isNull);
        expect(restored.updatedAt, isNull);
      });

      test('defaults are correct', () {
        final post = CommunityPost.fromJson(const {
          'id': 'post-1',
          'user_id': 'user-1',
        });

        expect(post.username, '');
        expect(post.postType, CommunityPostType.general);
        expect(post.content, '');
        expect(post.imageUrls, isEmpty);
        expect(post.mutationTags, isEmpty);
        expect(post.tags, isEmpty);
        expect(post.likeCount, 0);
        expect(post.commentCount, 0);
        expect(post.isLikedByMe, false);
        expect(post.isBookmarkedByMe, false);
        expect(post.isFollowingAuthor, false);
        expect(post.isDeleted, false);
        expect(post.needsReview, false);
      });

      test('unknown enum values fall back to unknown', () {
        final post = CommunityPost.fromJson(const {
          'id': 'post-1',
          'user_id': 'user-1',
          'post_type': 'nonexistent_type',
        });

        expect(post.postType, CommunityPostType.unknown);
      });

      test('toJson produces snake_case keys', () {
        const post = CommunityPost(
          id: 'p1',
          userId: 'u1',
          avatarUrl: 'url',
          postType: CommunityPostType.guide,
          imageUrl: 'img',
          imageUrls: ['img1'],
          birdId: 'b1',
          birdName: 'Mavi',
          mutationTags: ['lutino'],
        );
        final json = post.toJson();

        expect(json.containsKey('user_id'), isTrue);
        expect(json.containsKey('avatar_url'), isTrue);
        expect(json.containsKey('post_type'), isTrue);
        expect(json.containsKey('image_url'), isTrue);
        expect(json.containsKey('image_urls'), isTrue);
        expect(json.containsKey('bird_id'), isTrue);
        expect(json.containsKey('bird_name'), isTrue);
        expect(json.containsKey('mutation_tags'), isTrue);
        expect(json.containsKey('like_count'), isTrue);
        expect(json.containsKey('comment_count'), isTrue);
        expect(json.containsKey('is_deleted'), isTrue);
        expect(json.containsKey('needs_review'), isTrue);
        expect(json.containsKey('created_at'), isTrue);
        expect(json.containsKey('updated_at'), isTrue);
      });

      test('includeFromJson: false fields are not read from JSON', () {
        final post = CommunityPost.fromJson(const {
          'id': 'p1',
          'user_id': 'u1',
          'is_liked_by_me': true,
          'is_bookmarked_by_me': true,
          'is_following_author': true,
        });

        expect(post.isLikedByMe, false);
        expect(post.isBookmarkedByMe, false);
        expect(post.isFollowingAuthor, false);
      });

      test('fromJson parses DateTime strings', () {
        final post = CommunityPost.fromJson(const {
          'id': 'p1',
          'user_id': 'u1',
          'created_at': '2026-03-15T10:00:00.000Z',
          'updated_at': '2026-03-16T12:00:00.000Z',
        });

        expect(post.createdAt, isNotNull);
        expect(post.createdAt!.year, 2026);
        expect(post.updatedAt, isNotNull);
        expect(post.updatedAt!.month, 3);
        expect(post.updatedAt!.day, 16);
      });

      test('fromJson handles list fields', () {
        final post = CommunityPost.fromJson(const {
          'id': 'p1',
          'user_id': 'u1',
          'image_urls': ['url1', 'url2', 'url3'],
          'mutation_tags': ['lutino'],
          'tags': ['budgie', 'pet'],
        });

        expect(post.imageUrls, hasLength(3));
        expect(post.mutationTags, ['lutino']);
        expect(post.tags, ['budgie', 'pet']);
      });

      test('postType round-trips all valid values', () {
        for (final type in CommunityPostType.values) {
          final post = CommunityPost(
            id: 'p1',
            userId: 'u1',
            postType: type,
          );

          final json = post.toJson();
          final restored = CommunityPost.fromJson(json);

          expect(restored.postType, type);
        }
      });
    });

    group('copyWith', () {
      test('creates new instance with changed field', () {
        const post = CommunityPost(
          id: 'p1',
          userId: 'u1',
          content: 'Original',
        );
        final updated = post.copyWith(content: 'Updated');

        expect(updated.content, 'Updated');
        expect(post.content, 'Original');
      });

      test('preserves unchanged fields', () {
        const post = CommunityPost(
          id: 'p1',
          userId: 'u1',
          username: 'User1',
          postType: CommunityPostType.question,
          content: 'How?',
          likeCount: 5,
        );
        final updated = post.copyWith(content: 'Why?');

        expect(updated.id, 'p1');
        expect(updated.userId, 'u1');
        expect(updated.username, 'User1');
        expect(updated.postType, CommunityPostType.question);
        expect(updated.likeCount, 5);
      });
    });

    group('equality', () {
      test('two posts with same fields are equal', () {
        const p1 = CommunityPost(
          id: 'p1',
          userId: 'u1',
          content: 'Hello',
        );
        const p2 = CommunityPost(
          id: 'p1',
          userId: 'u1',
          content: 'Hello',
        );

        expect(p1, equals(p2));
        expect(p1.hashCode, equals(p2.hashCode));
      });

      test('two posts with different fields are not equal', () {
        const p1 = CommunityPost(
          id: 'p1',
          userId: 'u1',
          content: 'Hello',
        );
        const p2 = CommunityPost(
          id: 'p2',
          userId: 'u1',
          content: 'Hello',
        );

        expect(p1, isNot(equals(p2)));
      });
    });
  });

  group('CommunityPostX extension', () {
    group('allImageUrls', () {
      test('returns empty list when no images', () {
        const post = CommunityPost(
          id: 'p1',
          userId: 'u1',
        );

        expect(post.allImageUrls, isEmpty);
      });

      test('returns imageUrl first when set', () {
        const post = CommunityPost(
          id: 'p1',
          userId: 'u1',
          imageUrl: 'https://example.com/main.png',
          imageUrls: ['https://example.com/extra1.png'],
        );

        expect(post.allImageUrls, hasLength(2));
        expect(post.allImageUrls.first, 'https://example.com/main.png');
        expect(post.allImageUrls.last, 'https://example.com/extra1.png');
      });

      test('returns only imageUrls when imageUrl is null', () {
        const post = CommunityPost(
          id: 'p1',
          userId: 'u1',
          imageUrls: ['https://example.com/img1.png'],
        );

        expect(post.allImageUrls, hasLength(1));
        expect(post.allImageUrls.first, 'https://example.com/img1.png');
      });

      test('returns only imageUrl when imageUrls is empty', () {
        const post = CommunityPost(
          id: 'p1',
          userId: 'u1',
          imageUrl: 'https://example.com/main.png',
        );

        expect(post.allImageUrls, hasLength(1));
        expect(post.allImageUrls.first, 'https://example.com/main.png');
      });
    });

    group('primaryImageUrl', () {
      test('returns null when no images', () {
        const post = CommunityPost(id: 'p1', userId: 'u1');

        expect(post.primaryImageUrl, isNull);
      });

      test('returns imageUrl when set', () {
        const post = CommunityPost(
          id: 'p1',
          userId: 'u1',
          imageUrl: 'https://example.com/main.png',
          imageUrls: ['https://example.com/extra.png'],
        );

        expect(post.primaryImageUrl, 'https://example.com/main.png');
      });

      test('returns first imageUrls entry when imageUrl is null', () {
        const post = CommunityPost(
          id: 'p1',
          userId: 'u1',
          imageUrls: [
            'https://example.com/first.png',
            'https://example.com/second.png',
          ],
        );

        expect(post.primaryImageUrl, 'https://example.com/first.png');
      });
    });
  });
}
