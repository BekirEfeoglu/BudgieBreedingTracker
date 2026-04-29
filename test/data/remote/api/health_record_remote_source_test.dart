import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/health_record_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeQueryBuilder queryBuilder;
  late FakeSupabaseClient client;
  late HealthRecordRemoteSource source;

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    queryBuilder = stack.queryBuilder;
    client = stack.client;
    source = HealthRecordRemoteSource(client);
  });

  group('HealthRecordRemoteSource', () {
    test('fetchAll queries table and parses health records', () async {
      selectBuilder.result = [
        {
          'id': 'hr-1',
          'date': '2024-02-01T00:00:00.000',
          'type': 'checkup',
          'title': 'Annual Check',
          'user_id': 'user-1',
          'is_deleted': false,
        },
      ];

      final result = await source.fetchAll('user-1');

      expect(client.requestedTable, SupabaseConstants.healthRecordsTable);
      expect(result, hasLength(1));
      expect(result.single.id, 'hr-1');
      expect(result.single.type, HealthRecordType.checkup);
      expect(result.single.title, 'Annual Check');
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

    test('upsert sends serialized health record payload', () async {
      final record = HealthRecord(
        id: 'hr-1',
        date: DateTime(2024, 2, 1),
        type: HealthRecordType.checkup,
        title: 'Annual Check',
        userId: 'user-1',
      );

      await source.upsert(record);

      final payload = queryBuilder.upsertPayload as Map<String, dynamic>;
      expect(payload['id'], 'hr-1');
      expect(payload['title'], 'Annual Check');
      expect(payload['type'], 'checkup');
      expect(payload['user_id'], 'user-1');
    });

    test('converts fetch failures to NetworkException', () async {
      selectBuilder.error = Exception('remote failed');

      expect(() => source.fetchAll('user-1'), throwsA(isA<NetworkException>()));
    });
  });
}
