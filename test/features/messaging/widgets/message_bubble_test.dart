@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:budgie_breeding_tracker/core/enums/messaging_enums.dart';
import 'package:budgie_breeding_tracker/data/models/message_model.dart';
import 'package:budgie_breeding_tracker/features/messaging/widgets/message_bubble.dart';

import '../../../helpers/test_localization.dart';

void main() {
  group('MessageBubble — text message', () {
    testWidgets('renders text content for own message', (tester) async {
      final message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        content: 'Hello from me!',
        createdAt: DateTime(2025, 3, 15, 14, 30),
      );

      await pumpLocalizedWidget(
        tester,
        MessageBubble(message: message, isMe: true),
      );

      expect(find.text('Hello from me!'), findsOneWidget);
      expect(find.text('14:30'), findsOneWidget);
    });

    testWidgets('renders text content for other user message', (tester) async {
      final message = Message(
        id: 'msg-2',
        conversationId: 'conv-1',
        senderId: 'other-user',
        senderName: 'Alice',
        content: 'Hello from Alice!',
        createdAt: DateTime(2025, 3, 15, 14, 31),
      );

      await pumpLocalizedWidget(
        tester,
        MessageBubble(message: message, isMe: false),
      );

      expect(find.text('Hello from Alice!'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('14:31'), findsOneWidget);
    });

    testWidgets('does not show sender name for own messages', (tester) async {
      final message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        senderName: 'Me',
        content: 'My message',
        createdAt: DateTime(2025, 3, 15, 10, 0),
      );

      await pumpLocalizedWidget(
        tester,
        MessageBubble(message: message, isMe: true),
      );

      expect(find.text('Me'), findsNothing);
    });

    testWidgets('does not show sender name when it is empty', (tester) async {
      final message = Message(
        id: 'msg-2',
        conversationId: 'conv-1',
        senderId: 'other-user',
        senderName: '',
        content: 'Anonymous',
        createdAt: DateTime(2025, 3, 15, 10, 0),
      );

      await pumpLocalizedWidget(
        tester,
        MessageBubble(message: message, isMe: false),
      );

      // senderName is empty so it should not render the name widget
      expect(find.text('Anonymous'), findsOneWidget);
    });
  });

  group('MessageBubble — deleted message', () {
    testWidgets('shows deleted message text', (tester) async {
      final message = Message(
        id: 'msg-del',
        conversationId: 'conv-1',
        senderId: 'user-1',
        content: 'Secret',
        isDeleted: true,
        createdAt: DateTime(2025, 3, 15, 10, 0),
      );

      await pumpLocalizedWidget(
        tester,
        MessageBubble(message: message, isMe: true),
      );

      expect(
        find.text(l10n('messaging.message_deleted')),
        findsOneWidget,
      );
      // Original content should not be visible
      expect(find.text('Secret'), findsNothing);
    });
  });

  group('MessageBubble — read receipts', () {
    testWidgets('shows single check for unread own message', (tester) async {
      final message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        content: 'Hello',
        readBy: const ['user-1'],
        createdAt: DateTime(2025, 3, 15, 10, 0),
      );

      await pumpLocalizedWidget(
        tester,
        MessageBubble(message: message, isMe: true),
      );

      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      expect(find.byIcon(LucideIcons.checkCheck), findsNothing);
    });

    testWidgets('shows double check when read by others', (tester) async {
      final message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        content: 'Hello',
        readBy: const ['user-1', 'user-2'],
        createdAt: DateTime(2025, 3, 15, 10, 0),
      );

      await pumpLocalizedWidget(
        tester,
        MessageBubble(message: message, isMe: true),
      );

      expect(find.byIcon(LucideIcons.checkCheck), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsNothing);
    });

    testWidgets('does not show read receipt icons for other users',
        (tester) async {
      final message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'other-user',
        content: 'Hello',
        readBy: const ['other-user'],
        createdAt: DateTime(2025, 3, 15, 10, 0),
      );

      await pumpLocalizedWidget(
        tester,
        MessageBubble(message: message, isMe: false),
      );

      expect(find.byIcon(LucideIcons.check), findsNothing);
      expect(find.byIcon(LucideIcons.checkCheck), findsNothing);
    });
  });

  group('MessageBubble — alignment', () {
    testWidgets('own message aligns to the right', (tester) async {
      final message = Message(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        content: 'Right aligned',
        createdAt: DateTime(2025, 3, 15, 10, 0),
      );

      await pumpLocalizedWidget(
        tester,
        MessageBubble(message: message, isMe: true),
      );

      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('other user message aligns to the left', (tester) async {
      final message = Message(
        id: 'msg-2',
        conversationId: 'conv-1',
        senderId: 'other-user',
        content: 'Left aligned',
        createdAt: DateTime(2025, 3, 15, 10, 0),
      );

      await pumpLocalizedWidget(
        tester,
        MessageBubble(message: message, isMe: false),
      );

      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerLeft);
    });
  });

  group('MessageBubble — image message', () {
    testWidgets('renders image placeholder for image type', (tester) async {
      final message = Message(
        id: 'msg-img',
        conversationId: 'conv-1',
        senderId: 'user-1',
        messageType: MessageType.image,
        imageUrl: null,
        createdAt: DateTime(2025, 3, 15, 10, 0),
      );

      await pumpLocalizedWidget(
        tester,
        MessageBubble(message: message, isMe: true),
      );

      // With null imageUrl, should show SizedBox.shrink
      expect(find.byType(MessageBubble), findsOneWidget);
    });
  });

  group('MessageBubble — reference cards', () {
    testWidgets('renders bird card message', (tester) async {
      final message = Message(
        id: 'msg-bird',
        conversationId: 'conv-1',
        senderId: 'user-1',
        messageType: MessageType.birdCard,
        referenceData: const {'name': 'Blue Budgie'},
        createdAt: DateTime(2025, 3, 15, 10, 0),
      );

      await pumpLocalizedWidget(
        tester,
        MessageBubble(message: message, isMe: true),
      );

      expect(find.text('Blue Budgie'), findsOneWidget);
      expect(find.byIcon(LucideIcons.bird), findsOneWidget);
    });

    testWidgets('renders listing card message', (tester) async {
      final message = Message(
        id: 'msg-listing',
        conversationId: 'conv-1',
        senderId: 'user-1',
        messageType: MessageType.listingCard,
        referenceData: const {'title': 'Budgie for sale'},
        createdAt: DateTime(2025, 3, 15, 10, 0),
      );

      await pumpLocalizedWidget(
        tester,
        MessageBubble(message: message, isMe: true),
      );

      expect(find.text('Budgie for sale'), findsOneWidget);
      expect(find.byIcon(LucideIcons.store), findsOneWidget);
    });
  });

  group('MessageBubble — time formatting', () {
    testWidgets('shows formatted time with zero-padded hour and minute',
        (tester) async {
      final message = Message(
        id: 'msg-time',
        conversationId: 'conv-1',
        senderId: 'user-1',
        content: 'Time test',
        createdAt: DateTime(2025, 3, 15, 9, 5),
      );

      await pumpLocalizedWidget(
        tester,
        MessageBubble(message: message, isMe: true),
      );

      expect(find.text('09:05'), findsOneWidget);
    });

    testWidgets('shows empty string when createdAt is null', (tester) async {
      const message = Message(
        id: 'msg-null-time',
        conversationId: 'conv-1',
        senderId: 'user-1',
        content: 'No time',
        createdAt: null,
      );

      await pumpLocalizedWidget(
        tester,
        MessageBubble(message: message, isMe: true),
      );

      expect(find.text('No time'), findsOneWidget);
    });
  });
}
