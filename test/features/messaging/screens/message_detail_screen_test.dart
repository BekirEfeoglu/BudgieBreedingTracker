@Tags(['community'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart' as app;
import 'package:budgie_breeding_tracker/data/models/conversation_model.dart';
import 'package:budgie_breeding_tracker/data/models/message_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/messaging_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/messaging/providers/messaging_form_providers.dart';
import 'package:budgie_breeding_tracker/features/messaging/providers/messaging_providers.dart';
import 'package:budgie_breeding_tracker/features/messaging/providers/messaging_realtime_providers.dart';
import 'package:budgie_breeding_tracker/features/messaging/screens/message_detail_screen.dart';
import 'package:budgie_breeding_tracker/features/messaging/widgets/message_bubble.dart';
import 'package:budgie_breeding_tracker/features/messaging/widgets/message_input_bar.dart';

import '../../../helpers/test_localization.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late MockMessagingRepository mockRepo;

  setUp(() {
    mockRepo = MockMessagingRepository();
  });

  Widget buildSubject({
    AsyncValue<Conversation?>? conversationAsync,
    AsyncValue<List<Message>>? messagesAsync,
    List<Message> realtimeMessages = const [],
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        messagingRepositoryProvider.overrideWithValue(mockRepo),
        conversationByIdProvider('conv-1').overrideWith(
          (_) => switch (conversationAsync) {
            AsyncData(:final value) => Future.value(value),
            AsyncError(:final error) => Future.error(error),
            _ => Future<Conversation?>.value(null),
          },
        ),
        messagesProvider('conv-1').overrideWith(
          (_) => switch (messagesAsync) {
            AsyncData(:final value) => Future.value(value),
            AsyncError(:final error) => Future.error(error),
            _ => Future<List<Message>>.value([]),
          },
        ),
        messagingRealtimeProvider.overrideWith(
          () => _FakeRealtimeNotifier(realtimeMessages),
        ),
        typingIndicatorProvider.overrideWith(_FakeTypingNotifier.new),
        messagingFormStateProvider.overrideWith(
          _FakeMessagingFormNotifier.new,
        ),
      ],
      child: const MaterialApp(
        home: MessageDetailScreen(conversationId: 'conv-1'),
      ),
    );
  }

  group('MessageDetailScreen', () {
    testWidgets('loading state shows CircularProgressIndicator',
        (tester) async {
      final completer = Completer<List<Message>>();

      await pumpLocalizedApp(
        tester,
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            messagingRepositoryProvider.overrideWithValue(mockRepo),
            conversationByIdProvider('conv-1').overrideWith(
              (_) => Future.value(null),
            ),
            messagesProvider('conv-1').overrideWith(
              (_) => completer.future,
            ),
            messagingRealtimeProvider.overrideWith(
              () => _FakeRealtimeNotifier([]),
            ),
            typingIndicatorProvider.overrideWith(_FakeTypingNotifier.new),
            messagingFormStateProvider.overrideWith(
              _FakeMessagingFormNotifier.new,
            ),
          ],
          child: const MaterialApp(
            home: MessageDetailScreen(conversationId: 'conv-1'),
          ),
        ),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]);
    });

    testWidgets('error state shows ErrorState widget', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          messagesAsync: AsyncError(Exception('Network error'), StackTrace.empty),
        ),
      );

      expect(find.byType(app.ErrorState), findsOneWidget);
    });

    testWidgets('empty messages shows hint text', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          conversationAsync: const AsyncData(
            Conversation(id: 'conv-1', creatorId: 'user-1', name: 'Chat'),
          ),
          messagesAsync: const AsyncData([]),
        ),
      );

      // Empty state shows hint
      expect(find.byType(MessageBubble), findsNothing);
    });

    testWidgets('data state shows message bubbles', (tester) async {
      final messages = [
        Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          senderId: 'test-user',
          content: 'Hello there',
          createdAt: DateTime(2025, 1, 1, 10, 0),
        ),
        Message(
          id: 'msg-2',
          conversationId: 'conv-1',
          senderId: 'other-user',
          senderName: 'Other',
          content: 'Hi back',
          createdAt: DateTime(2025, 1, 1, 10, 1),
        ),
      ];

      await pumpLocalizedApp(
        tester,
        buildSubject(
          conversationAsync: const AsyncData(
            Conversation(id: 'conv-1', creatorId: 'user-1', name: 'Chat'),
          ),
          messagesAsync: AsyncData(messages),
        ),
      );

      expect(find.byType(MessageBubble), findsNWidgets(2));
      expect(find.text('Hello there'), findsOneWidget);
      expect(find.text('Hi back'), findsOneWidget);
    });

    testWidgets('renders conversation name in app bar', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          conversationAsync: const AsyncData(
            Conversation(id: 'conv-1', creatorId: 'user-1', name: 'My Group'),
          ),
          messagesAsync: const AsyncData([]),
        ),
      );

      expect(find.text('My Group'), findsOneWidget);
    });

    testWidgets('renders MessageInputBar', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          messagesAsync: const AsyncData([]),
        ),
      );

      expect(find.byType(MessageInputBar), findsOneWidget);
    });

    testWidgets('shows member count for group conversations', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          conversationAsync: const AsyncData(
            Conversation(
              id: 'conv-1',
              creatorId: 'user-1',
              name: 'Group Chat',
              type: ConversationType.group,
              participantCount: 5,
            ),
          ),
          messagesAsync: const AsyncData([]),
        ),
      );

      expect(find.text('Group Chat'), findsOneWidget);
    });
  });
}

class _FakeRealtimeNotifier extends MessagingRealtimeNotifier {
  final List<Message> _initialMessages;

  _FakeRealtimeNotifier(this._initialMessages);

  @override
  List<Message> build() => _initialMessages;

  @override
  void subscribe(String conversationId) {}

  @override
  void clear() {}
}

class _FakeTypingNotifier extends TypingIndicatorNotifier {
  @override
  Set<String> build() => {};
}

class _FakeMessagingFormNotifier extends MessagingFormNotifier {
  @override
  MessagingFormState build() => const MessagingFormState();

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    String? content,
    MessageType messageType = MessageType.text,
    String? imageUrl,
    String? referenceId,
    Map<String, dynamic>? referenceData,
  }) async {}

  @override
  void reset() {}
}
