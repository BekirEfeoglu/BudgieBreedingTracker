import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/photo_enums.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/photo_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeQueryBuilder queryBuilder;
  late FakeSupabaseClient client;
  late PhotoRemoteSource source;

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    queryBuilder = stack.queryBuilder;
    client = stack.client;
    source = PhotoRemoteSource(client);
  });

  group('PhotoRemoteSource', () {
    test('fetchAll queries table without is_deleted filter', () async {
      selectBuilder.result = [
        {
          'id': 'photo-1',
          'user_id': 'user-1',
          'entity_type': 'bird',
          'entity_id': 'bird-1',
          'file_name': 'test.jpg',
        },
      ];

      final result = await source.fetchAll('user-1');

      expect(client.requestedTable, SupabaseConstants.photosTable);
      expect(result, hasLength(1));
      expect(result.single.id, 'photo-1');
      expect(result.single.entityType, PhotoEntityType.bird);
      expect(result.single.fileName, 'test.jpg');
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

      final gtKeys = selectBuilder.gtCalls
          .map((entry) => '${entry.key}:${entry.value}')
          .toList();
      expect(gtKeys, contains('updated_at:${since.toIso8601String()}'));
    });

    test('upsert sends serialized photo payload', () async {
      const photo = Photo(
        id: 'photo-1',
        userId: 'user-1',
        entityType: PhotoEntityType.bird,
        entityId: 'bird-1',
        fileName: 'test.jpg',
      );

      await source.upsert(photo);

      final payload = queryBuilder.upsertPayload as Map<String, dynamic>;
      expect(payload['id'], 'photo-1');
      expect(payload['user_id'], 'user-1');
      expect(payload['entity_type'], 'bird');
      expect(payload['entity_id'], 'bird-1');
      expect(payload['url'], 'test.jpg');
    });

    test('converts fetch failures to NetworkException', () async {
      selectBuilder.error = Exception('remote failed');

      expect(() => source.fetchAll('user-1'), throwsA(isA<NetworkException>()));
    });
  });
}
