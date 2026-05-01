import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/event_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeQueryBuilder queryBuilder;
  late FakeSupabaseClient client;
  late EventRemoteSource source;

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    queryBuilder = stack.queryBuilder;
    client = stack.client;
    source = EventRemoteSource(client);
  });

  group('EventRemoteSource', () {
    test('fetchAll queries table and parses events', () async {
      selectBuilder.result = [
        {
          'id': 'evt-1',
          'title': 'Check',
          'event_date': '2024-03-01T00:00:00.000',
          'type': 'healthCheck',
          'user_id': 'user-1',
          'is_deleted': false,
        },
      ];

      final result = await source.fetchAll('user-1');

      expect(client.requestedTable, SupabaseConstants.eventsTable);
      expect(result, hasLength(1));
      expect(result.single.id, 'evt-1');
      expect(result.single.type, EventType.healthCheck);
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

    test('upsert sends serialized event payload', () async {
      final event = Event(
        id: 'evt-1',
        title: 'Check',
        eventDate: DateTime(2024, 3, 1),
        type: EventType.healthCheck,
        userId: 'user-1',
      );

      await source.upsert(event);

      final payload = queryBuilder.upsertPayload as Map<String, dynamic>;
      expect(payload['id'], 'evt-1');
      expect(payload['title'], 'Check');
      expect(payload['user_id'], 'user-1');
      expect(payload['type'], 'healthCheck');
    });

    test('converts fetch failures to NetworkException', () async {
      selectBuilder.error = Exception('remote failed');

      expect(() => source.fetchAll('user-1'), throwsA(isA<NetworkException>()));
    });
  });
}
