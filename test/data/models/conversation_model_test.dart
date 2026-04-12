@Tags(['community'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/messaging_enums.dart';
import 'package:budgie_breeding_tracker/data/models/conversation_model.dart';

void main() {
  group('Conversation model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final now = DateTime.utc(2026, 3, 15, 10, 30);
        final conversation = Conversation(
          id: 'conv-1',
          type: ConversationType.group,
          name: 'Budgie Lovers',
          imageUrl: 'https://example.com/group.png',
          creatorId: 'user-1',
          lastMessageContent: 'Hello everyone!',
          lastMessageAt: now,
          lastMessageUserId: 'user-2',
          participantCount: 5,
          isDeleted: false,
          createdAt: now,
          updatedAt: now,
        );

        final json = conversation.toJson();
        final restored = Conversation.fromJson(json);

        expect(restored.id, conversation.id);
        expect(restored.type, conversation.type);
        expect(restored.name, conversation.name);
        expect(restored.imageUrl, conversation.imageUrl);
        expect(restored.creatorId, conversation.creatorId);
        expect(restored.lastMessageContent, conversation.lastMessageContent);
        expect(restored.lastMessageAt, conversation.lastMessageAt);
        expect(restored.lastMessageUserId, conversation.lastMessageUserId);
        expect(restored.participantCount, conversation.participantCount);
        expect(restored.isDeleted, conversation.isDeleted);
        expect(restored.createdAt, conversation.createdAt);
        expect(restored.updatedAt, conversation.updatedAt);
      });

      test('unknown ConversationType falls back to ConversationType.unknown', () {
        final conversation = Conversation.fromJson(const {
          'id': 'conv-1',
          'creator_id': 'user-1',
          'type': 'channel',
        });

        expect(conversation.type, ConversationType.unknown);
      });

      test('defaults are correct', () {
        final conversation = Conversation.fromJson(const {
          'id': 'conv-1',
          'creator_id': 'user-1',
        });

        expect(conversation.type, ConversationType.direct);
        expect(conversation.participantCount, 0);
        expect(conversation.unreadCount, 0);
        expect(conversation.isDeleted, false);
        expect(conversation.name, isNull);
        expect(conversation.imageUrl, isNull);
        expect(conversation.lastMessageContent, isNull);
        expect(conversation.lastMessageAt, isNull);
        expect(conversation.lastMessageUserId, isNull);
        expect(conversation.createdAt, isNull);
        expect(conversation.updatedAt, isNull);
      });

      test('unreadCount is not read from JSON (includeFromJson: false)', () {
        final conversation = Conversation.fromJson(const {
          'id': 'conv-1',
          'creator_id': 'user-1',
          'unread_count': 99,
        });

        // unreadCount has @JsonKey(includeFromJson: false) so it always defaults to 0
        expect(conversation.unreadCount, 0);
      });
    });

    group('ConversationX extension', () {
      test('isGroup returns true for group type', () {
        const conversation = Conversation(
          id: 'conv-1',
          creatorId: 'user-1',
          type: ConversationType.group,
        );

        expect(conversation.isGroup, isTrue);
        expect(conversation.isDirect, isFalse);
      });

      test('isDirect returns true for direct type', () {
        const conversation = Conversation(
          id: 'conv-1',
          creatorId: 'user-1',
          type: ConversationType.direct,
        );

        expect(conversation.isDirect, isTrue);
        expect(conversation.isGroup, isFalse);
      });

      test('hasUnread returns true when unreadCount > 0', () {
        const conversation = Conversation(
          id: 'conv-1',
          creatorId: 'user-1',
          unreadCount: 3,
        );

        expect(conversation.hasUnread, isTrue);
      });

      test('hasUnread returns false when unreadCount == 0', () {
        const conversation = Conversation(
          id: 'conv-1',
          creatorId: 'user-1',
          unreadCount: 0,
        );

        expect(conversation.hasUnread, isFalse);
      });
    });
  });
}
