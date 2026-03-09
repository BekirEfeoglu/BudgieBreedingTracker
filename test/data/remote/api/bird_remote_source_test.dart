import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/bird_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeQueryBuilder queryBuilder;
  late FakeSupabaseClient client;
  late BirdRemoteSource source;

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    queryBuilder = stack.queryBuilder;
    client = stack.client;
    source = BirdRemoteSource(client);
  });

  group('BirdRemoteSource', () {
    test('fetchAll queries Supabase and parses birds', () async {
      selectBuilder.result = [
        {
          'id': 'bird-1',
          'name': 'Sky',
          'user_id': 'user-1',
          'gender': 'male',
          'is_deleted': false,
        },
      ];

      final result = await source.fetchAll('user-1');

      expect(client.requestedTable, SupabaseConstants.birdsTable);
      expect(result, hasLength(1));
      expect(result.single.id, 'bird-1');
      expect(result.single.gender, BirdGender.male);
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

    test('upsert sends serialized bird payload', () async {
      const bird = Bird(
        id: 'bird-1',
        name: 'Sky',
        userId: 'user-1',
        gender: BirdGender.male,
      );

      await source.upsert(bird);

      final payload = queryBuilder.upsertPayload as Map<String, dynamic>;
      expect(payload['id'], 'bird-1');
      expect(payload['name'], 'Sky');
      expect(payload['user_id'], 'user-1');
    });

    test('fetchByGender applies gender and active filters', () async {
      selectBuilder.result = const [];

      await source.fetchByGender('user-1', 'female');

      final eqKeys = selectBuilder.eqCalls
          .map((entry) => '${entry.key}:${entry.value}')
          .toList();
      expect(
        eqKeys,
        containsAll(['user_id:user-1', 'gender:female', 'is_deleted:false']),
      );
      expect(selectBuilder.orderCalls, contains('name'));
    });

    test('converts fetch failures to AppException', () async {
      selectBuilder.error = Exception('remote failed');

      expect(() => source.fetchAll('user-1'), throwsA(isA<NetworkException>()));
    });
  });
}
