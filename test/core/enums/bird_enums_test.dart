import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';

void main() {
  group('BirdGender', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in BirdGender.values) {
        expect(BirdGender.fromJson(value.toJson()), value);
      }
    });

    test('has expected value count', () {
      expect(BirdGender.values.length, 3);
    });
  });

  group('BirdStatus', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in BirdStatus.values) {
        expect(BirdStatus.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(BirdStatus.fromJson('invalid'), BirdStatus.unknown);
      expect(BirdStatus.fromJson(''), BirdStatus.unknown);
    });

    test('has expected value count', () {
      expect(BirdStatus.values.length, 4);
    });
  });

  group('Species', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in Species.values) {
        expect(Species.fromJson(value.toJson()), value);
      }
    });

    test('fromJson handles Turkish aliases', () {
      expect(Species.fromJson('muhabbet'), Species.budgie);
      expect(Species.fromJson('kanarya'), Species.canary);
      expect(Species.fromJson('sultan'), Species.cockatiel);
      expect(Species.fromJson('sultan_papaganı'), Species.cockatiel);
      expect(Species.fromJson('sultan_papagani'), Species.cockatiel);
      expect(Species.fromJson('ispinoz'), Species.finch);
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(Species.fromJson('invalid'), Species.unknown);
      expect(Species.fromJson(''), Species.unknown);
    });

    test('has expected value count', () {
      expect(Species.values.length, 6);
    });
  });

  group('BirdColor', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in BirdColor.values) {
        expect(BirdColor.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(BirdColor.fromJson('invalid'), BirdColor.unknown);
      expect(BirdColor.fromJson(''), BirdColor.unknown);
    });

    test('has expected value count', () {
      expect(BirdColor.values.length, 18);
    });
  });
}
