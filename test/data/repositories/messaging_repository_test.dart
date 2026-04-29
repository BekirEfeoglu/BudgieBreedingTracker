@Tags(['messaging'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/models/conversation_model.dart';
import 'package:budgie_breeding_tracker/data/models/conversation_participant_model.dart';
import 'package:budgie_breeding_tracker/data/models/message_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/conversation_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/message_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/messaging_repository.dart';

import '../../helpers/fake_supabase.dart';

class MockConversationRemoteSource extends Mock
    implements ConversationRemoteSource {}

class MockMessageRemoteSource extends Mock implements MessageRemoteSource {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

// ── Test Data Helpers ──

Map<String, dynamic> _makeConversationRow({
  required String id,
  String type = 'direct',
  String? name,
  String creatorId = 'u1',
  String? lastMessageContent,
  int participantCount = 2,
}) => {
  'id': id,
  'type': type,
  'name': name,
  'image_url': null,
  'creator_id': creatorId,
  'last_message_content': lastMessageContent,
  'last_message_at': '2026-04-01T10:00:00Z',
  'last_message_user_id': creatorId,
  'participant_count': participantCount,
  'is_deleted': false,
  'created_at': '2026-03-15T10:00:00Z',
  'updated_at': '2026-03-15T10:00:00Z',
};

Map<String, dynamic> _makeMessageRow({
  required String id,
  String conversationId = 'conv-1',
  String senderId = 'u1',
  String senderName = 'TestUser',
  String? content = 'Hello',
  String messageType = 'text',
}) => {
  'id': id,
  'conversation_id': conversationId,
  'sender_id': senderId,
  'sender_name': senderName,
  'sender_avatar_url': null,
  'content': content,
  'message_type': messageType,
  'image_url': null,
  'reference_id': null,
  'reference_data': <String, dynamic>{},
  'read_by': <String>[],
  'is_deleted': false,
  'created_at': '2026-04-01T10:00:00Z',
};

Map<String, dynamic> _makeParticipantRow({
  required String conversationId,
  required String userId,
  String role = 'member',
}) => {
  'conversation_id': conversationId,
  'user_id': userId,
  'role': role,
  'joined_at': '2026-03-15T10:00:00Z',
  'last_read_at': null,
  'is_muted': false,
  'is_left': false,
};

void main() {
  late MockConversationRemoteSource conversationSource;
  late MockMessageRemoteSource messageSource;
  late MockSupabaseClient client;
  late MessagingRepository repository;

  setUp(() {
    conversationSource = MockConversationRemoteSource();
    messageSource = MockMessageRemoteSource();
    client = MockSupabaseClient();

    repository = MessagingRepository(
      conversationSource: conversationSource,
      messageSource: messageSource,
      client: client,
    );

    registerFallbackValue(<String, dynamic>{});
  });

  // ── getConversations ──

  group('getConversations', () {
    test('returns parsed conversations from remote source', () async {
      when(() => conversationSource.fetchConversations('u1')).thenAnswer(
        (_) async => [
          _makeConversationRow(id: 'c1', name: 'Chat 1'),
          _makeConversationRow(id: 'c2', type: 'group', name: 'Group'),
        ],
      );

      final result = await repository.getConversations('u1');

      expect(result, hasLength(2));
      expect(result[0], isA<Conversation>());
      expect(result[0].id, 'c1');
      expect(result[1].id, 'c2');
      expect(result[1].type.name, 'group');
      verify(() => conversationSource.fetchConversations('u1')).called(1);
    });

    test('returns empty list when no conversations', () async {
      when(
        () => conversationSource.fetchConversations('u1'),
      ).thenAnswer((_) async => []);

      final result = await repository.getConversations('u1');

      expect(result, isEmpty);
    });

    test('rethrows on remote source failure', () async {
      when(
        () => conversationSource.fetchConversations(any()),
      ).thenThrow(Exception('Network error'));

      expect(
        () => repository.getConversations('u1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── getConversationById ──

  group('getConversationById', () {
    test('returns conversation when found', () async {
      when(() => conversationSource.fetchById('c1')).thenAnswer(
        (_) async => _makeConversationRow(id: 'c1', name: 'Test Chat'),
      );

      final result = await repository.getConversationById('c1');

      expect(result, isNotNull);
      expect(result!.id, 'c1');
    });

    test('returns null when not found', () async {
      when(
        () => conversationSource.fetchById('missing'),
      ).thenAnswer((_) async => null);

      final result = await repository.getConversationById('missing');

      expect(result, isNull);
    });
  });

  // ── getOrCreateDirectConversation ──

  group('getOrCreateDirectConversation', () {
    test('returns existing conversation id when found', () async {
      when(
        () => conversationSource.findDirectConversation('u1', 'u2'),
      ).thenAnswer((_) async => {'id': 'existing-conv'});

      final result = await repository.getOrCreateDirectConversation(
        userId1: 'u1',
        userId2: 'u2',
      );

      expect(result, 'existing-conv');
      verifyNever(() => conversationSource.create(any()));
    });

    test('creates new conversation when none exists', () async {
      when(
        () => conversationSource.findDirectConversation('u1', 'u2'),
      ).thenAnswer((_) async => null);
      when(
        () => conversationSource.create(any()),
      ).thenAnswer((_) async => <String, dynamic>{});
      when(
        () => conversationSource.addParticipant(any()),
      ).thenAnswer((_) async {});

      final result = await repository.getOrCreateDirectConversation(
        userId1: 'u1',
        userId2: 'u2',
      );

      expect(result, isNotEmpty);
      verify(() => conversationSource.create(any())).called(1);
      // Both participants added
      verify(() => conversationSource.addParticipant(any())).called(2);
    });

    test('creates conversation with correct type and creator', () async {
      when(
        () => conversationSource.findDirectConversation('u1', 'u2'),
      ).thenAnswer((_) async => null);

      Map<String, dynamic>? capturedData;
      when(() => conversationSource.create(any())).thenAnswer((inv) async {
        capturedData = inv.positionalArguments[0] as Map<String, dynamic>;
        return <String, dynamic>{};
      });
      when(
        () => conversationSource.addParticipant(any()),
      ).thenAnswer((_) async {});

      await repository.getOrCreateDirectConversation(
        userId1: 'u1',
        userId2: 'u2',
      );

      expect(capturedData?['type'], 'direct');
      expect(capturedData?['creator_id'], 'u1');
    });

    test('retries find on create race condition', () async {
      when(
        () => conversationSource.findDirectConversation('u1', 'u2'),
      ).thenAnswer((_) async => null);
      when(
        () => conversationSource.create(any()),
      ).thenThrow(Exception('Unique constraint'));

      // On retry after exception, the conversation is found
      var callCount = 0;
      when(
        () => conversationSource.findDirectConversation('u1', 'u2'),
      ).thenAnswer((_) async {
        callCount++;
        if (callCount <= 1) return null;
        return {'id': 'race-conv'};
      });

      final result = await repository.getOrCreateDirectConversation(
        userId1: 'u1',
        userId2: 'u2',
      );

      expect(result, 'race-conv');
    });

    test('rethrows when create fails and retry find returns null', () async {
      when(
        () => conversationSource.findDirectConversation('u1', 'u2'),
      ).thenAnswer((_) async => null);
      when(
        () => conversationSource.create(any()),
      ).thenThrow(Exception('DB error'));

      expect(
        () => repository.getOrCreateDirectConversation(
          userId1: 'u1',
          userId2: 'u2',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── createGroupConversation ──

  group('createGroupConversation', () {
    test('creates group with owner and members', () async {
      when(
        () => conversationSource.create(any()),
      ).thenAnswer((_) async => <String, dynamic>{});
      when(
        () => conversationSource.addParticipant(any()),
      ).thenAnswer((_) async {});

      final result = await repository.createGroupConversation(
        creatorId: 'u1',
        name: 'Bird Lovers',
        participantIds: ['u1', 'u2', 'u3'],
      );

      expect(result, isNotEmpty);
      verify(() => conversationSource.create(any())).called(1);
      // u1 (owner) + u2, u3 (members) = 3 participants
      verify(() => conversationSource.addParticipant(any())).called(3);
    });

    test('creates group with correct metadata', () async {
      Map<String, dynamic>? capturedData;
      when(() => conversationSource.create(any())).thenAnswer((inv) async {
        capturedData = inv.positionalArguments[0] as Map<String, dynamic>;
        return <String, dynamic>{};
      });
      when(
        () => conversationSource.addParticipant(any()),
      ).thenAnswer((_) async {});

      await repository.createGroupConversation(
        creatorId: 'u1',
        name: 'Bird Lovers',
        participantIds: ['u2'],
        imageUrl: 'https://example.com/img.png',
      );

      expect(capturedData?['type'], 'group');
      expect(capturedData?['name'], 'Bird Lovers');
      expect(capturedData?['creator_id'], 'u1');
      expect(capturedData?['image_url'], 'https://example.com/img.png');
    });

    test('skips creator in participant list to avoid duplicate', () async {
      final participantCalls = <Map<String, dynamic>>[];
      when(
        () => conversationSource.create(any()),
      ).thenAnswer((_) async => <String, dynamic>{});
      when(() => conversationSource.addParticipant(any())).thenAnswer((inv) {
        participantCalls.add(
          inv.positionalArguments[0] as Map<String, dynamic>,
        );
        return Future.value();
      });

      await repository.createGroupConversation(
        creatorId: 'u1',
        name: 'Test',
        participantIds: ['u1', 'u2'],
      );

      // Creator added once as owner, u2 as member — u1 not duplicated
      final roles = participantCalls.map((p) => p['role']).toList();
      expect(roles, contains('owner'));
      expect(roles.where((r) => r == 'owner'), hasLength(1));
      expect(participantCalls, hasLength(2));
    });
  });

  // ── getMessages ──

  group('getMessages', () {
    test('returns parsed messages', () async {
      when(
        () => messageSource.fetchMessages('conv-1', limit: 50, before: null),
      ).thenAnswer(
        (_) async => [
          _makeMessageRow(id: 'm1', content: 'Hi'),
          _makeMessageRow(id: 'm2', content: 'Hello'),
        ],
      );

      final result = await repository.getMessages('conv-1');

      expect(result, hasLength(2));
      expect(result[0], isA<Message>());
      expect(result[0].id, 'm1');
      expect(result[0].content, 'Hi');
      expect(result[1].id, 'm2');
    });

    test('passes limit and before parameters', () async {
      final before = DateTime(2026, 4, 1);
      when(
        () => messageSource.fetchMessages('conv-1', limit: 10, before: before),
      ).thenAnswer((_) async => []);

      await repository.getMessages('conv-1', limit: 10, before: before);

      verify(
        () => messageSource.fetchMessages('conv-1', limit: 10, before: before),
      ).called(1);
    });

    test('returns empty list when no messages', () async {
      when(
        () => messageSource.fetchMessages('conv-1', limit: 50, before: null),
      ).thenAnswer((_) async => []);

      final result = await repository.getMessages('conv-1');

      expect(result, isEmpty);
    });
  });

  // ── sendMessage ──

  group('sendMessage', () {
    test('inserts and returns parsed message', () async {
      final data = {
        'id': 'm1',
        'conversation_id': 'conv-1',
        'sender_id': 'u1',
        'content': 'Test message',
      };
      when(() => messageSource.insert(data)).thenAnswer(
        (_) async => _makeMessageRow(id: 'm1', content: 'Test message'),
      );

      final result = await repository.sendMessage(data);

      expect(result, isA<Message>());
      expect(result.id, 'm1');
      expect(result.content, 'Test message');
      verify(() => messageSource.insert(data)).called(1);
    });

    test('rethrows on insert failure', () async {
      when(
        () => messageSource.insert(any()),
      ).thenThrow(Exception('Insert failed'));

      expect(
        () => repository.sendMessage({'content': 'x'}),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── markAsRead ──

  group('markAsRead', () {
    test('delegates to message source', () async {
      when(() => messageSource.markAsRead('m1', 'u1')).thenAnswer((_) async {});

      await repository.markAsRead('m1', 'u1');

      verify(() => messageSource.markAsRead('m1', 'u1')).called(1);
    });
  });

  // ── deleteMessage ──

  group('deleteMessage', () {
    test('delegates soft delete to message source', () async {
      when(
        () => messageSource.softDelete('m1', userId: 'u1'),
      ).thenAnswer((_) async {});

      await repository.deleteMessage('m1', userId: 'u1');

      verify(() => messageSource.softDelete('m1', userId: 'u1')).called(1);
    });
  });

  // ── getParticipants ──

  group('getParticipants', () {
    test('returns parsed participants', () async {
      when(() => conversationSource.fetchParticipants('conv-1')).thenAnswer(
        (_) async => [
          _makeParticipantRow(
            conversationId: 'conv-1',
            userId: 'u1',
            role: 'owner',
          ),
          _makeParticipantRow(conversationId: 'conv-1', userId: 'u2'),
        ],
      );

      final result = await repository.getParticipants('conv-1');

      expect(result, hasLength(2));
      expect(result[0], isA<ConversationParticipant>());
      expect(result[0].userId, 'u1');
      expect(result[0].role.name, 'owner');
      expect(result[1].userId, 'u2');
      expect(result[1].role.name, 'member');
    });

    test('returns empty list when no participants', () async {
      when(
        () => conversationSource.fetchParticipants('conv-1'),
      ).thenAnswer((_) async => []);

      final result = await repository.getParticipants('conv-1');

      expect(result, isEmpty);
    });
  });

  // ── addParticipant ──

  group('addParticipant', () {
    test('adds participant with default role', () async {
      when(
        () => conversationSource.addParticipant(any()),
      ).thenAnswer((_) async {});

      await repository.addParticipant('conv-1', 'u3');

      final captured =
          verify(
                () => conversationSource.addParticipant(captureAny()),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['conversation_id'], 'conv-1');
      expect(captured['user_id'], 'u3');
      expect(captured['role'], 'member');
    });

    test('adds participant with custom role', () async {
      when(
        () => conversationSource.addParticipant(any()),
      ).thenAnswer((_) async {});

      await repository.addParticipant('conv-1', 'u3', role: 'admin');

      final captured =
          verify(
                () => conversationSource.addParticipant(captureAny()),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['role'], 'admin');
    });
  });

  // ── leaveConversation ──

  group('leaveConversation', () {
    test('updates participant with is_left true', () async {
      when(
        () => conversationSource.updateParticipant('conv-1', 'u1', any()),
      ).thenAnswer((_) async {});

      await repository.leaveConversation('conv-1', 'u1');

      final captured =
          verify(
                () => conversationSource.updateParticipant(
                  'conv-1',
                  'u1',
                  captureAny(),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['is_left'], isTrue);
    });
  });

  // ── updateParticipantRole ──

  group('updateParticipantRole', () {
    test('updates participant role', () async {
      when(
        () => conversationSource.updateParticipant('conv-1', 'u2', any()),
      ).thenAnswer((_) async {});

      await repository.updateParticipantRole('conv-1', 'u2', 'admin');

      final captured =
          verify(
                () => conversationSource.updateParticipant(
                  'conv-1',
                  'u2',
                  captureAny(),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['role'], 'admin');
    });
  });

  // ── muteConversation ──

  group('muteConversation', () {
    test('mutes conversation for user', () async {
      when(
        () => conversationSource.updateParticipant('conv-1', 'u1', any()),
      ).thenAnswer((_) async {});

      await repository.muteConversation('conv-1', 'u1', muted: true);

      final captured =
          verify(
                () => conversationSource.updateParticipant(
                  'conv-1',
                  'u1',
                  captureAny(),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['is_muted'], isTrue);
    });

    test('unmutes conversation for user', () async {
      when(
        () => conversationSource.updateParticipant('conv-1', 'u1', any()),
      ).thenAnswer((_) async {});

      await repository.muteConversation('conv-1', 'u1', muted: false);

      final captured =
          verify(
                () => conversationSource.updateParticipant(
                  'conv-1',
                  'u1',
                  captureAny(),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['is_muted'], isFalse);
    });
  });

  // ── subscribeToMessages ──

  group('subscribeToMessages', () {
    test('delegates to message source and parses callback payload', () async {
      late void Function(Map<String, dynamic>) capturedCallback;
      final mockChannel = MockRealtimeChannel();

      when(
        () => messageSource.isConversationParticipant('conv-1', 'u1'),
      ).thenAnswer((_) async => true);
      when(() => messageSource.subscribeToMessages('conv-1', any())).thenAnswer(
        (inv) {
          capturedCallback =
              inv.positionalArguments[1] as void Function(Map<String, dynamic>);
          return mockChannel;
        },
      );

      Message? receivedMessage;
      final channel = await repository.subscribeToMessages('conv-1', 'u1', (
        msg,
      ) {
        receivedMessage = msg;
      });

      expect(channel, mockChannel);

      // Simulate incoming message payload
      capturedCallback(_makeMessageRow(id: 'm-new', content: 'New!'));

      expect(receivedMessage, isNotNull);
      expect(receivedMessage!.id, 'm-new');
      expect(receivedMessage!.content, 'New!');
    });

    test('handles malformed payload gracefully', () async {
      late void Function(Map<String, dynamic>) capturedCallback;
      final mockChannel = MockRealtimeChannel();

      when(
        () => messageSource.isConversationParticipant('conv-1', 'u1'),
      ).thenAnswer((_) async => true);
      when(() => messageSource.subscribeToMessages('conv-1', any())).thenAnswer(
        (inv) {
          capturedCallback =
              inv.positionalArguments[1] as void Function(Map<String, dynamic>);
          return mockChannel;
        },
      );

      Message? receivedMessage;
      await repository.subscribeToMessages('conv-1', 'u1', (msg) {
        receivedMessage = msg;
      });

      // Malformed payload — missing required fields
      capturedCallback({'invalid': 'data'});

      // Should not crash, message stays null (error caught internally)
      expect(receivedMessage, isNull);
    });
  });

  // ── subscribeToConversationUpdates ──

  group('subscribeToConversationUpdates', () {
    test('delegates to message source and parses callback', () async {
      late void Function(Map<String, dynamic>) capturedCallback;
      final mockChannel = MockRealtimeChannel();

      when(
        () => messageSource.subscribeToConversationUpdates(['c1', 'c2'], any()),
      ).thenAnswer((inv) {
        capturedCallback =
            inv.positionalArguments[1] as void Function(Map<String, dynamic>);
        return mockChannel;
      });

      Conversation? receivedConversation;
      final channel = repository.subscribeToConversationUpdates(['c1', 'c2'], (
        conv,
      ) {
        receivedConversation = conv;
      });

      expect(channel, mockChannel);

      capturedCallback(
        _makeConversationRow(id: 'c1', lastMessageContent: 'Latest'),
      );

      expect(receivedConversation, isNotNull);
      expect(receivedConversation!.id, 'c1');
    });
  });

  // ── unsubscribe ──

  group('unsubscribe', () {
    test('delegates to message source', () async {
      final mockChannel = MockRealtimeChannel();
      when(
        () => messageSource.unsubscribe(mockChannel),
      ).thenAnswer((_) async {});

      await repository.unsubscribe(mockChannel);

      verify(() => messageSource.unsubscribe(mockChannel)).called(1);
    });
  });

  // ── searchProfiles ──

  group('searchProfiles', () {
    test('returns empty list for empty query', () async {
      final result = await repository.searchProfiles('', excludeUserId: 'u1');

      expect(result, isEmpty);
      verifyNever(() => client.from(any()));
    });

    test('returns empty list for whitespace-only query', () async {
      final result = await repository.searchProfiles(
        '   ',
        excludeUserId: 'u1',
      );

      expect(result, isEmpty);
    });

    test('returns empty list for query stripped by sanitizer', () async {
      final result = await repository.searchProfiles(
        '.,;()\'"`',
        excludeUserId: 'u1',
      );

      expect(result, isEmpty);
      verifyNever(() => client.from(any()));
    });

    test(
      'searches public profile names without selecting or filtering email',
      () async {
        final stack = createFakeSupabaseStack();
        stack.selectBuilder.result = [
          {'id': 'u2', 'display_name': 'Ada', 'avatar_url': null},
        ];
        final searchRepository = MessagingRepository(
          conversationSource: conversationSource,
          messageSource: messageSource,
          client: stack.client,
        );

        final result = await searchRepository.searchProfiles(
          'ada@example.com',
          excludeUserId: 'u1',
        );

        expect(stack.client.requestedTable, SupabaseConstants.profilesTable);
        expect(result, hasLength(1));
        expect(stack.queryBuilder.selectedColumns, isNot(contains('email')));
        expect(stack.selectBuilder.orCalls.single, contains('display_name'));
        expect(stack.selectBuilder.orCalls.single, contains('full_name'));
        expect(stack.selectBuilder.orCalls.single, isNot(contains('email')));
        final neqKeys = stack.selectBuilder.neqCalls
            .map((e) => '${e.key}:${e.value}')
            .toList();
        expect(neqKeys, contains('id:u1'));
      },
    );
  });
}
