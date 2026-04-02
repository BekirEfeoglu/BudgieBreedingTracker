import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/remote/api/community_profile_cache.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeSupabaseClient client;
  late CommunityProfileCache cache;

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    client = stack.client;
    cache = CommunityProfileCache(client);
  });

  group('getProfiles', () {
    test('returns empty map for empty userIds', () async {
      final result = await cache.getProfiles({});

      expect(result, isEmpty);
      expect(selectBuilder.inFilterCalls, isEmpty);
    });

    test('fetches profiles from Supabase on cache miss', () async {
      selectBuilder.result = [
        {
          'id': 'u1',
          'display_name': 'Alice',
          'avatar_url': 'https://a.com/1.jpg',
        },
        {'id': 'u2', 'display_name': 'Bob', 'avatar_url': null},
      ];

      final result = await cache.getProfiles({'u1', 'u2'});

      expect(result, hasLength(2));
      expect(result['u1']!['display_name'], 'Alice');
      expect(result['u2']!['display_name'], 'Bob');
      expect(client.requestedTable, 'profiles');
      expect(selectBuilder.inFilterCalls, hasLength(1));
      expect(selectBuilder.inFilterCalls.first.key, 'id');
    });

    test(
      'returns cached profiles without Supabase call on cache hit',
      () async {
        selectBuilder.result = [
          {'id': 'u1', 'display_name': 'Alice', 'avatar_url': null},
        ];

        await cache.getProfiles({'u1'});
        expect(selectBuilder.inFilterCalls, hasLength(1));

        // Second call — should use cache, no new Supabase request.
        final result = await cache.getProfiles({'u1'});

        expect(result, hasLength(1));
        expect(result['u1']!['display_name'], 'Alice');
        expect(selectBuilder.inFilterCalls, hasLength(1));
      },
    );

    test('fetches only uncached IDs on partial cache hit', () async {
      selectBuilder.result = [
        {'id': 'u1', 'display_name': 'Alice', 'avatar_url': null},
      ];
      await cache.getProfiles({'u1'});

      // Now request u1 (cached) + u2 (not cached).
      selectBuilder.result = [
        {'id': 'u2', 'display_name': 'Bob', 'avatar_url': null},
      ];

      final result = await cache.getProfiles({'u1', 'u2'});

      expect(result, hasLength(2));
      expect(result['u1']!['display_name'], 'Alice');
      expect(result['u2']!['display_name'], 'Bob');
      // Second inFilter call should only contain u2.
      expect(selectBuilder.inFilterCalls, hasLength(2));
      final secondCallIds = selectBuilder.inFilterCalls[1].value;
      expect(secondCallIds, contains('u2'));
      expect(secondCallIds, isNot(contains('u1')));
    });

    test('returns partial results on Supabase error', () async {
      selectBuilder.result = [
        {'id': 'u1', 'display_name': 'Alice', 'avatar_url': null},
      ];
      await cache.getProfiles({'u1'});

      // Next fetch throws for u2.
      selectBuilder.error = Exception('network error');

      final result = await cache.getProfiles({'u1', 'u2'});

      // u1 from cache, u2 missing due to error.
      expect(result, hasLength(1));
      expect(result['u1']!['display_name'], 'Alice');
      expect(result.containsKey('u2'), isFalse);
    });

    test('re-fetches expired entries after TTL', () async {
      var clockTime = DateTime(2026, 1, 1, 12, 0, 0);
      final testCache = CommunityProfileCache.withClock(
        client,
        () => clockTime,
        ttl: const Duration(seconds: 10),
      );

      selectBuilder.result = [
        {'id': 'u1', 'display_name': 'Alice', 'avatar_url': null},
      ];
      await testCache.getProfiles({'u1'});
      expect(selectBuilder.inFilterCalls, hasLength(1));

      // Within TTL — cache hit.
      clockTime = DateTime(2026, 1, 1, 12, 0, 5);
      await testCache.getProfiles({'u1'});
      expect(selectBuilder.inFilterCalls, hasLength(1));

      // After TTL — should re-fetch.
      clockTime = DateTime(2026, 1, 1, 12, 0, 11);
      selectBuilder.result = [
        {'id': 'u1', 'display_name': 'Alice Updated', 'avatar_url': null},
      ];
      final result = await testCache.getProfiles({'u1'});

      expect(selectBuilder.inFilterCalls, hasLength(2));
      expect(result['u1']!['display_name'], 'Alice Updated');
    });
  });

  group('chunking', () {
    test('splits large ID sets into multiple requests', () async {
      // Create a cache with a small chunk size-equivalent by passing 50 IDs.
      // Default _chunkSize is 40, so 50 IDs → 2 chunks (40 + 10).
      final ids = List.generate(50, (i) => 'u$i').toSet();

      selectBuilder.result = ids
          .map(
            (id) => <String, dynamic>{
              'id': id,
              'display_name': 'User $id',
              'avatar_url': null,
            },
          )
          .toList();

      final result = await cache.getProfiles(ids);

      // Should make 2 inFilter calls (40 + 10).
      expect(selectBuilder.inFilterCalls, hasLength(2));
      expect(selectBuilder.inFilterCalls[0].value, hasLength(40));
      expect(selectBuilder.inFilterCalls[1].value, hasLength(10));
      expect(result, hasLength(50));
    });

    test('uses single request for IDs within chunk size', () async {
      final ids = List.generate(30, (i) => 'u$i').toSet();

      selectBuilder.result = ids
          .map(
            (id) => <String, dynamic>{
              'id': id,
              'display_name': 'User $id',
              'avatar_url': null,
            },
          )
          .toList();

      final result = await cache.getProfiles(ids);

      expect(selectBuilder.inFilterCalls, hasLength(1));
      expect(result, hasLength(30));
    });
  });

  group('mergeIntoRows', () {
    test('returns empty list for empty rows', () async {
      final result = await cache.mergeIntoRows([]);

      expect(result, isEmpty);
    });

    test('merges profile data as top-level username and avatar_url', () async {
      selectBuilder.result = [
        {
          'id': 'u1',
          'display_name': 'Alice',
          'avatar_url': 'https://a.com/1.jpg',
        },
      ];

      final rows = [
        {'id': 'p1', 'user_id': 'u1', 'content': 'Hello'},
        {'id': 'p2', 'user_id': 'u1', 'content': 'World'},
      ];

      final result = await cache.mergeIntoRows(rows);

      expect(result, hasLength(2));
      expect(result[0]['username'], 'Alice');
      expect(result[0]['avatar_url'], 'https://a.com/1.jpg');
      expect(result[1]['username'], 'Alice');
      expect(result[0]['content'], 'Hello');
    });

    test('passes through rows without matching profile', () async {
      selectBuilder.result = [
        {'id': 'u1', 'display_name': 'Alice', 'avatar_url': null},
      ];

      final rows = [
        {'id': 'p1', 'user_id': 'u1', 'content': 'Found'},
        {'id': 'p2', 'user_id': 'u_unknown', 'content': 'Missing'},
      ];

      final result = await cache.mergeIntoRows(rows);

      expect(result, hasLength(2));
      expect(result[0]['username'], 'Alice');
      expect(result[1].containsKey('username'), isFalse);
      expect(result[1]['content'], 'Missing');
    });

    test('falls back to full_name when display_name is null', () async {
      selectBuilder.result = [
        {
          'id': 'u1',
          'display_name': null,
          'full_name': 'Bekir',
          'avatar_url': null,
        },
      ];

      final rows = [
        {'id': 'p1', 'user_id': 'u1', 'content': 'Hello'},
      ];

      final result = await cache.mergeIntoRows(rows);

      expect(result, hasLength(1));
      expect(result[0]['username'], 'Bekir');
    });

    test('prefers display_name over full_name', () async {
      selectBuilder.result = [
        {
          'id': 'u1',
          'display_name': 'Alice',
          'full_name': 'Alice Smith',
          'avatar_url': null,
        },
      ];

      final rows = [
        {'id': 'p1', 'user_id': 'u1', 'content': 'Hello'},
      ];

      final result = await cache.mergeIntoRows(rows);

      expect(result, hasLength(1));
      expect(result[0]['username'], 'Alice');
    });

    test('falls back to email prefix when both names are null', () async {
      selectBuilder.result = [
        {
          'id': 'u1',
          'display_name': null,
          'full_name': null,
          'email': 'bekir@example.com',
          'avatar_url': null,
        },
      ];

      final rows = [
        {'id': 'p1', 'user_id': 'u1', 'content': 'Hello'},
      ];

      final result = await cache.mergeIntoRows(rows);

      expect(result, hasLength(1));
      expect(result[0]['username'], 'bekir');
    });

    test('handles rows with null user_id', () async {
      selectBuilder.result = [];

      final rows = [
        {'id': 'p1', 'content': 'No user_id'},
      ];

      final result = await cache.mergeIntoRows(rows);

      expect(result, hasLength(1));
      expect(result[0].containsKey('username'), isFalse);
    });
  });

  group('invalidation', () {
    test('invalidate removes specific user from cache', () async {
      selectBuilder.result = [
        {'id': 'u1', 'display_name': 'Alice', 'avatar_url': null},
      ];
      await cache.getProfiles({'u1'});
      expect(selectBuilder.inFilterCalls, hasLength(1));

      cache.invalidate('u1');

      // Next call should re-fetch from Supabase
      selectBuilder.result = [
        {'id': 'u1', 'display_name': 'Alice Updated', 'avatar_url': null},
      ];
      final result = await cache.getProfiles({'u1'});

      expect(selectBuilder.inFilterCalls, hasLength(2));
      expect(result['u1']!['display_name'], 'Alice Updated');
    });

    test('clear removes all entries from cache', () async {
      selectBuilder.result = [
        {'id': 'u1', 'display_name': 'Alice', 'avatar_url': null},
        {'id': 'u2', 'display_name': 'Bob', 'avatar_url': null},
      ];
      await cache.getProfiles({'u1', 'u2'});
      expect(selectBuilder.inFilterCalls, hasLength(1));

      cache.clear();

      // Next call should re-fetch both from Supabase
      selectBuilder.result = [
        {'id': 'u1', 'display_name': 'Alice', 'avatar_url': null},
        {'id': 'u2', 'display_name': 'Bob', 'avatar_url': null},
      ];
      final result = await cache.getProfiles({'u1', 'u2'});

      expect(selectBuilder.inFilterCalls, hasLength(2));
      expect(result, hasLength(2));
    });
  });
}
