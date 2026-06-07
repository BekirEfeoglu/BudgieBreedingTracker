@Tags(['community'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/remote/api/community_comment_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_profile_cache.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';

import '../../../helpers/fake_supabase.dart';
import '../../../helpers/mocks.dart';

void main() {
  late RoutingFakeClient client;
  late FakeFilterBuilder<PostgrestList> commentsSelect;
  late FakeQueryBuilder commentsQuery;
  late MockEdgeFunctionClient edgeClient;
  late CommunityCommentRemoteSource source;

  setUp(() {
    client = RoutingFakeClient();
    final comments = client.addTable('community_comments');
    final profiles = client.addTable('profiles');
    commentsSelect = comments.selectBuilder;
    commentsQuery = comments.queryBuilder;
    profiles.selectBuilder.result = [];
    edgeClient = MockEdgeFunctionClient();

    final cache = CommunityProfileCache(client);
    source = CommunityCommentRemoteSource(client, cache, edgeClient);
  });

  group('fetchByPost', () {
    test(
      'queries by post_id with is_deleted filter and ascending order',
      () async {
        commentsSelect.result = [
          {
            'id': 'c1',
            'post_id': 'p1',
            'user_id': 'u1',
            'content': 'Nice!',
            'like_count': 0,
          },
          {
            'id': 'c2',
            'post_id': 'p1',
            'user_id': 'u2',
            'content': 'Thanks!',
            'like_count': 3,
          },
        ];

        final result = await source.fetchByPost('p1');

        expect(result, hasLength(2));
        expect(result[0]['content'], 'Nice!');
        expect(result[1]['content'], 'Thanks!');

        final eqCalls = commentsSelect.eqCalls;
        expect(eqCalls, hasLength(2));
        expect(eqCalls[0].key, 'post_id');
        expect(eqCalls[0].value, 'p1');
        expect(eqCalls[1].key, 'is_deleted');
        expect(eqCalls[1].value, false);

        expect(commentsSelect.orderCalls, contains('created_at'));
        expect(client.requestedTables, contains('community_comments'));
      },
    );

    test('applies default limit of 20', () async {
      commentsSelect.result = [];

      await source.fetchByPost('p1');

      expect(commentsSelect.limitValue, 20);
    });

    test('applies custom limit', () async {
      commentsSelect.result = [];

      await source.fetchByPost('p1', limit: 5);

      expect(commentsSelect.limitValue, 5);
    });

    test('applies cursor filter when cursor is provided', () async {
      commentsSelect.result = [];
      final cursor = DateTime(2026, 4, 14, 12, 0);

      await source.fetchByPost('p1', cursor: cursor);

      expect(commentsSelect.gtCalls, hasLength(1));
      expect(commentsSelect.gtCalls[0].key, 'created_at');
      expect(commentsSelect.gtCalls[0].value, cursor.toIso8601String());
    });

    test('does not apply cursor filter when cursor is null', () async {
      commentsSelect.result = [];

      await source.fetchByPost('p1');

      expect(commentsSelect.gtCalls, isEmpty);
    });

    test('triggers profile lookup', () async {
      commentsSelect.result = [
        {'id': 'c1', 'post_id': 'p1', 'user_id': 'u1', 'content': 'Hi'},
      ];

      await source.fetchByPost('p1');

      expect(client.requestedTables, contains('profiles'));
    });

    test('returns empty list when no comments', () async {
      commentsSelect.result = [];

      final result = await source.fetchByPost('p_empty');

      expect(result, isEmpty);
    });
  });

  group('insert', () {
    test(
      'creates comment through Edge Function instead of table upsert',
      () async {
        final data = {
          'id': 'c1',
          'post_id': 'p1',
          'user_id': 'u1',
          'content': 'Great!',
        };
        when(
          () => edgeClient.createCommunityComment(
            postId: 'p1',
            content: 'Great!',
          ),
        ).thenAnswer((_) async => const EdgeFunctionResult(success: true));

        await source.insert(data);

        verify(
          () => edgeClient.createCommunityComment(
            postId: 'p1',
            content: 'Great!',
          ),
        ).called(1);
        expect(commentsQuery.upsertPayload, isNull);
        expect(client.requestedTables, isNot(contains('community_comments')));
      },
    );

    test('throws when comment Edge Function rejects creation', () async {
      final data = {'post_id': 'p1', 'content': 'Great!'};
      when(
        () =>
            edgeClient.createCommunityComment(postId: 'p1', content: 'Great!'),
      ).thenAnswer(
        (_) async => const EdgeFunctionResult(
          success: false,
          error: 'moderation_failed',
        ),
      );

      await expectLater(() => source.insert(data), throwsException);
    });
  });

  group('softDelete', () {
    test('soft-deletes by comment id and user id', () async {
      await source.softDelete('c1', 'u1');

      final eqCalls = commentsQuery.updateBuilder.eqCalls;
      expect(eqCalls, hasLength(2));
      expect(eqCalls[0].key, 'id');
      expect(eqCalls[0].value, 'c1');
      expect(eqCalls[1].key, 'user_id');
      expect(eqCalls[1].value, 'u1');
    });
  });
}
