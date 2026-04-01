import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/community/providers/community_providers.dart';

void main() {
  group('isCommunityEnabledProvider', () {
    test('returns true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isCommunityEnabledProvider), isTrue);
    });
  });

  group('exploreSortProvider', () {
    test('defaults to newest and can be updated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(exploreSortProvider), CommunityExploreSort.newest);

      container.read(exploreSortProvider.notifier).state =
          CommunityExploreSort.trending;

      expect(
        container.read(exploreSortProvider),
        CommunityExploreSort.trending,
      );
    });
  });

  group('formatCommunityDate', () {
    test('returns empty string for null date', () {
      expect(formatCommunityDate(null), isEmpty);
    });

    test('formats just now for sub-minute dates', () {
      final value = formatCommunityDate(
        DateTime.now().subtract(const Duration(seconds: 20)),
      );

      expect(value, 'community.just_now');
    });

    test('formats minutes ago for recent dates', () {
      final value = formatCommunityDate(
        DateTime.now().subtract(const Duration(minutes: 12)),
      );

      expect(value, 'community.minutes_ago');
    });

    test('formats hours ago for same-day dates', () {
      final value = formatCommunityDate(
        DateTime.now().subtract(const Duration(hours: 5)),
      );

      expect(value, 'community.hours_ago');
    });

    test('formats days ago for older dates', () {
      final value = formatCommunityDate(
        DateTime.now().subtract(const Duration(days: 3, hours: 1)),
      );

      expect(value, 'community.days_ago');
    });
  });

  group('CommunityPost', () {
    test('creates instance with required fields', () {
      final post = CommunityPost(
        id: '1',
        userId: 'u1',
        username: 'testuser',
        content: 'Hello!',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(post.id, '1');
      expect(post.username, 'testuser');
      expect(post.content, 'Hello!');
      expect(post.postType, CommunityPostType.general);
      expect(post.likeCount, 0);
      expect(post.commentCount, 0);
      expect(post.isLikedByMe, isFalse);
      expect(post.isBookmarkedByMe, isFalse);
    });

    test('optional fields default to null/zero', () {
      final post = CommunityPost(
        id: '1',
        userId: 'u1',
        username: 'x',
        content: 'y',
        createdAt: DateTime(2024),
      );

      expect(post.avatarUrl, isNull);
      expect(post.imageUrl, isNull);
      expect(post.imageUrls, isEmpty);
      expect(post.likeCount, 0);
      expect(post.commentCount, 0);
    });

    test('can set non-zero likeCount and commentCount', () {
      final post = CommunityPost(
        id: '2',
        userId: 'u2',
        username: 'alice',
        content: 'Great photo!',
        likeCount: 42,
        commentCount: 7,
        createdAt: DateTime(2024, 6, 1),
      );

      expect(post.likeCount, 42);
      expect(post.commentCount, 7);
    });

    test('copyWith updates specified fields', () {
      final post = CommunityPost(
        id: '1',
        userId: 'u1',
        username: 'testuser',
        content: 'Hello!',
        createdAt: DateTime(2024),
      );

      final updated = post.copyWith(
        isLikedByMe: true,
        likeCount: 5,
        isBookmarkedByMe: true,
      );

      expect(updated.isLikedByMe, isTrue);
      expect(updated.likeCount, 5);
      expect(updated.isBookmarkedByMe, isTrue);
      expect(updated.content, 'Hello!');
    });
  });

  group('CommunityComment', () {
    test('creates instance with required fields', () {
      final comment = CommunityComment(
        id: 'c1',
        postId: 'p1',
        userId: 'u1',
        username: 'bob',
        content: 'Nice post!',
        createdAt: DateTime(2024, 3, 1),
      );

      expect(comment.id, 'c1');
      expect(comment.postId, 'p1');
      expect(comment.content, 'Nice post!');
      expect(comment.likeCount, 0);
      expect(comment.isLikedByMe, isFalse);
    });

    test('copyWith updates like state', () {
      final comment = CommunityComment(
        id: 'c1',
        postId: 'p1',
        userId: 'u1',
        username: 'bob',
        content: 'Nice!',
        createdAt: DateTime(2024),
      );

      final updated = comment.copyWith(isLikedByMe: true, likeCount: 1);

      expect(updated.isLikedByMe, isTrue);
      expect(updated.likeCount, 1);
      expect(updated.content, 'Nice!');
    });
  });
}
