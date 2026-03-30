import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/features/birds/utils/bird_display_utils.dart';

void main() {
  group('speciesLabel', () {
    test('returns non-empty label for all species values', () {
      for (final species in Species.values) {
        expect(speciesLabel(species), isNotEmpty);
      }
    });

    test('distinguishes unknown from other', () {
      expect(speciesLabel(Species.unknown), isNot(speciesLabel(Species.other)));
    });
  });

  group('formatBirdAge', () {
    test('returns non-empty age string for years branch', () {
      final result = formatBirdAge((years: 2, months: 3, days: 0));
      expect(result, isNotEmpty);
    });

    test('returns non-empty age string for months branch', () {
      final result = formatBirdAge((years: 0, months: 5, days: 10));
      expect(result, isNotEmpty);
    });

    test('returns non-empty age string for days branch', () {
      final result = formatBirdAge((years: 0, months: 0, days: 8));
      expect(result, isNotEmpty);
    });
  });

  group('formatBirdAgeShort', () {
    test('returns non-empty short age string for years branch', () {
      final result = formatBirdAgeShort((years: 1, months: 2, days: 0));
      expect(result, isNotEmpty);
    });

    test('returns non-empty short age string for months branch', () {
      final result = formatBirdAgeShort((years: 0, months: 4, days: 15));
      expect(result, isNotEmpty);
    });

    test('returns non-empty short age string for days branch', () {
      final result = formatBirdAgeShort((years: 0, months: 0, days: 3));
      expect(result, isNotEmpty);
    });
  });
}
