import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/remote/api/message_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late FakeFilterBuilder<PostgrestList> selectBuilder;
  late FakeQueryBuilder queryBuilder;
  late FakeSupabaseClient client;
  late MessageRemoteSource source;

  setUp(() {
    final stack = createFakeSupabaseStack();
    selectBuilder = stack.selectBuilder;
    queryBuilder = stack.queryBuilder;
    client = stack.client;
    source = MessageRemoteSource(client);
  });

  group('MessageRemoteSource', () {
    test('fetchMessages applies conversation filter and order', () async {
      selectBuilder.result = [
        {'id': 'msg-1', 'conversation_id': 'conv-1', 'content': 'Hello'},
      ];

      final result = await source.fetchMessages('conv-1');

      expect(client.requestedTable, SupabaseConstants.messagesTable);
      expect(result, hasLength(1));
      final eqKeys = selectBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(
        eqKeys,
        containsAll(['conversation_id:conv-1', 'is_deleted:false']),
      );
      expect(selectBuilder.orderCalls, contains('created_at'));
      expect(selectBuilder.limitValue, 50);
    });

    test('fetchMessages applies before filter for pagination', () async {
      selectBuilder.result = [];
      final before = DateTime(2024, 6, 1);

      await source.fetchMessages('conv-1', before: before);

      final ltKeys = selectBuilder.ltCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(ltKeys, contains('created_at:${before.toIso8601String()}'));
    });

    test('fetchMessages respects custom limit', () async {
      selectBuilder.result = [];

      await source.fetchMessages('conv-1', limit: 25);

      expect(selectBuilder.limitValue, 25);
    });

    // insert() uses insert().select().single() chain — skipped due to fake
    // limitation (FakeFilterBuilder doesn't support select() on insert result).

    test('softDelete sets is_deleted and filters by sender_id', () async {
      await source.softDelete('msg-1', userId: 'user-1');

      expect(queryBuilder.updatePayload, {'is_deleted': true});
      final eqKeys = queryBuilder.updateBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, containsAll(['id:msg-1', 'sender_id:user-1']));
    });

    test('rethrows on fetch error', () {
      selectBuilder.error = Exception('network error');

      expect(
        () => source.fetchMessages('conv-1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
