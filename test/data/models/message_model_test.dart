import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/messaging_enums.dart';
import 'package:budgie_breeding_tracker/data/models/message_model.dart';

void main() {
  group('Message model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final now = DateTime.utc(2026, 3, 15, 10, 30);
        final message = Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          senderId: 'user-1',
          senderName: 'Bekir',
          senderAvatarUrl: 'https://example.com/avatar.png',
          content: 'Hello!',
          messageType: MessageType.text,
          imageUrl: null,
          referenceId: 'ref-1',
          referenceData: const {'birdId': 'bird-1', 'name': 'Mavi'},
          readBy: const ['user-2', 'user-3'],
          isDeleted: false,
          createdAt: now,
        );

        final json = message.toJson();
        final restored = Message.fromJson(json);

        expect(restored.id, message.id);
        expect(restored.conversationId, message.conversationId);
        expect(restored.senderId, message.senderId);
        expect(restored.senderName, message.senderName);
        expect(restored.senderAvatarUrl, message.senderAvatarUrl);
        expect(restored.content, message.content);
        expect(restored.messageType, message.messageType);
        expect(restored.imageUrl, message.imageUrl);
        expect(restored.referenceId, message.referenceId);
        expect(restored.referenceData, message.referenceData);
        expect(restored.readBy, message.readBy);
        expect(restored.isDeleted, message.isDeleted);
        expect(restored.createdAt, message.createdAt);
      });

      test('unknown MessageType falls back to MessageType.unknown', () {
        final message = Message.fromJson(const {
          'id': 'msg-1',
          'conversation_id': 'conv-1',
          'sender_id': 'user-1',
          'message_type': 'video',
        });

        expect(message.messageType, MessageType.unknown);
      });

      test('defaults are correct', () {
        final message = Message.fromJson(const {
          'id': 'msg-1',
          'conversation_id': 'conv-1',
          'sender_id': 'user-1',
        });

        expect(message.senderName, '');
        expect(message.messageType, MessageType.text);
        expect(message.referenceData, isEmpty);
        expect(message.readBy, isEmpty);
        expect(message.isDeleted, false);
        expect(message.senderAvatarUrl, isNull);
        expect(message.content, isNull);
        expect(message.imageUrl, isNull);
        expect(message.referenceId, isNull);
        expect(message.createdAt, isNull);
      });
    });

    group('MessageX extension', () {
      test('isText returns true for text type', () {
        const message = Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          senderId: 'user-1',
          messageType: MessageType.text,
        );

        expect(message.isText, isTrue);
        expect(message.isImage, isFalse);
        expect(message.isBirdCard, isFalse);
        expect(message.isListingCard, isFalse);
      });

      test('isImage returns true for image type', () {
        const message = Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          senderId: 'user-1',
          messageType: MessageType.image,
        );

        expect(message.isImage, isTrue);
        expect(message.isText, isFalse);
      });

      test('isBirdCard returns true for birdCard type', () {
        const message = Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          senderId: 'user-1',
          messageType: MessageType.birdCard,
        );

        expect(message.isBirdCard, isTrue);
        expect(message.isText, isFalse);
        expect(message.isImage, isFalse);
        expect(message.isListingCard, isFalse);
      });

      test('isListingCard returns true for listingCard type', () {
        const message = Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          senderId: 'user-1',
          messageType: MessageType.listingCard,
        );

        expect(message.isListingCard, isTrue);
        expect(message.isText, isFalse);
        expect(message.isImage, isFalse);
        expect(message.isBirdCard, isFalse);
      });

      test('isReadBy returns true when userId is in readBy list', () {
        const message = Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          senderId: 'user-1',
          readBy: ['user-2', 'user-3'],
        );

        expect(message.isReadBy('user-2'), isTrue);
        expect(message.isReadBy('user-3'), isTrue);
      });

      test('isReadBy returns false when userId is not in readBy list', () {
        const message = Message(
          id: 'msg-1',
          conversationId: 'conv-1',
          senderId: 'user-1',
          readBy: ['user-2'],
        );

        expect(message.isReadBy('user-99'), isFalse);
        expect(message.isReadBy(''), isFalse);
      });
    });
  });
}
