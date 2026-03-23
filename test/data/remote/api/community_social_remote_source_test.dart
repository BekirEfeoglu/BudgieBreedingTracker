import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_social_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late RoutingFakeClient client;
  late CommunitySocialRemoteSource source;

  late FakeFilterBuilder<PostgrestList> likesSelect;
  late FakeQueryBuilder likesQuery;
  late FakeFilterBuilder<PostgrestList> commentLikesSelect;
  late FakeQueryBuilder commentLikesQuery;
  late FakeFilterBuilder<PostgrestList> bookmarksSelect;
  late FakeQueryBuilder bookmarksQuery;
  late FakeFilterBuilder<PostgrestList> followsSelect;
  late FakeQueryBuilder followsQuery;
  late FakeFilterBuilder<PostgrestList> blocksSelect;
  late FakeQueryBuilder blocksQuery;
  late FakeQueryBuilder reportsQuery;

  setUp(() {
    client = RoutingFakeClient();

    final likes = client.addTable('community_likes');
    likesSelect = likes.selectBuilder;
    likesQuery = likes.queryBuilder;

    final commentLikes = client.addTable('community_comment_likes');
    commentLikesSelect = commentLikes.selectBuilder;
    commentLikesQuery = commentLikes.queryBuilder;

    final bookmarks = client.addTable('community_bookmarks');
    bookmarksSelect = bookmarks.selectBuilder;
    bookmarksQuery = bookmarks.queryBuilder;

    final follows = client.addTable('community_follows');
    followsSelect = follows.selectBuilder;
    followsQuery = follows.queryBuilder;

    final blocks = client.addTable('community_blocks');
    blocksSelect = blocks.selectBuilder;
    blocksQuery = blocks.queryBuilder;

    final reports = client.addTable('community_reports');
    reportsQuery = reports.queryBuilder;

    source = CommunitySocialRemoteSource(client);
  });

  // ── Post likes ──

  group('fetchLikedPostIds', () {
    test('returns empty set for empty postIds', () async {
      final result = await source.fetchLikedPostIds('user-1', []);
      expect(result, isEmpty);
    });

    test('returns empty set for anonymous user', () async {
      final result = await source.fetchLikedPostIds('anonymous', ['p1', 'p2']);
      expect(result, isEmpty);
    });

    test('returns set of liked post IDs', () async {
      likesSelect.result = [
        {'post_id': 'p1'},
        {'post_id': 'p3'},
      ];

      final result =
          await source.fetchLikedPostIds('user-1', ['p1', 'p2', 'p3']);

      expect(result, {'p1', 'p3'});
      expect(client.requestedTables, contains('community_likes'));
    });

    test('queries with correct filters', () async {
      likesSelect.result = [];

      await source.fetchLikedPostIds('user-1', ['p1', 'p2']);

      final eqCalls = likesSelect.eqCalls;
      expect(eqCalls, hasLength(1));
      expect(eqCalls[0].key, 'user_id');
      expect(eqCalls[0].value, 'user-1');

      expect(likesSelect.inFilterCalls, hasLength(1));
      expect(likesSelect.inFilterCalls[0].key, 'post_id');
      expect(likesSelect.inFilterCalls[0].value, ['p1', 'p2']);
    });

    test('returns empty set on error', () async {
      likesSelect.error = Exception('Network error');

      final result = await source.fetchLikedPostIds('user-1', ['p1']);
      expect(result, isEmpty);
    });
  });

  group('likePost', () {
    test('inserts like into community_likes table', () async {
      await source.likePost('user-1', 'post-1');

      expect(client.requestedTables, contains('community_likes'));
      final payload = likesQuery.insertPayload as Map<String, dynamic>;
      expect(payload['user_id'], 'user-1');
      expect(payload['post_id'], 'post-1');
      expect(payload['id'], isNotNull);
    });

    test('rethrows on error', () async {
      likesQuery.insertBuilder.error = Exception('Insert failed');

      expect(
        () => source.likePost('user-1', 'post-1'),
        throwsException,
      );
    });
  });

  group('unlikePost', () {
    test('deletes like from community_likes table', () async {
      await source.unlikePost('user-1', 'post-1');

      expect(client.requestedTables, contains('community_likes'));

      final eqCalls = likesQuery.deleteBuilder.eqCalls;
      expect(eqCalls, hasLength(2));
      expect(eqCalls[0].key, 'user_id');
      expect(eqCalls[0].value, 'user-1');
      expect(eqCalls[1].key, 'post_id');
      expect(eqCalls[1].value, 'post-1');
    });

    test('rethrows on error', () async {
      likesQuery.deleteBuilder.error = Exception('Delete failed');

      expect(
        () => source.unlikePost('user-1', 'post-1'),
        throwsException,
      );
    });
  });

  group('isPostLiked', () {
    test('returns true when like exists', () async {
      likesSelect.singleResult = {'id': 'like-1'};

      final result = await source.isPostLiked('user-1', 'post-1');
      expect(result, isTrue);
    });

    test('returns false when like does not exist', () async {
      likesSelect.singleResult = null;

      final result = await source.isPostLiked('user-1', 'post-1');
      expect(result, isFalse);
    });

    test('returns false on error', () async {
      likesSelect.error = Exception('Query failed');

      final result = await source.isPostLiked('user-1', 'post-1');
      expect(result, isFalse);
    });
  });

  // ── Comment likes ──

  group('fetchLikedCommentIds', () {
    test('returns empty set for empty commentIds', () async {
      final result = await source.fetchLikedCommentIds('user-1', []);
      expect(result, isEmpty);
    });

    test('returns empty set for anonymous user', () async {
      final result =
          await source.fetchLikedCommentIds('anonymous', ['c1', 'c2']);
      expect(result, isEmpty);
    });

    test('returns set of liked comment IDs', () async {
      commentLikesSelect.result = [
        {'comment_id': 'c1'},
        {'comment_id': 'c2'},
      ];

      final result =
          await source.fetchLikedCommentIds('user-1', ['c1', 'c2', 'c3']);

      expect(result, {'c1', 'c2'});
      expect(client.requestedTables, contains('community_comment_likes'));
    });

    test('returns empty set on error', () async {
      commentLikesSelect.error = Exception('Network error');

      final result = await source.fetchLikedCommentIds('user-1', ['c1']);
      expect(result, isEmpty);
    });
  });

  group('likeComment', () {
    test('inserts like into community_comment_likes table', () async {
      await source.likeComment('user-1', 'comment-1');

      expect(client.requestedTables, contains('community_comment_likes'));
      final payload = commentLikesQuery.insertPayload as Map<String, dynamic>;
      expect(payload['user_id'], 'user-1');
      expect(payload['comment_id'], 'comment-1');
      expect(payload['id'], isNotNull);
    });

    test('rethrows on error', () async {
      commentLikesQuery.insertBuilder.error = Exception('Insert failed');

      expect(
        () => source.likeComment('user-1', 'comment-1'),
        throwsException,
      );
    });
  });

  group('unlikeComment', () {
    test('deletes like from community_comment_likes table', () async {
      await source.unlikeComment('user-1', 'comment-1');

      expect(client.requestedTables, contains('community_comment_likes'));

      final eqCalls = commentLikesQuery.deleteBuilder.eqCalls;
      expect(eqCalls, hasLength(2));
      expect(eqCalls[0].key, 'user_id');
      expect(eqCalls[0].value, 'user-1');
      expect(eqCalls[1].key, 'comment_id');
      expect(eqCalls[1].value, 'comment-1');
    });
  });

  group('isCommentLiked', () {
    test('returns true when like exists', () async {
      commentLikesSelect.singleResult = {'id': 'cl-1'};

      final result = await source.isCommentLiked('user-1', 'comment-1');
      expect(result, isTrue);
    });

    test('returns false when like does not exist', () async {
      commentLikesSelect.singleResult = null;

      final result = await source.isCommentLiked('user-1', 'comment-1');
      expect(result, isFalse);
    });

    test('returns false on error', () async {
      commentLikesSelect.error = Exception('Query failed');

      final result = await source.isCommentLiked('user-1', 'comment-1');
      expect(result, isFalse);
    });
  });

  // ── Bookmarks ──

  group('fetchBookmarkedPostIds', () {
    test('returns empty set for empty postIds', () async {
      final result = await source.fetchBookmarkedPostIds('user-1', []);
      expect(result, isEmpty);
    });

    test('returns empty set for anonymous user', () async {
      final result =
          await source.fetchBookmarkedPostIds('anonymous', ['p1', 'p2']);
      expect(result, isEmpty);
    });

    test('returns set of bookmarked post IDs', () async {
      bookmarksSelect.result = [
        {'post_id': 'p2'},
      ];

      final result =
          await source.fetchBookmarkedPostIds('user-1', ['p1', 'p2']);

      expect(result, {'p2'});
      expect(client.requestedTables, contains('community_bookmarks'));
    });

    test('returns empty set on error', () async {
      bookmarksSelect.error = Exception('Network error');

      final result = await source.fetchBookmarkedPostIds('user-1', ['p1']);
      expect(result, isEmpty);
    });
  });

  group('bookmarkPost', () {
    test('inserts bookmark into community_bookmarks table', () async {
      await source.bookmarkPost('user-1', 'post-1');

      expect(client.requestedTables, contains('community_bookmarks'));
      final payload = bookmarksQuery.insertPayload as Map<String, dynamic>;
      expect(payload['user_id'], 'user-1');
      expect(payload['post_id'], 'post-1');
      expect(payload['id'], isNotNull);
    });

    test('rethrows on error', () async {
      bookmarksQuery.insertBuilder.error = Exception('Insert failed');

      expect(
        () => source.bookmarkPost('user-1', 'post-1'),
        throwsException,
      );
    });
  });

  group('unbookmarkPost', () {
    test('deletes bookmark from community_bookmarks table', () async {
      await source.unbookmarkPost('user-1', 'post-1');

      expect(client.requestedTables, contains('community_bookmarks'));

      final eqCalls = bookmarksQuery.deleteBuilder.eqCalls;
      expect(eqCalls, hasLength(2));
      expect(eqCalls[0].key, 'user_id');
      expect(eqCalls[0].value, 'user-1');
      expect(eqCalls[1].key, 'post_id');
      expect(eqCalls[1].value, 'post-1');
    });
  });

  group('isPostBookmarked', () {
    test('returns true when bookmarked', () async {
      bookmarksSelect.singleResult = {'id': 'bm-1'};

      final result = await source.isPostBookmarked('user-1', 'post-1');
      expect(result, isTrue);
    });

    test('returns false when not bookmarked', () async {
      bookmarksSelect.singleResult = null;

      final result = await source.isPostBookmarked('user-1', 'post-1');
      expect(result, isFalse);
    });

    test('returns false on error', () async {
      bookmarksSelect.error = Exception('Query failed');

      final result = await source.isPostBookmarked('user-1', 'post-1');
      expect(result, isFalse);
    });
  });

  group('fetchAllBookmarkedPostIds', () {
    test('returns empty list for anonymous user', () async {
      final result = await source.fetchAllBookmarkedPostIds('anonymous');
      expect(result, isEmpty);
    });

    test('returns list of all bookmarked post IDs', () async {
      bookmarksSelect.result = [
        {'post_id': 'p1'},
        {'post_id': 'p2'},
        {'post_id': 'p3'},
      ];

      final result = await source.fetchAllBookmarkedPostIds('user-1');

      expect(result, ['p1', 'p2', 'p3']);
    });

    test('returns empty list on error', () async {
      bookmarksSelect.error = Exception('Network error');

      final result = await source.fetchAllBookmarkedPostIds('user-1');
      expect(result, isEmpty);
    });
  });

  // ── Follows ──

  group('fetchFollowedUserIds', () {
    test('returns empty set for anonymous user', () async {
      final result = await source.fetchFollowedUserIds('anonymous');
      expect(result, isEmpty);
    });

    test('returns set of followed user IDs', () async {
      followsSelect.result = [
        {'following_id': 'u2'},
        {'following_id': 'u3'},
      ];

      final result = await source.fetchFollowedUserIds('user-1');

      expect(result, {'u2', 'u3'});
      expect(client.requestedTables, contains('community_follows'));
    });

    test('queries with correct filter', () async {
      followsSelect.result = [];

      await source.fetchFollowedUserIds('user-1');

      final eqCalls = followsSelect.eqCalls;
      expect(eqCalls, hasLength(1));
      expect(eqCalls[0].key, 'follower_id');
      expect(eqCalls[0].value, 'user-1');
    });

    test('returns empty set on error', () async {
      followsSelect.error = Exception('Network error');

      final result = await source.fetchFollowedUserIds('user-1');
      expect(result, isEmpty);
    });
  });

  group('isFollowing', () {
    test('returns true when following', () async {
      followsSelect.singleResult = {'id': 'f-1'};

      final result = await source.isFollowing('user-1', 'user-2');
      expect(result, isTrue);
    });

    test('returns false when not following', () async {
      followsSelect.singleResult = null;

      final result = await source.isFollowing('user-1', 'user-2');
      expect(result, isFalse);
    });

    test('returns false on error', () async {
      followsSelect.error = Exception('Query failed');

      final result = await source.isFollowing('user-1', 'user-2');
      expect(result, isFalse);
    });
  });

  group('followUser', () {
    test('inserts follow into community_follows table', () async {
      await source.followUser('user-1', 'user-2');

      expect(client.requestedTables, contains('community_follows'));
      final payload = followsQuery.insertPayload as Map<String, dynamic>;
      expect(payload['follower_id'], 'user-1');
      expect(payload['following_id'], 'user-2');
      expect(payload['id'], isNotNull);
    });

    test('rethrows on error', () async {
      followsQuery.insertBuilder.error = Exception('Insert failed');

      expect(
        () => source.followUser('user-1', 'user-2'),
        throwsException,
      );
    });
  });

  group('unfollowUser', () {
    test('deletes follow from community_follows table', () async {
      await source.unfollowUser('user-1', 'user-2');

      expect(client.requestedTables, contains('community_follows'));

      final eqCalls = followsQuery.deleteBuilder.eqCalls;
      expect(eqCalls, hasLength(2));
      expect(eqCalls[0].key, 'follower_id');
      expect(eqCalls[0].value, 'user-1');
      expect(eqCalls[1].key, 'following_id');
      expect(eqCalls[1].value, 'user-2');
    });
  });

  // ── Blocks ──

  group('fetchBlockedUserIds', () {
    test('returns empty list for anonymous user', () async {
      final result = await source.fetchBlockedUserIds('anonymous');
      expect(result, isEmpty);
    });

    test('returns list of blocked user IDs', () async {
      blocksSelect.result = [
        {'blocked_user_id': 'u5'},
        {'blocked_user_id': 'u6'},
      ];

      final result = await source.fetchBlockedUserIds('user-1');

      expect(result, ['u5', 'u6']);
      expect(client.requestedTables, contains('community_blocks'));
    });

    test('returns empty list on error', () async {
      blocksSelect.error = Exception('Network error');

      final result = await source.fetchBlockedUserIds('user-1');
      expect(result, isEmpty);
    });
  });

  group('blockUser', () {
    test('inserts block into community_blocks table', () async {
      await source.blockUser('user-1', 'user-5');

      expect(client.requestedTables, contains('community_blocks'));
      final payload = blocksQuery.insertPayload as Map<String, dynamic>;
      expect(payload['user_id'], 'user-1');
      expect(payload['blocked_user_id'], 'user-5');
      expect(payload['id'], isNotNull);
    });

    test('rethrows on error', () async {
      blocksQuery.insertBuilder.error = Exception('Insert failed');

      expect(
        () => source.blockUser('user-1', 'user-5'),
        throwsException,
      );
    });
  });

  group('unblockUser', () {
    test('deletes block from community_blocks table', () async {
      await source.unblockUser('user-1', 'user-5');

      expect(client.requestedTables, contains('community_blocks'));

      final eqCalls = blocksQuery.deleteBuilder.eqCalls;
      expect(eqCalls, hasLength(2));
      expect(eqCalls[0].key, 'user_id');
      expect(eqCalls[0].value, 'user-1');
      expect(eqCalls[1].key, 'blocked_user_id');
      expect(eqCalls[1].value, 'user-5');
    });
  });

  // ── Reports ──

  group('reportContent', () {
    test('inserts report into community_reports table', () async {
      await source.reportContent(
        userId: 'user-1',
        targetId: 'post-1',
        targetType: 'post',
        reason: CommunityReportReason.spam,
      );

      expect(client.requestedTables, contains('community_reports'));
      final payload = reportsQuery.insertPayload as Map<String, dynamic>;
      expect(payload['user_id'], 'user-1');
      expect(payload['target_id'], 'post-1');
      expect(payload['target_type'], 'post');
      expect(payload['reason'], 'spam');
      expect(payload['id'], isNotNull);
    });

    test('includes description when provided', () async {
      await source.reportContent(
        userId: 'user-1',
        targetId: 'post-1',
        targetType: 'post',
        reason: CommunityReportReason.other,
        description: 'This content is problematic',
      );

      final payload = reportsQuery.insertPayload as Map<String, dynamic>;
      expect(payload['description'], 'This content is problematic');
    });

    test('omits description when null', () async {
      await source.reportContent(
        userId: 'user-1',
        targetId: 'comment-1',
        targetType: 'comment',
        reason: CommunityReportReason.harassment,
      );

      final payload = reportsQuery.insertPayload as Map<String, dynamic>;
      expect(payload.containsKey('description'), isFalse);
    });

    test('rethrows on error', () async {
      reportsQuery.insertBuilder.error = Exception('Insert failed');

      expect(
        () => source.reportContent(
          userId: 'user-1',
          targetId: 'post-1',
          targetType: 'post',
          reason: CommunityReportReason.inappropriate,
        ),
        throwsException,
      );
    });

    test('serializes all report reasons correctly', () async {
      for (final reason in CommunityReportReason.values) {
        if (reason == CommunityReportReason.unknown) continue;

        await source.reportContent(
          userId: 'user-1',
          targetId: 'post-1',
          targetType: 'post',
          reason: reason,
        );

        final payload = reportsQuery.insertPayload as Map<String, dynamic>;
        expect(payload['reason'], reason.toJson());
      }
    });
  });
}
