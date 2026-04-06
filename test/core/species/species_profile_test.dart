import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/species/species_profile.dart';

void main() {
  group('SpeciesProfile', () {
    test('supportsGenetics returns true for full mode', () {
      const profile = SpeciesProfile(
        species: Species.budgie,
        labelKey: 'test',
        helpTextKey: 'test',
        geneticsMode: GeneticsMode.full,
        supportedColors: [BirdColor.green],
        incubationPeriodDays: 18,
        candlingDay: 7,
        secondCheckDay: 14,
        sensitivePeriodDay: 16,
        expectedHatchDay: 18,
        lateHatchDay: 21,
        eggTurningHours: ['08:00', '14:00', '20:00'],
      );

      expect(profile.supportsGenetics, isTrue);
    });

    test('supportsGenetics returns true for limited mode', () {
      const profile = SpeciesProfile(
        species: Species.canary,
        labelKey: 'test',
        helpTextKey: 'test',
        geneticsMode: GeneticsMode.limited,
        supportedColors: [BirdColor.yellow],
        incubationPeriodDays: 13,
        candlingDay: 5,
        secondCheckDay: 10,
        sensitivePeriodDay: 11,
        expectedHatchDay: 13,
        lateHatchDay: 16,
        eggTurningHours: ['08:00', '14:00', '20:00'],
      );

      expect(profile.supportsGenetics, isTrue);
    });

    test('supportsGenetics returns false for none mode', () {
      const profile = SpeciesProfile(
        species: Species.finch,
        labelKey: 'test',
        helpTextKey: 'test',
        geneticsMode: GeneticsMode.none,
        supportedColors: [BirdColor.grey],
        incubationPeriodDays: 14,
        candlingDay: 5,
        secondCheckDay: 10,
        sensitivePeriodDay: 12,
        expectedHatchDay: 14,
        lateHatchDay: 16,
        eggTurningHours: ['08:00', '14:00', '20:00'],
      );

      expect(profile.supportsGenetics, isFalse);
    });
  });

  group('GeneticsMode', () {
    test('has expected value count', () {
      expect(GeneticsMode.values.length, 3);
    });
  });
}
