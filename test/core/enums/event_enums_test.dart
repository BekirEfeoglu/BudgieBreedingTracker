import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';

void main() {
  group('EventType', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in EventType.values) {
        expect(EventType.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(EventType.fromJson('invalid'), EventType.unknown);
      expect(EventType.fromJson(''), EventType.unknown);
    });

    test('has at least 17 values', () {
      expect(EventType.values.length, greaterThanOrEqualTo(17));
    });
  });

  group('EventStatus', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in EventStatus.values) {
        expect(EventStatus.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(EventStatus.fromJson('invalid'), EventStatus.unknown);
      expect(EventStatus.fromJson('done'), EventStatus.unknown);
    });

    test('has expected value count', () {
      expect(EventStatus.values.length, 5);
    });
  });
}
