import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/egg_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeQueryBuilder queryBuilder;
  late FakeSupabaseClient client;
  late EggRemoteSource source;

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    queryBuilder = stack.queryBuilder;
    client = stack.client;
    source = EggRemoteSource(client);
  });

  group('EggRemoteSource', () {
    test('fetchAll queries Supabase and parses eggs', () async {
      selectBuilder.result = [
        {
          'id': 'egg-1',
          'user_id': 'user-1',
          'lay_date': '2024-01-10T00:00:00.000',
          'status': 'laid',
          'is_deleted': false,
        },
      ];

      final result = await source.fetchAll('user-1');

      expect(client.requestedTable, SupabaseConstants.eggsTable);
      expect(result, hasLength(1));
      expect(result.single.id, 'egg-1');
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

      final gtKeys = selectBuilder.gtCalls
          .map((entry) => '${entry.key}:${entry.value}')
          .toList();
      expect(gtKeys, contains('updated_at:${since.toIso8601String()}'));
    });

    test('upsert sends serialized egg payload', () async {
      final egg = Egg(
        id: 'egg-1',
        userId: 'user-1',
        layDate: DateTime(2024, 1, 10),
      );

      await source.upsert(egg);

      final payload = queryBuilder.upsertPayload as Map<String, dynamic>;
      expect(payload['id'], 'egg-1');
      expect(payload['user_id'], 'user-1');
      expect(payload['lay_date'], isNotNull);
    });

    test('converts fetch failures to AppException', () async {
      selectBuilder.error = Exception('remote failed');

      expect(() => source.fetchAll('user-1'), throwsA(isA<NetworkException>()));
    });
  });
}
