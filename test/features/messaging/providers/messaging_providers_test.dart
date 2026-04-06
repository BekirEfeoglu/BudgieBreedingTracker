@Tags(['community'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/repositories/messaging_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/messaging/providers/messaging_providers.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

Conversation _makeConversation(
  String id, {
  String? name,
  String? lastMessageContent,
  int unreadCount = 0,
}) {
  return Conversation(
    id: id,
    creatorId: 'user-1',
    name: name,
    lastMessageContent: lastMessageContent,
    unreadCount: unreadCount,
    createdAt: DateTime(2024),
  );
}

Message _makeMessage(String id, {String conversationId = 'conv-1'}) {
  return Message(
    id: id,
    conversationId: conversationId,
    senderId: 'user-1',
    senderName: 'Test User',
    content: 'Message $id',
    createdAt: DateTime(2024),
  );
}

void main() {
  late MockMessagingRepository mockRepo;

  setUp(() {
    mockRepo = MockMessagingRepository();
  });

  group('isMessagingEnabledProvider', () {
    test('returns true by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isMessagingEnabledProvider), isTrue);
    });
  });

  group('conversationsProvider', () {
    test('returns conversations from repository', () async {
      final conversations = [
        _makeConversation('c1', name: 'Chat 1'),
        _makeConversation('c2', name: 'Chat 2'),
      ];

      when(() => mockRepo.getConversations('user-1'))
          .thenAnswer((_) async => conversations);

      final container = ProviderContainer(overrides: [
        messagingRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(conversationsProvider('user-1').future);

      expect(result.length, 2);
      expect(result.first.id, 'c1');
      expect(result.last.id, 'c2');
      verify(() => mockRepo.getConversations('user-1')).called(1);
    });

    test('returns empty list when no conversations', () async {
      when(() => mockRepo.getConversations('user-1'))
          .thenAnswer((_) async => []);

      final container = ProviderContainer(overrides: [
        messagingRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(conversationsProvider('user-1').future);

      expect(result, isEmpty);
    });

    test('exposes error when repository fails', () async {
      when(() => mockRepo.getConversations('user-1'))
          .thenAnswer((_) async => throw Exception('Network error'));

      final container = ProviderContainer(overrides: [
        messagingRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final sub = container.listen(
        conversationsProvider('user-1'),
        (_, __) {},
        fireImmediately: true,
      );

      // Allow microtasks to settle
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final value = container.read(conversationsProvider('user-1'));
      expect(value.hasError, isTrue);
      expect(value.error, isA<Exception>());
      sub.close();
    });
  });

  group('conversationByIdProvider', () {
    test('returns conversation when found', () async {
      final conversation = _makeConversation('c1', name: 'Test Chat');

      when(() => mockRepo.getConversationById('c1'))
          .thenAnswer((_) async => conversation);

      final container = ProviderContainer(overrides: [
        messagingRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(conversationByIdProvider('c1').future);

      expect(result, isNotNull);
      expect(result!.id, 'c1');
      expect(result.name, 'Test Chat');
    });

    test('returns null when conversation not found', () async {
      when(() => mockRepo.getConversationById('nonexistent'))
          .thenAnswer((_) async => null);

      final container = ProviderContainer(overrides: [
        messagingRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(conversationByIdProvider('nonexistent').future);

      expect(result, isNull);
    });

    test('exposes error when repository fails', () async {
      when(() => mockRepo.getConversationById('c1'))
          .thenAnswer((_) async => throw Exception('fetch failed'));

      final container = ProviderContainer(overrides: [
        messagingRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final sub = container.listen(
        conversationByIdProvider('c1'),
        (_, __) {},
        fireImmediately: true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final value = container.read(conversationByIdProvider('c1'));
      expect(value.hasError, isTrue);
      expect(value.error, isA<Exception>());
      sub.close();
    });
  });

  group('messagesProvider', () {
    test('returns messages for conversation', () async {
      final messages = [
        _makeMessage('m1'),
        _makeMessage('m2'),
        _makeMessage('m3'),
      ];

      when(() => mockRepo.getMessages('conv-1'))
          .thenAnswer((_) async => messages);

      final container = ProviderContainer(overrides: [
        messagingRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(messagesProvider('conv-1').future);

      expect(result.length, 3);
      expect(result.first.id, 'm1');
      verify(() => mockRepo.getMessages('conv-1')).called(1);
    });

    test('returns empty list when no messages', () async {
      when(() => mockRepo.getMessages('conv-1'))
          .thenAnswer((_) async => []);

      final container = ProviderContainer(overrides: [
        messagingRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final result =
          await container.read(messagesProvider('conv-1').future);

      expect(result, isEmpty);
    });

    test('exposes error when repository fails', () async {
      when(() => mockRepo.getMessages('conv-1'))
          .thenAnswer((_) async => throw Exception('fetch failed'));

      final container = ProviderContainer(overrides: [
        messagingRepositoryProvider.overrideWithValue(mockRepo),
      ]);
      addTearDown(container.dispose);

      final sub = container.listen(
        messagesProvider('conv-1'),
        (_, __) {},
        fireImmediately: true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final value = container.read(messagesProvider('conv-1'));
      expect(value.hasError, isTrue);
      expect(value.error, isA<Exception>());
      sub.close();
    });
  });

  group('ConversationSearchQueryNotifier', () {
    test('initial value is empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(conversationSearchQueryProvider), isEmpty);
    });

    test('can update search query', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(conversationSearchQueryProvider.notifier).state =
          'test query';

      expect(container.read(conversationSearchQueryProvider), 'test query');
    });

    test('can reset search query', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(conversationSearchQueryProvider.notifier).state =
          'something';
      container.read(conversationSearchQueryProvider.notifier).state = '';

      expect(container.read(conversationSearchQueryProvider), isEmpty);
    });
  });

  group('filteredConversationsProvider', () {
    final conversations = [
      _makeConversation('c1', name: 'Bird Chat', lastMessageContent: 'Hello'),
      _makeConversation(
        'c2',
        name: 'Breeding Group',
        lastMessageContent: 'New egg today',
      ),
      _makeConversation(
        'c3',
        name: 'General',
        lastMessageContent: 'Budgie tips',
      ),
    ];

    test('returns all conversations when query is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(
        filteredConversationsProvider(conversations),
      );

      expect(result.length, 3);
    });

    test('returns all conversations when query is whitespace', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(conversationSearchQueryProvider.notifier).state = '   ';

      final result = container.read(
        filteredConversationsProvider(conversations),
      );

      expect(result.length, 3);
    });

    test('filters by conversation name', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(conversationSearchQueryProvider.notifier).state = 'bird';

      final result = container.read(
        filteredConversationsProvider(conversations),
      );

      expect(result.length, 1);
      expect(result.first.id, 'c1');
    });

    test('filters by last message content', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(conversationSearchQueryProvider.notifier).state = 'egg';

      final result = container.read(
        filteredConversationsProvider(conversations),
      );

      expect(result.length, 1);
      expect(result.first.id, 'c2');
    });

    test('search is case insensitive', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(conversationSearchQueryProvider.notifier).state =
          'BREEDING';

      final result = container.read(
        filteredConversationsProvider(conversations),
      );

      expect(result.length, 1);
      expect(result.first.id, 'c2');
    });

    test('returns empty when no match', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(conversationSearchQueryProvider.notifier).state =
          'nonexistent';

      final result = container.read(
        filteredConversationsProvider(conversations),
      );

      expect(result, isEmpty);
    });

    test('handles conversations with null name', () {
      final conversationsWithNull = [
        _makeConversation('c1', lastMessageContent: 'some text'),
      ];

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(conversationSearchQueryProvider.notifier).state = 'some';

      final result = container.read(
        filteredConversationsProvider(conversationsWithNull),
      );

      expect(result.length, 1);
    });

    test('handles conversations with null lastMessageContent', () {
      final conversationsWithNull = [
        _makeConversation('c1', name: 'Chat Room'),
      ];

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(conversationSearchQueryProvider.notifier).state = 'chat';

      final result = container.read(
        filteredConversationsProvider(conversationsWithNull),
      );

      expect(result.length, 1);
    });

    test('no match when both name and lastMessageContent are null', () {
      final conversationsWithNull = [
        _makeConversation('c1'),
      ];

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(conversationSearchQueryProvider.notifier).state =
          'anything';

      final result = container.read(
        filteredConversationsProvider(conversationsWithNull),
      );

      expect(result, isEmpty);
    });
  });

  group('totalUnreadCountProvider', () {
    test('returns 0 for empty list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(totalUnreadCountProvider([]));

      expect(result, 0);
    });

    test('sums unread counts across conversations', () {
      final conversations = [
        _makeConversation('c1', unreadCount: 3),
        _makeConversation('c2', unreadCount: 5),
        _makeConversation('c3', unreadCount: 2),
      ];

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(totalUnreadCountProvider(conversations));

      expect(result, 10);
    });

    test('returns 0 when all conversations are read', () {
      final conversations = [
        _makeConversation('c1', unreadCount: 0),
        _makeConversation('c2', unreadCount: 0),
      ];

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(totalUnreadCountProvider(conversations));

      expect(result, 0);
    });

    test('handles single conversation', () {
      final conversations = [
        _makeConversation('c1', unreadCount: 7),
      ];

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(totalUnreadCountProvider(conversations));

      expect(result, 7);
    });
  });
}
