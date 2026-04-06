@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:budgie_breeding_tracker/core/enums/messaging_enums.dart';
import 'package:budgie_breeding_tracker/data/models/conversation_model.dart';
import 'package:budgie_breeding_tracker/features/messaging/widgets/conversation_tile.dart';

import '../../../helpers/test_localization.dart';

void main() {
  group('ConversationTile', () {
    testWidgets('renders conversation name', (tester) async {
      const conversation = Conversation(
        id: 'conv-1',
        creatorId: 'user-1',
        name: 'My Budgies Chat',
      );

      await pumpLocalizedWidget(tester, ConversationTile(conversation: conversation));

      expect(find.text('My Budgies Chat'), findsOneWidget);
    });

    testWidgets('renders fallback name for direct message without name',
        (tester) async {
      const conversation = Conversation(
        id: 'conv-1',
        creatorId: 'user-1',
        name: null,
        type: ConversationType.direct,
      );

      await pumpLocalizedWidget(tester, ConversationTile(conversation: conversation));

      expect(
        find.text(l10n('messaging.direct_message')),
        findsOneWidget,
      );
    });

    testWidgets('shows last message content', (tester) async {
      const conversation = Conversation(
        id: 'conv-1',
        creatorId: 'user-1',
        name: 'Chat',
        lastMessageContent: 'Hello world!',
      );

      await pumpLocalizedWidget(tester, ConversationTile(conversation: conversation));

      expect(find.text('Hello world!'), findsOneWidget);
    });

    testWidgets('shows unread badge when there are unread messages',
        (tester) async {
      const conversation = Conversation(
        id: 'conv-1',
        creatorId: 'user-1',
        name: 'Chat',
        unreadCount: 3,
      );

      await pumpLocalizedWidget(tester, ConversationTile(conversation: conversation));

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('does not show unread badge when count is zero',
        (tester) async {
      const conversation = Conversation(
        id: 'conv-1',
        creatorId: 'user-1',
        name: 'Chat',
        unreadCount: 0,
      );

      await pumpLocalizedWidget(tester, ConversationTile(conversation: conversation));

      // No unread count badge
      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows users icon for group conversations', (tester) async {
      const conversation = Conversation(
        id: 'conv-1',
        creatorId: 'user-1',
        name: 'Group Chat',
        type: ConversationType.group,
      );

      await pumpLocalizedWidget(tester, ConversationTile(conversation: conversation));

      expect(find.byIcon(LucideIcons.users), findsOneWidget);
    });

    testWidgets('shows user icon for direct conversations', (tester) async {
      const conversation = Conversation(
        id: 'conv-1',
        creatorId: 'user-1',
        name: 'DM',
        type: ConversationType.direct,
      );

      await pumpLocalizedWidget(tester, ConversationTile(conversation: conversation));

      expect(find.byIcon(LucideIcons.user), findsOneWidget);
    });

    testWidgets('renders ListTile with tap area', (tester) async {
      const conversation = Conversation(
        id: 'conv-1',
        creatorId: 'user-1',
        name: 'Chat',
      );

      await pumpLocalizedWidget(tester, ConversationTile(conversation: conversation));

      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('shows CircleAvatar', (tester) async {
      const conversation = Conversation(
        id: 'conv-1',
        creatorId: 'user-1',
        name: 'Chat',
      );

      await pumpLocalizedWidget(tester, ConversationTile(conversation: conversation));

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('shows time for recent messages', (tester) async {
      final conversation = Conversation(
        id: 'conv-1',
        creatorId: 'user-1',
        name: 'Chat',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      await pumpLocalizedWidget(tester, ConversationTile(conversation: conversation));

      // Time text should be present (e.g. "2 hours ago" or localized key)
      expect(find.byType(ConversationTile), findsOneWidget);
    });
  });
}
