import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/gamification_enums.dart';

void main() {
  group('BadgeCategory', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in BadgeCategory.values) {
        expect(BadgeCategory.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(BadgeCategory.fromJson('invalid'), BadgeCategory.unknown);
      expect(BadgeCategory.fromJson(''), BadgeCategory.unknown);
    });

    test('has expected value count', () {
      expect(BadgeCategory.values.length, 7);
    });
  });

  group('BadgeTier', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in BadgeTier.values) {
        expect(BadgeTier.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(BadgeTier.fromJson('invalid'), BadgeTier.unknown);
      expect(BadgeTier.fromJson(''), BadgeTier.unknown);
    });

    test('has expected value count', () {
      expect(BadgeTier.values.length, 5);
    });
  });

  group('XpAction', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in XpAction.values) {
        expect(XpAction.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(XpAction.fromJson('invalid'), XpAction.unknown);
      expect(XpAction.fromJson(''), XpAction.unknown);
    });

    test('has expected value count', () {
      expect(XpAction.values.length, 13);
    });
  });
}
