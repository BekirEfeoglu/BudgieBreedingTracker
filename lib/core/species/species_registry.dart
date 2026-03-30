import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/species/species_profile.dart';

abstract final class SpeciesRegistry {
  static const List<String> _defaultTurningHours = ['08:00', '14:00', '20:00'];

  static const SpeciesProfile budgie = SpeciesProfile(
    species: Species.budgie,
    labelKey: 'birds.budgie',
    helpTextKey: 'birds.species_help_budgie',
    geneticsMode: GeneticsMode.full,
    supportedColors: [
      BirdColor.green,
      BirdColor.blue,
      BirdColor.yellow,
      BirdColor.white,
      BirdColor.grey,
      BirdColor.violet,
      BirdColor.lutino,
      BirdColor.albino,
      BirdColor.cinnamon,
      BirdColor.opaline,
      BirdColor.spangle,
      BirdColor.pied,
      BirdColor.clearwing,
      BirdColor.other,
    ],
    incubationPeriodDays: 18,
    candlingDay: 7,
    secondCheckDay: 14,
    sensitivePeriodDay: 16,
    expectedHatchDay: 18,
    lateHatchDay: 21,
    eggTurningHours: _defaultTurningHours,
  );

  static const SpeciesProfile canary = SpeciesProfile(
    species: Species.canary,
    labelKey: 'birds.canary',
    helpTextKey: 'birds.species_help_canary',
    geneticsMode: GeneticsMode.limited,
    supportedColors: [
      BirdColor.green,
      BirdColor.yellow,
      BirdColor.red,
      BirdColor.white,
      BirdColor.cinnamon,
      BirdColor.lutino,
      BirdColor.pied,
      BirdColor.other,
    ],
    incubationPeriodDays: 13,
    candlingDay: 5,
    secondCheckDay: 10,
    sensitivePeriodDay: 11,
    expectedHatchDay: 13,
    lateHatchDay: 16,
    eggTurningHours: _defaultTurningHours,
  );

  static const SpeciesProfile cockatiel = SpeciesProfile(
    species: Species.cockatiel,
    labelKey: 'birds.cockatiel',
    helpTextKey: 'birds.species_help_cockatiel',
    geneticsMode: GeneticsMode.limited,
    supportedColors: [
      BirdColor.grey,
      BirdColor.white,
      BirdColor.yellow,
      BirdColor.lutino,
      BirdColor.cinnamon,
      BirdColor.pearl,
      BirdColor.whiteface,
      BirdColor.pied,
      BirdColor.other,
    ],
    incubationPeriodDays: 19,
    candlingDay: 7,
    secondCheckDay: 14,
    sensitivePeriodDay: 17,
    expectedHatchDay: 19,
    lateHatchDay: 23,
    eggTurningHours: _defaultTurningHours,
  );

  static const SpeciesProfile finch = SpeciesProfile(
    species: Species.finch,
    labelKey: 'birds.finch',
    helpTextKey: 'birds.species_help_finch',
    geneticsMode: GeneticsMode.none,
    supportedColors: [BirdColor.grey, BirdColor.white, BirdColor.other],
    incubationPeriodDays: 14,
    candlingDay: 5,
    secondCheckDay: 10,
    sensitivePeriodDay: 12,
    expectedHatchDay: 14,
    lateHatchDay: 16,
    eggTurningHours: _defaultTurningHours,
  );

  static const SpeciesProfile other = SpeciesProfile(
    species: Species.other,
    labelKey: 'birds.other_species',
    helpTextKey: 'birds.species_help_other',
    geneticsMode: GeneticsMode.none,
    supportedColors: [BirdColor.other],
    incubationPeriodDays: 18,
    candlingDay: 7,
    secondCheckDay: 14,
    sensitivePeriodDay: 16,
    expectedHatchDay: 18,
    lateHatchDay: 21,
    eggTurningHours: _defaultTurningHours,
  );

  static const SpeciesProfile unknown = SpeciesProfile(
    species: Species.unknown,
    labelKey: 'common.unknown',
    helpTextKey: 'birds.species_help_other',
    geneticsMode: GeneticsMode.none,
    supportedColors: [BirdColor.other],
    incubationPeriodDays: 18,
    candlingDay: 7,
    secondCheckDay: 14,
    sensitivePeriodDay: 16,
    expectedHatchDay: 18,
    lateHatchDay: 21,
    eggTurningHours: _defaultTurningHours,
  );

  static const List<SpeciesProfile> supportedProfiles = [
    budgie,
    canary,
    cockatiel,
    finch,
    other,
  ];

  static SpeciesProfile of(Species species) {
    for (final profile in supportedProfiles) {
      if (profile.species == species) return profile;
    }
    return unknown;
  }

  static List<Species> get supportedSpecies =>
      supportedProfiles.map((profile) => profile.species).toList();
}
