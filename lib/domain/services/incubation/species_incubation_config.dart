import 'package:budgie_breeding_tracker/core/constants/incubation_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/species/species_registry.dart';
import 'package:budgie_breeding_tracker/core/utils/date_utils.dart' as date_utils;

int incubationDaysForSpecies(Species species) =>
    SpeciesRegistry.of(species).incubationPeriodDays;

int incubationDaysFromDates({
  required DateTime? startDate,
  required DateTime? expectedHatchDate,
  Species species = Species.unknown,
}) {
  if (startDate != null && expectedHatchDate != null) {
    final diff = date_utils.DateUtils.dayDiff(startDate, expectedHatchDate);
    if (diff > 0) return diff;
  }
  return incubationDaysForSpecies(species);
}

List<String> eggTurningHoursForSpecies(Species species) =>
    SpeciesRegistry.of(species).eggTurningHours;

int incubationMilestoneCount = 5;

({
  int candlingDay,
  int secondCheckDay,
  int sensitivePeriodDay,
  int expectedHatchDay,
  int lateHatchDay,
})
incubationMilestonesForSpecies(Species species) {
  final profile = SpeciesRegistry.of(species);
  return (
    candlingDay: profile.candlingDay,
    secondCheckDay: profile.secondCheckDay,
    sensitivePeriodDay: profile.sensitivePeriodDay,
    expectedHatchDay: profile.expectedHatchDay,
    lateHatchDay: profile.lateHatchDay,
  );
}

int fallbackIncubationDays() => IncubationConstants.incubationPeriodDays;
