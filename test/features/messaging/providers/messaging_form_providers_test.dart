import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/data/repositories/messaging_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/messaging/providers/messaging_form_providers.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late MockMessagingRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockMessagingRepository();
    container = ProviderContainer(overrides: [
      messagingRepositoryProvider.overrideWithValue(mockRepo),
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
