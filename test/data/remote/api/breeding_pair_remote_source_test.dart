import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/breeding_pair_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeQueryBuilder queryBuilder;
  late FakeSupabaseClient client;
  late BreedingPairRemoteSource source;

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    queryBuilder = stack.queryBuilder;
    client = stack.client;
    source = BreedingPairRemoteSource(client);
  });

  group('BreedingPairRemoteSource', () {
    test('fetchAll queries and parses breeding pairs', () async {
      selectBuilder.result = [
        {
          'id': 'pair-1',
          'user_id': 'user-1',
          'status': 'active',
          'is_deleted': false,
        },
      ];

      final result = await source.fetchAll('user-1');

      expect(client.requestedTable, SupabaseConstants.breedingPairsTable);
      expect(result, hasLength(1));
      expect(result.single.id, 'pair-1');
      expect(result.single.status, BreedingStatus.active);
      final eqKeys = selectBuilder.eqCalls
          .map((entry) => '${entry.key}:${entry.value}')
          .toList();
      expect(eqKeys, containsAll(['user_id:user-1', 'is_deleted:false']));
      expect(selectBuilder.orderCalls, contains('created_at'));
    });

    test('fetchUpdatedSince applies updated_at gt', () async {
      selectBuilder.result = const [];
      final since = DateTime(2024, 1, 10);

      await source.fetchUpdatedSince('user-1', since);

      final gtKeys = selectBuilder.gtCalls
          .map((entry) => '${entry.key}:${entry.value}')
          .toList();
      expect(gtKeys, contains('updated_at:${since.toIso8601String()}'));
    });

    test('upsert serializes breeding pair payload', () async {
      const pair = BreedingPair(
        id: 'pair-1',
        userId: 'user-1',
        status: BreedingStatus.active,
      );

      await source.upsert(pair);

      final payload = queryBuilder.upsertPayload as Map<String, dynamic>;
      expect(payload['id'], 'pair-1');
      expect(payload['user_id'], 'user-1');
      expect(payload['status'], 'active');
    });

    test('maps remote exceptions to AppException', () async {
      selectBuilder.error = Exception('timeout');

      expect(() => source.fetchAll('user-1'), throwsA(isA<NetworkException>()));
    });
  });
}
