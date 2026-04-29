import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/profile_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeQueryBuilder queryBuilder;
  late FakeSupabaseClient client;
  late ProfileRemoteSource source;

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    queryBuilder = stack.queryBuilder;
    client = stack.client;
    source = ProfileRemoteSource(client);
  });

  group('ProfileRemoteSource', () {
    test('fetchAll delegates to fetchById and returns profile list', () async {
      selectBuilder.singleResult = {'id': 'user-1', 'email': 'test@test.com'};

      final result = await source.fetchAll('user-1');

      expect(client.requestedTable, SupabaseConstants.profilesTable);
      expect(result, hasLength(1));
      expect(result.single.id, 'user-1');
      expect(result.single.email, 'test@test.com');
      final eqKeys = selectBuilder.eqCalls
          .map((entry) => '${entry.key}:${entry.value}')
          .toList();
      expect(eqKeys, contains('id:user-1'));
    });

    test('fetchAll returns empty list when profile not found', () async {
      selectBuilder.singleResult = null;

      final result = await source.fetchAll('user-1');

      expect(result, isEmpty);
    });

    test('fetchUpdatedSince applies updated_at filter', () async {
      selectBuilder.result = const [];
      final since = DateTime(2024, 1, 10);

      await source.fetchUpdatedSince('user-1', since);

      final gtKeys = selectBuilder.gtCalls
          .map((entry) => '${entry.key}:${entry.value}')
          .toList();
      expect(gtKeys, contains('updated_at:${since.toIso8601String()}'));
    });

    test('upsert sends serialized profile payload', () async {
      const profile = Profile(id: 'user-1', email: 'test@test.com');

      await source.upsert(profile);

      final payload = queryBuilder.upsertPayload as Map<String, dynamic>;
      expect(payload['id'], 'user-1');
      expect(payload['email'], 'test@test.com');
    });

    test('converts fetch failures to NetworkException', () async {
      selectBuilder.error = Exception('remote failed');

      expect(() => source.fetchAll('user-1'), throwsA(isA<NetworkException>()));
    });
  });
}
