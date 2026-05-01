import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/remote/api/conversation_remote_source.dart';

import '../../../helpers/fake_supabase.dart';

void main() {
  late RoutingFakeClient client;
  late ConversationRemoteSource source;

  late FakeFilterBuilder<PostgrestList> participantsSelect;
  late FakeFilterBuilder<PostgrestList> conversationsSelect;
  late FakeQueryBuilder participantsQuery;
  late FakeQueryBuilder conversationsQuery;

  setUp(() {
    client = RoutingFakeClient();

    final participants = client.addTable(
      SupabaseConstants.conversationParticipantsTable,
    );
    participantsSelect = participants.selectBuilder;
    participantsQuery = participants.queryBuilder;

    final conversations = client.addTable(SupabaseConstants.conversationsTable);
    conversationsSelect = conversations.selectBuilder;
    conversationsQuery = conversations.queryBuilder;

    source = ConversationRemoteSource(client);
  });

  group('ConversationRemoteSource', () {
    test('fetchConversations returns empty when no participant rows', () async {
      participantsSelect.result = [];

      final result = await source.fetchConversations('user-1');

      expect(result, isEmpty);
    });

    test('fetchById applies id filter', () async {
      conversationsSelect.singleResult = {'id': 'conv-1', 'type': 'direct'};

      final result = await source.fetchById('conv-1');

      expect(result, isNotNull);
      expect(result!['id'], 'conv-1');
      final eqKeys = conversationsSelect.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, contains('id:conv-1'));
    });

    // create() uses insert().select().single() which requires FakeFilterBuilder
    // to support select() on the insert result — skipped due to fake limitation.
    // The insert payload is validated in integration tests.

    test('update sends data with id filter', () async {
      await source.update('conv-1', {'name': 'Updated Group'});

      final payload = conversationsQuery.updatePayload as Map<String, dynamic>;
      expect(payload['name'], 'Updated Group');
      final eqKeys = conversationsQuery.updateBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, contains('id:conv-1'));
    });

    test('fetchParticipants filters by conversation_id and is_left', () async {
      participantsSelect.result = [
        {'user_id': 'user-1', 'conversation_id': 'conv-1'},
      ];

      final result = await source.fetchParticipants('conv-1');

      expect(result, hasLength(1));
      final eqKeys = participantsSelect.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, containsAll(['conversation_id:conv-1', 'is_left:false']));
    });

    test('addParticipant inserts participant data', () async {
      final data = {
        'conversation_id': 'conv-1',
        'user_id': 'user-2',
        'role': 'member',
      };

      await source.addParticipant(data);

      expect(participantsQuery.upsertPayload, data);
    });

    test('updateParticipant applies correct filters', () async {
      await source.updateParticipant('conv-1', 'user-1', {'is_left': true});

      final payload = participantsQuery.updatePayload as Map<String, dynamic>;
      expect(payload['is_left'], true);
      final eqKeys = participantsQuery.updateBuilder.eqCalls
          .map((e) => '${e.key}:${e.value}')
          .toList();
      expect(eqKeys, containsAll(['conversation_id:conv-1', 'user_id:user-1']));
    });

    test(
      'findDirectConversation checks all shared participant conversations',
      () async {
        participantsSelect.resultQueue.addAll([
          [
            {'conversation_id': 'conv-a'},
            {'conversation_id': 'conv-b'},
          ],
          [
            {'conversation_id': 'conv-b'},
          ],
        ]);
        conversationsSelect.singleResult = {'id': 'conv-b', 'type': 'direct'};

        final result = await source.findDirectConversation('user-1', 'user-2');

        expect(result, isNotNull);
        expect(result!['id'], 'conv-b');
        final eqKeys = participantsSelect.eqCalls
            .map((e) => '${e.key}:${e.value}')
            .toList();
        expect(eqKeys, containsAll(['user_id:user-1', 'user_id:user-2']));
        expect(participantsSelect.inFilterCalls.single.value, [
          'conv-a',
          'conv-b',
        ]);
        expect(conversationsSelect.inFilterCalls.single.value, ['conv-b']);
      },
    );

    test('rethrows on error', () {
      participantsSelect.error = Exception('network error');

      expect(
        () => source.fetchConversations('user-1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
