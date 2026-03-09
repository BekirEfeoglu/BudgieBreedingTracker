import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/incubation_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeQueryBuilder queryBuilder;
  late FakeSupabaseClient client;
  late IncubationRemoteSource source;

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    queryBuilder = stack.queryBuilder;
    client = stack.client;
    source = IncubationRemoteSource(client);
  });

  group('IncubationRemoteSource', () {
    test('fetchAll queries table without is_deleted filter', () async {
      selectBuilder.result = [
        {'id': 'inc-1', 'user_id': 'user-1', 'status': 'active'},
      ];

      final result = await source.fetchAll('user-1');

      expect(client.requestedTable, SupabaseConstants.incubationsTable);
      expect(result, hasLength(1));
      expect(result.single.id, 'inc-1');
      expect(result.single.status, IncubationStatus.active);
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

    test('upsert sends serialized incubation payload', () async {
      const incubation = Incubation(
        id: 'inc-1',
        userId: 'user-1',
        status: IncubationStatus.active,
      );

      await source.upsert(incubation);

      final payload = queryBuilder.upsertPayload as Map<String, dynamic>;
      expect(payload['id'], 'inc-1');
      expect(payload['user_id'], 'user-1');
      expect(payload['status'], 'active');
    });

    test('converts fetch failures to NetworkException', () async {
      selectBuilder.error = Exception('remote failed');

      expect(() => source.fetchAll('user-1'), throwsA(isA<NetworkException>()));
    });
  });
}
