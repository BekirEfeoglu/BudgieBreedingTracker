import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/models/notification_schedule_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/notification_schedule_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeQueryBuilder queryBuilder;
  late FakeSupabaseClient client;
  late NotificationScheduleRemoteSource source;

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    queryBuilder = stack.queryBuilder;
    client = stack.client;
    source = NotificationScheduleRemoteSource(client);
  });

  group('NotificationScheduleRemoteSource', () {
    test('fetchAll queries table without is_deleted filter', () async {
      selectBuilder.result = [
        {
          'id': 'sched-1',
          'user_id': 'user-1',
          'type': 'eggTurning',
          'title': 'Egg Turn',
          'scheduled_at': '2024-03-01T00:00:00.000',
          'is_active': true,
        },
      ];

      final result = await source.fetchAll('user-1');

      expect(
        client.requestedTable,
        SupabaseConstants.notificationSchedulesTable,
      );
      expect(result, hasLength(1));
      expect(result.single.id, 'sched-1');
      expect(result.single.type, NotificationType.eggTurning);
      expect(result.single.title, 'Egg Turn');
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

    test('upsert sends serialized notification schedule payload', () async {
      final schedule = NotificationSchedule(
        id: 'sched-1',
        userId: 'user-1',
        type: NotificationType.eggTurning,
        title: 'Egg Turn',
        scheduledAt: DateTime(2024, 3, 1),
      );

      await source.upsert(schedule);

      final payload = queryBuilder.upsertPayload as Map<String, dynamic>;
      expect(payload['id'], 'sched-1');
      expect(payload['user_id'], 'user-1');
      expect(payload['type'], 'eggTurning');
      expect(payload['title'], 'Egg Turn');
    });

    test('converts fetch failures to NetworkException', () async {
      selectBuilder.error = Exception('remote failed');

      expect(() => source.fetchAll('user-1'), throwsA(isA<NetworkException>()));
    });
  });
}
