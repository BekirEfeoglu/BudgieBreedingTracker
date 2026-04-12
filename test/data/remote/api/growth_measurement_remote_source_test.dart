import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/growth_measurement_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeQueryBuilder queryBuilder;
  late FakeSupabaseClient client;
  late GrowthMeasurementRemoteSource source;

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    queryBuilder = stack.queryBuilder;
    client = stack.client;
    source = GrowthMeasurementRemoteSource(client);
  });

  group('GrowthMeasurementRemoteSource', () {
    test('fetchAll queries table without is_deleted filter', () async {
      selectBuilder.result = [
        {
          'id': 'gm-1',
          'chick_id': 'chick-1',
          'weight': 25.0,
          'measurement_date': '2024-02-01T00:00:00.000',
          'user_id': 'user-1',
        },
      ];

      final result = await source.fetchAll('user-1');

      expect(client.requestedTable, SupabaseConstants.growthMeasurementsTable);
      expect(result, hasLength(1));
      expect(result.single.id, 'gm-1');
      expect(result.single.weight, 25.0);
      final eqKeys = selectBuilder.eqCalls
          .map((entry) => '${entry.key}:${entry.value}')
          .toList();
      expect(eqKeys, contains('user_id:user-1'));
      // NoSoftDelete: no is_deleted filter
      expect(eqKeys, isNot(contains('is_deleted:false')));
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

    test('upsert sends serialized growth measurement payload', () async {
      final measurement = GrowthMeasurement(
        id: 'gm-1',
        chickId: 'chick-1',
        weight: 25.0,
        measurementDate: DateTime(2024, 2, 1),
        userId: 'user-1',
      );

      await source.upsert(measurement);

      final payload = queryBuilder.upsertPayload as Map<String, dynamic>;
      expect(payload['id'], 'gm-1');
      expect(payload['chick_id'], 'chick-1');
      expect(payload['weight'], 25.0);
      expect(payload['user_id'], 'user-1');
    });

    test('converts fetch failures to NetworkException', () async {
      selectBuilder.error = Exception('remote failed');

      expect(() => source.fetchAll('user-1'), throwsA(isA<NetworkException>()));
    });
  });
}
