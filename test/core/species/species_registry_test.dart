import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/species/species_profile.dart';
import 'package:budgie_breeding_tracker/core/species/species_registry.dart';

void main() {
  group('SpeciesRegistry', () {
    test('of returns correct profile for each supported species', () {
      expect(SpeciesRegistry.of(Species.budgie).species, Species.budgie);
      expect(SpeciesRegistry.of(Species.canary).species, Species.canary);
      expect(SpeciesRegistry.of(Species.cockatiel).species, Species.cockatiel);
      expect(SpeciesRegistry.of(Species.finch).species, Species.finch);
      expect(SpeciesRegistry.of(Species.other).species, Species.other);
    });

    test('of returns unknown profile for Species.unknown', () {
      final profile = SpeciesRegistry.of(Species.unknown);
      expect(profile.species, Species.unknown);
    });

    test('supportedProfiles has expected count', () {
      expect(SpeciesRegistry.supportedProfiles.length, 5);
    });

    test('supportedSpecies returns list without unknown', () {
      final species = SpeciesRegistry.supportedSpecies;
      expect(species, contains(Species.budgie));
      expect(species, contains(Species.canary));
      expect(species, contains(Species.cockatiel));
      expect(species, contains(Species.finch));
      expect(species, contains(Species.other));
      expect(species, isNot(contains(Species.unknown)));
    });

    test('budgie profile has full genetics mode', () {
      expect(SpeciesRegistry.budgie.geneticsMode, GeneticsMode.full);
      expect(SpeciesRegistry.budgie.supportsGenetics, isTrue);
    });

    test('canary profile has limited genetics mode', () {
      expect(SpeciesRegistry.canary.geneticsMode, GeneticsMode.limited);
      expect(SpeciesRegistry.canary.supportsGenetics, isTrue);
    });

    test('finch profile has no genetics mode', () {
      expect(SpeciesRegistry.finch.geneticsMode, GeneticsMode.none);
      expect(SpeciesRegistry.finch.supportsGenetics, isFalse);
    });

    test('budgie incubation period is 18 days', () {
      expect(SpeciesRegistry.budgie.incubationPeriodDays, 18);
      expect(SpeciesRegistry.budgie.expectedHatchDay, 18);
      expect(SpeciesRegistry.budgie.lateHatchDay, 21);
    });

    test('canary incubation period is 13 days', () {
      expect(SpeciesRegistry.canary.incubationPeriodDays, 13);
      expect(SpeciesRegistry.canary.expectedHatchDay, 13);
    });

    test('cockatiel incubation period is 19 days', () {
      expect(SpeciesRegistry.cockatiel.incubationPeriodDays, 19);
      expect(SpeciesRegistry.cockatiel.expectedHatchDay, 19);
    });

    test('all profiles have egg turning hours', () {
      for (final profile in SpeciesRegistry.supportedProfiles) {
        expect(profile.eggTurningHours, isNotEmpty);
      }
    });
  });
}
