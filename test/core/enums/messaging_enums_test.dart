import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/messaging_enums.dart';

void main() {
  group('ConversationType', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in ConversationType.values) {
        expect(ConversationType.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(ConversationType.fromJson('invalid'), ConversationType.unknown);
      expect(ConversationType.fromJson(''), ConversationType.unknown);
    });

    test('has expected value count', () {
      expect(ConversationType.values.length, 3);
    });
  });

  group('MessageType', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in MessageType.values) {
        expect(MessageType.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(MessageType.fromJson('invalid'), MessageType.unknown);
      expect(MessageType.fromJson(''), MessageType.unknown);
    });

    test('has expected value count', () {
      expect(MessageType.values.length, 5);
    });
  });

  group('ParticipantRole', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in ParticipantRole.values) {
        expect(ParticipantRole.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(ParticipantRole.fromJson('invalid'), ParticipantRole.unknown);
      expect(ParticipantRole.fromJson(''), ParticipantRole.unknown);
    });

    test('has expected value count', () {
      expect(ParticipantRole.values.length, 4);
    });
  });
}
