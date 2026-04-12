@Tags(['community'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/remote/api/community_post_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_profile_cache.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late RoutingFakeClient client;
  late FakeFilterBuilder<PostgrestList> postsSelect;
  late FakeFilterBuilder<PostgrestList> profilesSelect;
  late FakeQueryBuilder postsQuery;
  late CommunityPostRemoteSource source;

  setUp(() {
    client = RoutingFakeClient();
    final posts = client.addTable('community_posts');
    final profiles = client.addTable('profiles');
    postsSelect = posts.selectBuilder;
    postsQuery = posts.queryBuilder;
    profilesSelect = profiles.selectBuilder;
    profilesSelect.result = [];

    final cache = CommunityProfileCache(client);
    source = CommunityPostRemoteSource(client, cache);
  });

  group('fetchFeed', () {
    test('queries community_posts with correct filters', () async {
      postsSelect.result = [
        {'id': 'p1', 'user_id': 'u1', 'content': 'Hello', 'is_deleted': false},
      ];

      final result = await source.fetchFeed();

      expect(result, hasLength(1));
      expect(result.first['content'], 'Hello');
      expect(client.requestedTables, contains('community_posts'));
      expect(postsSelect.eqCalls.first.key, 'is_deleted');
      expect(postsSelect.eqCalls.first.value, false);
    });

    test('applies before filter and limit', () async {
      postsSelect.result = [];

      final before = DateTime(2026, 3, 1);
      await source.fetchFeed(limit: 10, before: before);

      expect(postsSelect.ltCalls, hasLength(1));
      expect(postsSelect.ltCalls.first.key, 'created_at');
      expect(postsSelect.limitValue, 10);
      expect(postsSelect.orderCalls, contains('created_at'));
    });

    test('triggers profile lookup for returned rows', () async {
      postsSelect.result = [
        {'id': 'p1', 'user_id': 'u1', 'content': 'Hello'},
      ];

      await source.fetchFeed();

      expect(client.requestedTables, contains('profiles'));
    });
  });

  group('fetchById', () {
    test('returns null for missing post', () async {
      postsSelect.singleResult = null;

      final result = await source.fetchById('missing');

      expect(result, isNull);
    });

    test('returns row when found', () async {
      postsSelect.singleResult = {
        'id': 'p1',
        'user_id': 'u2',
        'content': 'Found',
      };

      final result = await source.fetchById('p1');

      expect(result, isNotNull);
      expect(result!['content'], 'Found');
      expect(
        postsSelect.eqCalls.any((e) => e.key == 'id' && e.value == 'p1'),
        isTrue,
      );
    });
  });

  group('fetchByIds', () {
    test('returns empty list for empty IDs', () async {
      final result = await source.fetchByIds([]);

      expect(result, isEmpty);
      expect(client.requestedTables, isEmpty);
    });

    test('queries with inFilter', () async {
      postsSelect.result = [
        {'id': 'p1', 'user_id': 'u1', 'content': 'A'},
        {'id': 'p2', 'user_id': 'u2', 'content': 'B'},
      ];

      final result = await source.fetchByIds(['p1', 'p2']);

      expect(result, hasLength(2));
      expect(postsSelect.inFilterCalls, hasLength(1));
      expect(postsSelect.inFilterCalls.first.key, 'id');
      expect(postsSelect.inFilterCalls.first.value, ['p1', 'p2']);
    });
  });

  group('search', () {
    test('applies text filter via or clause', () async {
      postsSelect.result = [
        {'id': 'p1', 'user_id': 'u1', 'content': 'Budgie care tips'},
      ];

      final result = await source.search('budgie');

      expect(result, hasLength(1));
      expect(postsSelect.orCalls, hasLength(1));
      expect(postsSelect.orCalls.first, contains('content.ilike.%budgie%'));
      expect(postsSelect.orCalls.first, contains('title.ilike.%budgie%'));
    });

    test('strips backticks and double quotes from query', () async {
      postsSelect.result = [];

      await source.search('test`"; DROP TABLE--');

      expect(postsSelect.orCalls, hasLength(1));
      final filter = postsSelect.orCalls.first;
      // Backtick, double quote, and single quote should be removed
      expect(filter, isNot(contains('`')));
      expect(filter, isNot(contains('"')));
      expect(filter, isNot(contains("'")));
    });

    test('returns empty list for query that sanitizes to empty', () async {
      final result = await source.search("'`\"");

      expect(result, isEmpty);
    });
  });

  group('insert', () {
    test('sends data to community_posts table', () async {
      final data = {'id': 'p1', 'user_id': 'u1', 'content': 'New post'};

      await source.insert(data);

      expect(postsQuery.insertPayload, data);
      expect(client.requestedTables, contains('community_posts'));
    });
  });

  group('softDelete', () {
    test('updates is_deleted for matching post and user', () async {
      await source.softDelete('p1', 'u1');

      expect(postsQuery.updatePayload, {'is_deleted': true});
      final eqCalls = postsQuery.updateBuilder.eqCalls;
      expect(eqCalls, hasLength(2));
      expect(eqCalls[0].key, 'id');
      expect(eqCalls[0].value, 'p1');
      expect(eqCalls[1].key, 'user_id');
      expect(eqCalls[1].value, 'u1');
    });
  });
}
