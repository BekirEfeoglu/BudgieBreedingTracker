import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/incubation_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/species_incubation_config.dart';

void main() {
  group('incubationDaysForSpecies', () {
    test('returns 18 for budgie', () {
      expect(incubationDaysForSpecies(Species.budgie), 18);
    });

    test('returns 13 for canary', () {
      expect(incubationDaysForSpecies(Species.canary), 13);
    });

    test('returns 19 for cockatiel', () {
      expect(incubationDaysForSpecies(Species.cockatiel), 19);
    });

    test('returns 14 for finch', () {
      expect(incubationDaysForSpecies(Species.finch), 14);
    });

    test('returns 18 for other', () {
      expect(incubationDaysForSpecies(Species.other), 18);
    });

    test('returns 18 for unknown', () {
      expect(incubationDaysForSpecies(Species.unknown), 18);
    });
  });

  group('incubationDaysFromDates', () {
    test('calculates difference when both dates are provided', () {
      final start = DateTime(2026, 1, 1);
      final hatch = DateTime(2026, 1, 19);
      final result = incubationDaysFromDates(
        startDate: start,
        expectedHatchDate: hatch,
      );
      expect(result, 18);
    });

    test('returns species default when startDate is null', () {
      final result = incubationDaysFromDates(
        startDate: null,
        expectedHatchDate: DateTime(2026, 1, 19),
        species: Species.canary,
      );
      expect(result, 13);
    });

    test('returns species default when expectedHatchDate is null', () {
      final result = incubationDaysFromDates(
        startDate: DateTime(2026, 1, 1),
        expectedHatchDate: null,
        species: Species.finch,
      );
      expect(result, 14);
    });

    test('returns species default when both dates are null', () {
      final result = incubationDaysFromDates(
        startDate: null,
        expectedHatchDate: null,
        species: Species.cockatiel,
      );
      expect(result, 19);
    });

    test('returns species default when difference is zero or negative', () {
      final start = DateTime(2026, 1, 20);
      final hatch = DateTime(2026, 1, 10);
      final result = incubationDaysFromDates(
        startDate: start,
        expectedHatchDate: hatch,
        species: Species.budgie,
      );
      expect(result, 18);
    });

    test('returns species default when dates are the same day', () {
      final date = DateTime(2026, 1, 15);
      final result = incubationDaysFromDates(
        startDate: date,
        expectedHatchDate: date,
        species: Species.budgie,
      );
      expect(result, 18);
    });

    test('defaults to unknown species when not specified', () {
      final result = incubationDaysFromDates(
        startDate: null,
        expectedHatchDate: null,
      );
      // Species.unknown defaults to 18
      expect(result, 18);
    });
  });

  group('incubationMilestonesForSpecies', () {
    test('returns 5 milestone fields for budgie', () {
      final milestones = incubationMilestonesForSpecies(Species.budgie);
      expect(milestones.candlingDay, 7);
      expect(milestones.secondCheckDay, 14);
      expect(milestones.sensitivePeriodDay, 16);
      expect(milestones.expectedHatchDay, 18);
      expect(milestones.lateHatchDay, 21);
    });

    test('returns correct milestones for canary', () {
      final milestones = incubationMilestonesForSpecies(Species.canary);
      expect(milestones.candlingDay, 5);
      expect(milestones.secondCheckDay, 10);
      expect(milestones.sensitivePeriodDay, 11);
      expect(milestones.expectedHatchDay, 13);
      expect(milestones.lateHatchDay, 16);
    });

    test('returns correct milestones for cockatiel', () {
      final milestones = incubationMilestonesForSpecies(Species.cockatiel);
      expect(milestones.candlingDay, 7);
      expect(milestones.secondCheckDay, 14);
      expect(milestones.sensitivePeriodDay, 17);
      expect(milestones.expectedHatchDay, 19);
      expect(milestones.lateHatchDay, 23);
    });

    test('incubationMilestoneCount is 5', () {
      expect(incubationMilestoneCount, 5);
    });
  });

  group('fallbackIncubationDays', () {
    test('returns IncubationConstants.incubationPeriodDays', () {
      expect(
        fallbackIncubationDays(),
        IncubationConstants.incubationPeriodDays,
      );
    });

    test('returns 18', () {
      expect(fallbackIncubationDays(), 18);
    });
  });

  group('eggTurningHoursForSpecies', () {
    test('returns 3 turning hours for budgie', () {
      final hours = eggTurningHoursForSpecies(Species.budgie);
      expect(hours, hasLength(3));
    });

    test('returns default turning hours for all species', () {
      const expected = ['08:00', '14:00', '20:00'];
      for (final species in Species.values) {
        expect(
          eggTurningHoursForSpecies(species),
          expected,
          reason: 'Expected default turning hours for $species',
        );
      }
    });

    test('returns list of String', () {
      final hours = eggTurningHoursForSpecies(Species.budgie);
      expect(hours, isA<List<String>>());
      for (final hour in hours) {
        expect(hour, matches(RegExp(r'^\d{2}:\d{2}$')));
      }
    });
  });
}
