import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_milestone.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/species_incubation_config.dart';

void main() {
  group('incubationDaysFromDates', () {
    test('returns species default when no dates provided', () {
      expect(
        incubationDaysFromDates(
          startDate: null,
          expectedHatchDate: null,
          species: Species.canary,
        ),
        13,
      );
      expect(
        incubationDaysFromDates(
          startDate: null,
          expectedHatchDate: null,
          species: Species.cockatiel,
        ),
        19,
      );
    });

    test('prefers stored dates over species default', () {
      // Old canary record created with 14-day period
      final result = incubationDaysFromDates(
        startDate: DateTime(2026, 1, 1),
        expectedHatchDate: DateTime(2026, 1, 15), // 14 days
        species: Species.canary,
      );
      expect(result, 14, reason: 'stored dates should take precedence');
    });

    test('falls back to species default for invalid date diff', () {
      final result = incubationDaysFromDates(
        startDate: DateTime(2026, 1, 15),
        expectedHatchDate: DateTime(2026, 1, 1), // negative diff
        species: Species.canary,
      );
      expect(result, 13);
    });
  });

  group('incubationDaysForSpecies', () {
    test('returns correct days for each species', () {
      expect(incubationDaysForSpecies(Species.budgie), 18);
      expect(incubationDaysForSpecies(Species.canary), 13);
      expect(incubationDaysForSpecies(Species.cockatiel), 19);
      expect(incubationDaysForSpecies(Species.finch), 14);
      expect(incubationDaysForSpecies(Species.other), 18);
      expect(incubationDaysForSpecies(Species.unknown), 18);
    });
  });

  group('IncubationCalculator', () {
    group('getStageColor', () {
      test('returns stageNew for day 0', () {
        expect(
          IncubationCalculator.getStageColor(0),
          equals(AppColors.stageNew),
        );
      });

      test('returns stageNew for days 1-6', () {
        expect(
          IncubationCalculator.getStageColor(3),
          equals(AppColors.stageNew),
        );
      });

      test('returns stageOngoing for days 7-15 (candling to sensitive)', () {
        expect(
          IncubationCalculator.getStageColor(7),
          equals(AppColors.stageOngoing),
        );
        expect(
          IncubationCalculator.getStageColor(10),
          equals(AppColors.stageOngoing),
        );
      });

      test('returns stageNearHatch for days 16-18 (sensitive period)', () {
        expect(
          IncubationCalculator.getStageColor(16),
          equals(AppColors.stageNearHatch),
        );
        expect(
          IncubationCalculator.getStageColor(18),
          equals(AppColors.stageNearHatch),
        );
      });

      test('returns stageOverdue for days > 18', () {
        expect(
          IncubationCalculator.getStageColor(19),
          equals(AppColors.stageOverdue),
        );
        expect(
          IncubationCalculator.getStageColor(25),
          equals(AppColors.stageOverdue),
        );
      });

      test('supports species-aware stage thresholds', () {
        // Canary: sensitivePeriodDay=11, expectedHatchDay=13
        expect(
          IncubationCalculator.getStageColor(11, species: Species.canary),
          equals(AppColors.stageNearHatch),
        );
        expect(
          IncubationCalculator.getStageColor(14, species: Species.canary),
          equals(AppColors.stageOverdue),
        );
      });
    });

    group('getStageLabel', () {
      test('returns stage_new key for early days', () {
        expect(IncubationCalculator.getStageLabel(0), 'incubation.stage_new');
        expect(IncubationCalculator.getStageLabel(5), 'incubation.stage_new');
      });

      test('returns stage_ongoing key for candling period', () {
        expect(
          IncubationCalculator.getStageLabel(7),
          'incubation.stage_ongoing',
        );
        expect(
          IncubationCalculator.getStageLabel(15),
          'incubation.stage_ongoing',
        );
      });

      test('returns stage_near_hatch key for sensitive period', () {
        expect(
          IncubationCalculator.getStageLabel(16),
          'incubation.stage_near_hatch',
        );
        expect(
          IncubationCalculator.getStageLabel(18),
          'incubation.stage_near_hatch',
        );
      });

      test('returns stage_overdue key for overdue', () {
        expect(
          IncubationCalculator.getStageLabel(19),
          'incubation.stage_overdue',
        );
        expect(
          IncubationCalculator.getStageLabel(25),
          'incubation.stage_overdue',
        );
      });

      test('supports totalDays-based fallback thresholds', () {
        expect(
          IncubationCalculator.getStageLabel(12, totalDays: 14),
          'incubation.stage_near_hatch',
        );
      });
    });

    group('getCompletedStageColor', () {
      test('returns stageCompleted color', () {
        expect(
          IncubationCalculator.getCompletedStageColor(),
          equals(AppColors.stageCompleted),
        );
      });
    });

    group('getMilestones', () {
      test('returns exactly 5 milestones', () {
        final startDate = DateTime(2025, 1, 1);
        final milestones = IncubationCalculator.getMilestones(startDate);
        expect(milestones, hasLength(5));
      });

      test('milestones are in chronological order', () {
        final startDate = DateTime(2025, 1, 1);
        final milestones = IncubationCalculator.getMilestones(startDate);
        for (int i = 1; i < milestones.length; i++) {
          expect(milestones[i].day, greaterThan(milestones[i - 1].day));
        }
      });

      test('milestone days match constants', () {
        final startDate = DateTime(2025, 1, 1);
        final milestones = IncubationCalculator.getMilestones(startDate);
        expect(milestones[0].day, 7); // candling
        expect(milestones[1].day, 14); // second check
        expect(milestones[2].day, 16); // sensitive
        expect(milestones[3].day, 18); // expected hatch
        expect(milestones[4].day, 21); // late hatch
      });

      test('supports species-aware milestone days', () {
        final startDate = DateTime(2025, 1, 1);
        final milestones = IncubationCalculator.getMilestones(
          startDate,
          species: Species.canary,
        );
        // Canary: candling=5, secondCheck=10, sensitive=11, hatch=13, late=16
        expect(milestones[0].day, 5);
        expect(milestones[1].day, 10);
        expect(milestones[2].day, 11);
        expect(milestones[3].day, 13);
        expect(milestones[4].day, 16);
      });

      test('cockatiel has correct milestone days including late=23', () {
        final startDate = DateTime(2025, 1, 1);
        final milestones = IncubationCalculator.getMilestones(
          startDate,
          species: Species.cockatiel,
        );
        // Cockatiel: candling=7, secondCheck=14, sensitive=17, hatch=19, late=23
        expect(milestones[0].day, 7);
        expect(milestones[1].day, 14);
        expect(milestones[2].day, 17);
        expect(milestones[3].day, 19);
        expect(milestones[4].day, 23);
      });

      test('milestone dates are correctly offset from start', () {
        final startDate = DateTime(2025, 6, 1);
        final milestones = IncubationCalculator.getMilestones(startDate);
        expect(milestones[0].date, DateTime(2025, 6, 8)); // +7 days
        expect(milestones[3].date, DateTime(2025, 6, 19)); // +18 days
      });

      test('milestone types are correct', () {
        final startDate = DateTime(2025, 1, 1);
        final milestones = IncubationCalculator.getMilestones(startDate);
        expect(milestones[0].type, MilestoneType.candling);
        expect(milestones[1].type, MilestoneType.check);
        expect(milestones[2].type, MilestoneType.sensitive);
        expect(milestones[3].type, MilestoneType.hatch);
        expect(milestones[4].type, MilestoneType.late);
      });

      test('past milestones have isPassed true', () {
        // Start date far in the past - all milestones should be passed
        final startDate = DateTime(2020, 1, 1);
        final milestones = IncubationCalculator.getMilestones(startDate);
        for (final m in milestones) {
          expect(m.isPassed, isTrue);
        }
      });

      test('future milestones have isPassed false', () {
        // Start date far in the future
        final startDate = DateTime(2030, 1, 1);
        final milestones = IncubationCalculator.getMilestones(startDate);
        for (final m in milestones) {
          expect(m.isPassed, isFalse);
        }
      });
    });

    group('getNextMilestone', () {
      test('returns first milestone for future start', () {
        final startDate = DateTime(2030, 1, 1);
        final next = IncubationCalculator.getNextMilestone(startDate);
        expect(next, isNotNull);
        expect(next!.type, MilestoneType.candling);
      });

      test('returns null when all milestones passed', () {
        final startDate = DateTime(2020, 1, 1);
        final next = IncubationCalculator.getNextMilestone(startDate);
        expect(next, isNull);
      });
    });

    group('isTemperatureValid', () {
      test('returns true for optimal temperature', () {
        expect(IncubationCalculator.isTemperatureValid(37.5), isTrue);
      });

      test('returns true for min boundary', () {
        expect(IncubationCalculator.isTemperatureValid(37.0), isTrue);
      });

      test('returns true for max boundary', () {
        expect(IncubationCalculator.isTemperatureValid(38.0), isTrue);
      });

      test('returns false for too low', () {
        expect(IncubationCalculator.isTemperatureValid(36.9), isFalse);
      });

      test('returns false for too high', () {
        expect(IncubationCalculator.isTemperatureValid(38.1), isFalse);
      });
    });

    group('isHumidityValid', () {
      test('returns true for optimal humidity', () {
        expect(IncubationCalculator.isHumidityValid(60.0), isTrue);
      });

      test('returns true for min boundary (55%)', () {
        expect(IncubationCalculator.isHumidityValid(55.0), isTrue);
      });

      test('returns true for max boundary (65%)', () {
        expect(IncubationCalculator.isHumidityValid(65.0), isTrue);
      });

      test('returns false for below range', () {
        expect(IncubationCalculator.isHumidityValid(54.9), isFalse);
      });

      test('returns false for above range', () {
        expect(IncubationCalculator.isHumidityValid(65.1), isFalse);
      });
    });

    group('getNextEggNumber', () {
      test('returns 1 for empty list', () {
        expect(IncubationCalculator.getNextEggNumber([]), 1);
      });

      test('returns max + 1 for existing eggs', () {
        final eggs = [
          _createEgg(eggNumber: 1),
          _createEgg(eggNumber: 3),
          _createEgg(eggNumber: 2),
        ];
        expect(IncubationCalculator.getNextEggNumber(eggs), 4);
      });

      test('handles eggs with null eggNumber', () {
        final eggs = [_createEgg(eggNumber: null), _createEgg(eggNumber: 2)];
        expect(IncubationCalculator.getNextEggNumber(eggs), 3);
      });

      test('returns 1 when all eggNumbers are null', () {
        final eggs = [_createEgg(eggNumber: null), _createEgg(eggNumber: null)];
        expect(IncubationCalculator.getNextEggNumber(eggs), 1);
      });
    });

    group('getValidStatusTransitions', () {
      test('laid can transition to fertile, infertile, damaged, discarded', () {
        final transitions = IncubationCalculator.getValidStatusTransitions(
          EggStatus.laid,
        );
        expect(
          transitions,
          containsAll([
            EggStatus.fertile,
            EggStatus.infertile,
            EggStatus.damaged,
            EggStatus.discarded,
          ]),
        );
        expect(transitions, hasLength(4));
      });

      test('fertile can transition to incubating, damaged, discarded', () {
        final transitions = IncubationCalculator.getValidStatusTransitions(
          EggStatus.fertile,
        );
        expect(
          transitions,
          containsAll([
            EggStatus.incubating,
            EggStatus.damaged,
            EggStatus.discarded,
          ]),
        );
        expect(transitions, hasLength(3));
      });

      test('incubating can transition to hatched, damaged, discarded', () {
        final transitions = IncubationCalculator.getValidStatusTransitions(
          EggStatus.incubating,
        );
        expect(
          transitions,
          containsAll([
            EggStatus.hatched,
            EggStatus.damaged,
            EggStatus.discarded,
          ]),
        );
        expect(transitions, hasLength(3));
      });

      test('terminal states have no transitions', () {
        expect(
          IncubationCalculator.getValidStatusTransitions(EggStatus.hatched),
          isEmpty,
        );
        expect(
          IncubationCalculator.getValidStatusTransitions(EggStatus.damaged),
          isEmpty,
        );
        expect(
          IncubationCalculator.getValidStatusTransitions(EggStatus.discarded),
          isEmpty,
        );
        expect(
          IncubationCalculator.getValidStatusTransitions(EggStatus.infertile),
          isEmpty,
        );
      });

      test('unknown status has no transitions', () {
        expect(
          IncubationCalculator.getValidStatusTransitions(EggStatus.unknown),
          isEmpty,
        );
      });
    });
  });
}

/// Helper to create a minimal Egg for testing.
Egg _createEgg({int? eggNumber}) {
  return Egg(
    id: 'egg-${eggNumber ?? 0}',
    layDate: DateTime(2025, 1, 1),
    userId: 'user-1',
    eggNumber: eggNumber,
    status: EggStatus.laid,
  );
}
