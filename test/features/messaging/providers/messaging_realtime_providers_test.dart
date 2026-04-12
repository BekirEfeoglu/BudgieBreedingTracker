@Tags(['community'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/data/models/message_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/messaging_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/messaging/providers/messaging_realtime_providers.dart';

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

  group('MessagingRealtimeNotifier', () {
    test('initial state is empty list', () {
      final state = container.read(messagingRealtimeProvider);
      expect(state, isEmpty);
    });

    test('addLocalMessage prepends message to state', () {
      const message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        content: 'Hello',
      );

      container.read(messagingRealtimeProvider.notifier).addLocalMessage(
            message,
          );

      final state = container.read(messagingRealtimeProvider);
      expect(state.length, 1);
      expect(state.first.id, 'msg-1');
      expect(state.first.content, 'Hello');
    });

    test('addLocalMessage prepends multiple messages in order', () {
      const msg1 = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        content: 'First',
      );
      const msg2 = Message(
        id: 'msg-2',
        conversationId: 'conv-1',
        senderId: 'user-2',
        content: 'Second',
      );

      final notifier = container.read(messagingRealtimeProvider.notifier);
      notifier.addLocalMessage(msg1);
      notifier.addLocalMessage(msg2);

      final state = container.read(messagingRealtimeProvider);
      expect(state.length, 2);
      expect(state[0].id, 'msg-2');
      expect(state[1].id, 'msg-1');
    });

    test('clear resets state to empty', () {
      const message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        content: 'Hello',
      );

      final notifier = container.read(messagingRealtimeProvider.notifier);
      notifier.addLocalMessage(message);
      expect(container.read(messagingRealtimeProvider), isNotEmpty);

      notifier.clear();
      expect(container.read(messagingRealtimeProvider), isEmpty);
    });
  });

  group('TypingIndicatorNotifier', () {
    test('initial state is empty set', () {
      final state = container.read(typingIndicatorProvider);
      expect(state, isEmpty);
    });

    test('userStartedTyping adds user to set', () {
      container
          .read(typingIndicatorProvider.notifier)
          .userStartedTyping('user-1');

      final state = container.read(typingIndicatorProvider);
      expect(state, contains('user-1'));
    });

    test('userStoppedTyping removes user from set', () {
      final notifier = container.read(typingIndicatorProvider.notifier);
      notifier.userStartedTyping('user-1');
      notifier.userStoppedTyping('user-1');

      final state = container.read(typingIndicatorProvider);
      expect(state, isEmpty);
    });

    test('multiple users can be typing simultaneously', () {
      final notifier = container.read(typingIndicatorProvider.notifier);
      notifier.userStartedTyping('user-1');
      notifier.userStartedTyping('user-2');

      final state = container.read(typingIndicatorProvider);
      expect(state, containsAll(['user-1', 'user-2']));
    });

    test('clear resets typing state', () {
      final notifier = container.read(typingIndicatorProvider.notifier);
      notifier.userStartedTyping('user-1');
      notifier.userStartedTyping('user-2');
      notifier.clear();

      final state = container.read(typingIndicatorProvider);
      expect(state, isEmpty);
    });
  });
}
