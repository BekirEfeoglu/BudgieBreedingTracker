@Tags(['community'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/data/repositories/messaging_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/data/models/message_model.dart';
import 'package:budgie_breeding_tracker/domain/services/moderation/content_moderation_service.dart';
import 'package:budgie_breeding_tracker/domain/services/moderation/moderation_providers.dart';
import 'package:budgie_breeding_tracker/features/messaging/providers/messaging_form_providers.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

class MockContentModerationService extends Mock
    implements ContentModerationService {}

void main() {
  late MockMessagingRepository mockRepo;
  late MockContentModerationService mockModeration;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockMessagingRepository();
    mockModeration = MockContentModerationService();
    container = ProviderContainer(overrides: [
      messagingRepositoryProvider.overrideWithValue(mockRepo),
      contentModerationServiceProvider.overrideWithValue(mockModeration),
    ]);
  });

  tearDown(() => container.dispose());

  test('initial state is correct', () {
    final state = container.read(messagingFormStateProvider);
    expect(state.isLoading, false);
    expect(state.error, isNull);
    expect(state.isSuccess, false);
    expect(state.resultConversationId, isNull);
  });

  group('sendMessage', () {
    setUp(() {
      when(() => mockModeration.checkText(any()))
          .thenAnswer((_) async => const ModerationResult.allowed());
      when(() => mockRepo.sendMessage(any())).thenAnswer(
        (_) async => Message.fromJson({
          'id': 'msg-1',
          'conversation_id': 'conv-1',
          'sender_id': 'user-1',
          'sender_name': 'Test',
          'content': 'Hello',
          'message_type': 'text',
          'read_by': ['user-1'],
          'is_deleted': false,
        }),
      );
    });

    test('sends message with moderation check', () async {
      await container
          .read(messagingFormStateProvider.notifier)
          .sendMessage(
            conversationId: 'conv-1',
            senderId: 'user-1',
            senderName: 'Test',
            content: 'Hello world',
          );

      verify(() => mockModeration.checkText('Hello world')).called(1);
      verify(() => mockRepo.sendMessage(any())).called(1);
    });

    test('rejects message when moderation fails', () async {
      when(() => mockModeration.checkText(any())).thenAnswer(
        (_) async => const ModerationResult.rejected('content_violation'),
      );

      await container
          .read(messagingFormStateProvider.notifier)
          .sendMessage(
            conversationId: 'conv-1',
            senderId: 'user-1',
            senderName: 'Test',
            content: 'Forbidden content',
          );

      verifyNever(() => mockRepo.sendMessage(any()));
      final state = container.read(messagingFormStateProvider);
      expect(state.error, isNotNull);
    });

    test('rejects content exceeding max length', () async {
      final longContent = 'a' * 2001;

      await container
          .read(messagingFormStateProvider.notifier)
          .sendMessage(
            conversationId: 'conv-1',
            senderId: 'user-1',
            senderName: 'Test',
            content: longContent,
          );

      verifyNever(() => mockModeration.checkText(any()));
      verifyNever(() => mockRepo.sendMessage(any()));
      final state = container.read(messagingFormStateProvider);
      expect(state.error, isNotNull);
    });

    test('throttles rapid messages', () async {
      await container
          .read(messagingFormStateProvider.notifier)
          .sendMessage(
            conversationId: 'conv-1',
            senderId: 'user-1',
            senderName: 'Test',
            content: 'First message',
          );

      // Second message immediately — should be throttled
      await container
          .read(messagingFormStateProvider.notifier)
          .sendMessage(
            conversationId: 'conv-1',
            senderId: 'user-1',
            senderName: 'Test',
            content: 'Second message',
          );

      // Only first message should have been sent
      verify(() => mockRepo.sendMessage(any())).called(1);
      // Throttled message should set error state
      final state = container.read(messagingFormStateProvider);
      expect(state.error, isNotNull);
    });

    test('skips moderation for null content', () async {
      await container
          .read(messagingFormStateProvider.notifier)
          .sendMessage(
            conversationId: 'conv-1',
            senderId: 'user-1',
            senderName: 'Test',
          );

      verifyNever(() => mockModeration.checkText(any()));
    });
  });

  test('startDirectConversation returns conversationId on success', () async {
    when(() => mockRepo.getOrCreateDirectConversation(
          userId1: any(named: 'userId1'),
          userId2: any(named: 'userId2'),
        )).thenAnswer((_) async => 'conv-123');

    final result = await container
        .read(messagingFormStateProvider.notifier)
        .startDirectConversation(
          userId1: 'user-1',
          userId2: 'user-2',
        );

    expect(result, 'conv-123');
    final state = container.read(messagingFormStateProvider);
    expect(state.isSuccess, isTrue);
    expect(state.resultConversationId, 'conv-123');
  });

  test('startDirectConversation sets error on failure', () async {
    when(() => mockRepo.getOrCreateDirectConversation(
          userId1: any(named: 'userId1'),
          userId2: any(named: 'userId2'),
        )).thenThrow(Exception('Network error'));

    final result = await container
        .read(messagingFormStateProvider.notifier)
        .startDirectConversation(
          userId1: 'user-1',
          userId2: 'user-2',
        );

    expect(result, isNull);
    final state = container.read(messagingFormStateProvider);
    expect(state.error, isNotNull);
    expect(state.isLoading, isFalse);
  });

  test('createGroupConversation returns conversationId on success', () async {
    when(() => mockRepo.createGroupConversation(
          creatorId: any(named: 'creatorId'),
          name: any(named: 'name'),
          participantIds: any(named: 'participantIds'),
          imageUrl: any(named: 'imageUrl'),
        )).thenAnswer((_) async => 'group-456');

    final result = await container
        .read(messagingFormStateProvider.notifier)
        .createGroupConversation(
          creatorId: 'user-1',
          name: 'Test Group',
          participantIds: ['user-1', 'user-2'],
        );

    expect(result, 'group-456');
    final state = container.read(messagingFormStateProvider);
    expect(state.isSuccess, isTrue);
    expect(state.resultConversationId, 'group-456');
  });

  test('leaveGroup sets isSuccess on success', () async {
    when(() => mockRepo.leaveConversation(any(), any()))
        .thenAnswer((_) async {});

    await container
        .read(messagingFormStateProvider.notifier)
        .leaveGroup('conv-1', 'user-1');

    final state = container.read(messagingFormStateProvider);
    expect(state.isSuccess, isTrue);
  });

  test('reset clears state', () async {
    when(() => mockRepo.getOrCreateDirectConversation(
          userId1: any(named: 'userId1'),
          userId2: any(named: 'userId2'),
        )).thenAnswer((_) async => 'conv-123');

    await container
        .read(messagingFormStateProvider.notifier)
        .startDirectConversation(userId1: 'u1', userId2: 'u2');

    container.read(messagingFormStateProvider.notifier).reset();

    final state = container.read(messagingFormStateProvider);
    expect(state.isLoading, false);
    expect(state.error, isNull);
    expect(state.isSuccess, false);
    expect(state.resultConversationId, isNull);
  });
}
