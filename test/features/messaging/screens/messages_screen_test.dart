@Tags(['community'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/data/repositories/messaging_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/messaging/providers/messaging_providers.dart';
import 'package:budgie_breeding_tracker/features/messaging/screens/messages_screen.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';

import '../../../helpers/test_localization.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late MockMessagingRepository mockRepo;

  setUp(() {
    mockRepo = MockMessagingRepository();
  });

  Widget buildSubject({
    required AsyncValue<List<Conversation>> conversationsAsync,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        messagingRepositoryProvider.overrideWithValue(mockRepo),
        conversationsProvider('test-user').overrideWith(
          (_) => switch (conversationsAsync) {
            AsyncData(:final value) => Future.value(value),
            AsyncError(:final error) => Future.error(error),
            _ => Future<List<Conversation>>.value([]),
          },
        ),
      ],
      child: const MaterialApp(
        home: MessagesScreen(),
      ),
    );
  }

  testWidgets('loading state shows CircularProgressIndicator', (tester) async {
    final completer = Completer<List<Conversation>>();

    await pumpLocalizedApp(
      tester,
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('test-user'),
          messagingRepositoryProvider.overrideWithValue(mockRepo),
          conversationsProvider('test-user').overrideWith(
            (_) => completer.future,
          ),
        ],
        child: const MaterialApp(
          home: MessagesScreen(),
        ),
      ),
      settle: false,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete([]);
  });

  testWidgets('empty state shows EmptyState widget', (tester) async {
    await pumpLocalizedApp(
      tester,
      buildSubject(conversationsAsync: const AsyncData([])),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('data state shows ConversationTile widgets', (tester) async {
    final conversations = [
      const Conversation(
        id: 'conv-1',
        creatorId: 'user-1',
        name: 'Test Conversation',
      ),
      const Conversation(
        id: 'conv-2',
        creatorId: 'user-2',
        name: 'Another Chat',
      ),
    ];

    await pumpLocalizedApp(
      tester,
      buildSubject(conversationsAsync: AsyncData(conversations)),
    );

    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Test Conversation'), findsOneWidget);
    expect(find.text('Another Chat'), findsOneWidget);
  });
}
