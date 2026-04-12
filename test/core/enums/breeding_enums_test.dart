import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';

void main() {
  group('NestStatus', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in NestStatus.values) {
        expect(NestStatus.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(NestStatus.fromJson('invalid'), NestStatus.unknown);
      expect(NestStatus.fromJson(''), NestStatus.unknown);
      expect(NestStatus.fromJson('AVAILABLE'), NestStatus.unknown);
    });

    test('has expected value count', () {
      expect(NestStatus.values.length, 4);
    });
  });

  group('BreedingStatus', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in BreedingStatus.values) {
        expect(BreedingStatus.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(BreedingStatus.fromJson('invalid'), BreedingStatus.unknown);
    });

    test('has expected value count', () {
      expect(BreedingStatus.values.length, 5);
    });
  });

  group('IncubationStatus', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in IncubationStatus.values) {
        expect(IncubationStatus.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(IncubationStatus.fromJson('invalid'), IncubationStatus.unknown);
    });

    test('has expected value count', () {
      expect(IncubationStatus.values.length, 4);
    });
  });
}
