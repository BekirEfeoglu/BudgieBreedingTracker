import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/clutch_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeQueryBuilder queryBuilder;
  late FakeSupabaseClient client;
  late ClutchRemoteSource source;

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    queryBuilder = stack.queryBuilder;
    client = stack.client;
    source = ClutchRemoteSource(client);
  });

  group('ClutchRemoteSource', () {
    test('fetchAll queries table and parses clutches', () async {
      selectBuilder.result = [
        {'id': 'clutch-1', 'user_id': 'user-1', 'is_deleted': false},
      ];

      final result = await source.fetchAll('user-1');

      expect(client.requestedTable, SupabaseConstants.clutchesTable);
      expect(result, hasLength(1));
      expect(result.single.id, 'clutch-1');
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

    test('upsert sends serialized clutch payload', () async {
      const clutch = Clutch(id: 'clutch-1', userId: 'user-1');

      await source.upsert(clutch);

      final payload = queryBuilder.upsertPayload as Map<String, dynamic>;
      expect(payload['id'], 'clutch-1');
      expect(payload['user_id'], 'user-1');
    });

    test('converts fetch failures to NetworkException', () async {
      selectBuilder.error = Exception('remote failed');

      expect(() => source.fetchAll('user-1'), throwsA(isA<NetworkException>()));
    });
  });
}
