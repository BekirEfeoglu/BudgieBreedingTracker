@Tags(['messaging'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/models/conversation_participant_model.dart';
import 'package:budgie_breeding_tracker/core/enums/messaging_enums.dart';

void main() {
  group('ConversationParticipant', () {
    test('toJson/fromJson round-trip', () {
      final participant = ConversationParticipant(
        conversationId: 'conv-1',
        userId: 'user-1',
        role: ParticipantRole.admin,
        joinedAt: DateTime.utc(2026, 1, 15),
        lastReadAt: DateTime.utc(2026, 2, 10),
        isMuted: true,
        isLeft: false,
      );

      final json = participant.toJson();
      final restored = ConversationParticipant.fromJson(json);

      expect(restored.conversationId, participant.conversationId);
      expect(restored.userId, participant.userId);
      expect(restored.role, participant.role);
      expect(restored.joinedAt, participant.joinedAt);
      expect(restored.lastReadAt, participant.lastReadAt);
      expect(restored.isMuted, participant.isMuted);
      expect(restored.isLeft, participant.isLeft);
    });

    test('deserializes unknown role to unknown', () {
      final json = {
        'conversation_id': 'conv-1',
        'user_id': 'user-1',
        'role': 'superadmin',
      };
      final participant = ConversationParticipant.fromJson(json);
      expect(participant.role, ParticipantRole.unknown);
    });

    test('default values are correct', () {
      const participant = ConversationParticipant(
        conversationId: 'conv-1',
        userId: 'user-1',
      );
      expect(participant.role, ParticipantRole.member);
      expect(participant.joinedAt, isNull);
      expect(participant.lastReadAt, isNull);
      expect(participant.isMuted, false);
      expect(participant.isLeft, false);
    });

    group('ConversationParticipantX', () {
      test('isOwner returns true for owner role', () {
        const participant = ConversationParticipant(
          conversationId: 'conv-1',
          userId: 'user-1',
          role: ParticipantRole.owner,
        );
        expect(participant.isOwner, isTrue);
        expect(participant.isAdmin, isTrue);
      });

      test('isAdmin returns true for admin and owner roles', () {
        const admin = ConversationParticipant(
          conversationId: 'conv-1',
          userId: 'user-1',
          role: ParticipantRole.admin,
        );
        expect(admin.isAdmin, isTrue);
        expect(admin.isOwner, isFalse);

        const member = ConversationParticipant(
          conversationId: 'conv-1',
          userId: 'user-2',
          role: ParticipantRole.member,
        );
        expect(member.isAdmin, isFalse);
      });

      test('isActive returns false when isLeft is true', () {
        const participant = ConversationParticipant(
          conversationId: 'conv-1',
          userId: 'user-1',
          isLeft: true,
        );
        expect(participant.isActive, isFalse);
      });

      test('isActive returns true when isLeft is false', () {
        const participant = ConversationParticipant(
          conversationId: 'conv-1',
          userId: 'user-1',
        );
        expect(participant.isActive, isTrue);
      });
    });
  });
}
