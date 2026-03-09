import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/notification_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeQueryBuilder queryBuilder;
  late FakeSupabaseClient client;
  late NotificationRemoteSource source;

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    queryBuilder = stack.queryBuilder;
    client = stack.client;
    source = NotificationRemoteSource(client);
  });

  group('NotificationRemoteSource', () {
    test('fetchAll queries table without is_deleted filter', () async {
      selectBuilder.result = [
        {'id': 'notif-1', 'title': 'Test', 'user_id': 'user-1'},
      ];

      final result = await source.fetchAll('user-1');

      expect(client.requestedTable, SupabaseConstants.notificationsTable);
      expect(result, hasLength(1));
      expect(result.single.id, 'notif-1');
      expect(result.single.title, 'Test');
      final eqKeys = selectBuilder.eqCalls
          .map((entry) => '${entry.key}:${entry.value}')
          .toList();
      expect(eqKeys, contains('user_id:user-1'));
      // NotificationRemoteSource overrides fetchAll: no is_deleted filter
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

    test('upsert sends serialized notification payload', () async {
      const notification = AppNotification(
        id: 'notif-1',
        title: 'Test',
        userId: 'user-1',
      );

      await source.upsert(notification);

      final payload = queryBuilder.upsertPayload as Map<String, dynamic>;
      expect(payload['id'], 'notif-1');
      expect(payload['title'], 'Test');
      expect(payload['user_id'], 'user-1');
    });

    test('fetchUpdatedSince converts failures to NetworkException', () async {
      selectBuilder.error = Exception('remote failed');

      expect(
        () => source.fetchUpdatedSince('user-1', DateTime(2024)),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
