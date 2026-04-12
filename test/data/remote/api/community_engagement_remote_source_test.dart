@Tags(['community'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_engagement_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late RoutingFakeClient client;
  late CommunityEngagementRemoteSource source;
  late FakeFilterBuilder<PostgrestList> bookmarkSelect;
  late FakeFilterBuilder<dynamic> bookmarkDelete;
  late FakeQueryBuilder bookmarkQuery;
  late FakeFilterBuilder<PostgrestList> followSelect;
  late FakeFilterBuilder<dynamic> followDelete;
  late FakeQueryBuilder followQuery;
  late FakeFilterBuilder<PostgrestList> blockSelect;
  late FakeFilterBuilder<dynamic> blockDelete;
  late FakeQueryBuilder blockQuery;
  late FakeQueryBuilder reportQuery;

  setUp(() {
    client = RoutingFakeClient();

    final bookmarks =
        client.addTable(SupabaseConstants.communityBookmarksTable);
    bookmarkSelect = bookmarks.selectBuilder;
    bookmarkDelete = bookmarks.deleteBuilder;
    bookmarkQuery = bookmarks.queryBuilder;

    final follows = client.addTable(SupabaseConstants.communityFollowsTable);
    followSelect = follows.selectBuilder;
    followDelete = follows.deleteBuilder;
    followQuery = follows.queryBuilder;

    final blocks = client.addTable(SupabaseConstants.communityBlocksTable);
    blockSelect = blocks.selectBuilder;
    blockDelete = blocks.deleteBuilder;
    blockQuery = blocks.queryBuilder;

    final reports = client.addTable(SupabaseConstants.communityReportsTable);
    reportQuery = reports.queryBuilder;

    source = CommunityEngagementRemoteSource(client);
  });

  group('Bookmarks', () {
    test('fetchBookmarkedPostIds returns set of post IDs', () async {
      bookmarkSelect.result = [
        {'post_id': 'p1'},
        {'post_id': 'p2'},
      ];

      final result =
          await source.fetchBookmarkedPostIds('user-1', ['p1', 'p2', 'p3']);

      expect(result, {'p1', 'p2'});
      expect(bookmarkSelect.eqCalls.first.key, 'user_id');
      expect(bookmarkSelect.inFilterCalls.first.key, 'post_id');
    });

    test('fetchBookmarkedPostIds returns empty for anonymous', () async {
      final result =
          await source.fetchBookmarkedPostIds('anonymous', ['p1']);

      expect(result, isEmpty);
    });

    test('fetchBookmarkedPostIds returns empty for empty list', () async {
      final result = await source.fetchBookmarkedPostIds('user-1', []);

      expect(result, isEmpty);
    });

    test('bookmarkPost inserts to correct table', () async {
      await source.bookmarkPost('user-1', 'post-1');

      expect(
        client.requestedTables,
        contains(SupabaseConstants.communityBookmarksTable),
      );
      final payload = bookmarkQuery.insertPayload as Map<String, dynamic>;
      expect(payload['user_id'], 'user-1');
      expect(payload['post_id'], 'post-1');
      expect(payload['id'], isNotNull);
    });

    test('unbookmarkPost deletes with filters', () async {
      await source.unbookmarkPost('user-1', 'post-1');

      final eqKeys = bookmarkDelete.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, containsAll(['user_id:user-1', 'post_id:post-1']));
    });

    test('isPostBookmarked returns true when found', () async {
      bookmarkSelect.singleResult = {'id': 'bm-1'};

      final result = await source.isPostBookmarked('user-1', 'post-1');

      expect(result, isTrue);
    });

    test('isPostBookmarked returns false when not found', () async {
      bookmarkSelect.singleResult = null;

      final result = await source.isPostBookmarked('user-1', 'post-1');

      expect(result, isFalse);
    });

    test('fetchAllBookmarkedPostIds returns list', () async {
      bookmarkSelect.result = [
        {'post_id': 'p1'},
        {'post_id': 'p2'},
      ];

      final result = await source.fetchAllBookmarkedPostIds('user-1');

      expect(result, ['p1', 'p2']);
    });

    test('fetchAllBookmarkedPostIds returns empty for anonymous', () async {
      final result = await source.fetchAllBookmarkedPostIds('anonymous');

      expect(result, isEmpty);
    });
  });

  group('Follows', () {
    test('fetchFollowedUserIds returns set', () async {
      followSelect.result = [
        {'following_id': 'u2'},
        {'following_id': 'u3'},
      ];

      final result = await source.fetchFollowedUserIds('user-1');

      expect(result, {'u2', 'u3'});
    });

    test('fetchFollowedUserIds returns empty for anonymous', () async {
      final result = await source.fetchFollowedUserIds('anonymous');

      expect(result, isEmpty);
    });

    test('isFollowing returns true when found', () async {
      followSelect.singleResult = {'id': 'f-1'};

      final result = await source.isFollowing('user-1', 'user-2');

      expect(result, isTrue);
    });

    test('followUser inserts with correct data', () async {
      await source.followUser('user-1', 'user-2');

      final payload = followQuery.insertPayload as Map<String, dynamic>;
      expect(payload['follower_id'], 'user-1');
      expect(payload['following_id'], 'user-2');
    });

    test('unfollowUser deletes with correct filters', () async {
      await source.unfollowUser('user-1', 'user-2');

      final eqKeys =
          followDelete.eqCalls.map((e) => '${e.key}:${e.value}').toList();
      expect(
        eqKeys,
        containsAll(['follower_id:user-1', 'following_id:user-2']),
      );
    });
  });

  group('Blocks', () {
    test('fetchBlockedUserIds returns list', () async {
      blockSelect.result = [
        {'blocked_user_id': 'u3'},
      ];

      final result = await source.fetchBlockedUserIds('user-1');

      expect(result, ['u3']);
    });

    test('fetchBlockedUserIds returns empty for anonymous', () async {
      final result = await source.fetchBlockedUserIds('anonymous');

      expect(result, isEmpty);
    });

    test('blockUser inserts with correct data', () async {
      await source.blockUser('user-1', 'bad-user');

      final payload = blockQuery.insertPayload as Map<String, dynamic>;
      expect(payload['user_id'], 'user-1');
      expect(payload['blocked_user_id'], 'bad-user');
    });

    test('unblockUser deletes with correct filters', () async {
      await source.unblockUser('user-1', 'bad-user');

      final eqKeys =
          blockDelete.eqCalls.map((e) => '${e.key}:${e.value}').toList();
      expect(
        eqKeys,
        containsAll(['user_id:user-1', 'blocked_user_id:bad-user']),
      );
    });
  });

  group('Reports', () {
    test('reportContent inserts with correct data', () async {
      await source.reportContent(
        userId: 'user-1',
        targetId: 'post-1',
        targetType: 'post',
        reason: CommunityReportReason.spam,
        description: 'Spam content',
      );

      final payload = reportQuery.insertPayload as Map<String, dynamic>;
      expect(payload['user_id'], 'user-1');
      expect(payload['target_id'], 'post-1');
      expect(payload['target_type'], 'post');
      expect(payload['description'], 'Spam content');
    });

    test('reportContent omits description when null', () async {
      await source.reportContent(
        userId: 'user-1',
        targetId: 'post-1',
        targetType: 'post',
        reason: CommunityReportReason.spam,
      );

      final payload = reportQuery.insertPayload as Map<String, dynamic>;
      expect(payload.containsKey('description'), isFalse);
    });
  });
}
