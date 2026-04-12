import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/chick_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeQueryBuilder queryBuilder;
  late FakeSupabaseClient client;
  late ChickRemoteSource source;

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    queryBuilder = stack.queryBuilder;
    client = stack.client;
    source = ChickRemoteSource(client);
  });

  group('ChickRemoteSource', () {
    test('fetchAll queries and parses chick rows', () async {
      selectBuilder.result = [
        {
          'id': 'chick-1',
          'user_id': 'user-1',
          'gender': 'unknown',
          'health_status': 'healthy',
          'is_deleted': false,
        },
      ];

      final result = await source.fetchAll('user-1');

      expect(client.requestedTable, SupabaseConstants.chicksTable);
      expect(result, hasLength(1));
      expect(result.single.id, 'chick-1');
      final eqKeys = selectBuilder.eqCalls
          .map((entry) => '${entry.key}:${entry.value}')
          .toList();
      expect(eqKeys, containsAll(['user_id:user-1', 'is_deleted:false']));
      expect(selectBuilder.orderCalls, contains('created_at'));
    });

    test('fetchUpdatedSince applies updated_at filter', () async {
      selectBuilder.result = const [];
      final since = DateTime(2024, 1, 10);

      await source.fetchUpdatedSince('user-1', since);

      final gteKeys = selectBuilder.gteCalls
          .map((entry) => '${entry.key}:${entry.value}')
          .toList();
      expect(gteKeys, contains('updated_at:${since.toIso8601String()}'));
    });

    test('upsert serializes chick payload', () async {
      const chick = Chick(id: 'chick-1', userId: 'user-1');

      await source.upsert(chick);

      final payload = queryBuilder.upsertPayload as Map<String, dynamic>;
      expect(payload['id'], 'chick-1');
      expect(payload['user_id'], 'user-1');
    });

    test('maps unexpected failures to AppException', () async {
      selectBuilder.error = Exception('service unavailable');

      expect(() => source.fetchAll('user-1'), throwsA(isA<NetworkException>()));
    });
  });
}
