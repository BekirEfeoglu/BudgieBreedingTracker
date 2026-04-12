import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/incubation_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/species_incubation_config.dart';

import 'incubation_milestone.dart';

/// Static utility class for incubation-related calculations.
///
/// Provides stage colors, milestone generation, validation helpers,
/// and egg status transition rules for the breeding module.
abstract class IncubationCalculator {
  static ({
    int candlingDay,
    int secondCheckDay,
    int sensitivePeriodDay,
    int expectedHatchDay,
    int lateHatchDay,
  })
  _resolveMilestones({Species? species, int? totalDays}) {
    if (species != null) {
      return incubationMilestonesForSpecies(species);
    }

    final resolvedTotalDays =
        totalDays ?? IncubationConstants.incubationPeriodDays;
    if (resolvedTotalDays == IncubationConstants.incubationPeriodDays) {
      return incubationMilestonesForSpecies(Species.unknown);
    }

    final candlingDay = (resolvedTotalDays * 0.39).round().clamp(
      1,
      resolvedTotalDays,
    );
    final secondCheckDay = (resolvedTotalDays * 0.78).round().clamp(
      candlingDay + 1,
      resolvedTotalDays,
    );
    final sensitivePeriodDay = (resolvedTotalDays - 2).clamp(
      secondCheckDay,
      resolvedTotalDays,
    );
    return (
      candlingDay: candlingDay,
      secondCheckDay: secondCheckDay,
      sensitivePeriodDay: sensitivePeriodDay,
      expectedHatchDay: resolvedTotalDays,
      lateHatchDay: resolvedTotalDays + 3,
    );
  }

  /// Returns the stage color based on elapsed incubation days.
  static Color getStageColor(
    int daysElapsed, {
    Species? species,
    int? totalDays,
  }) {
    final milestones = _resolveMilestones(
      species: species,
      totalDays: totalDays,
    );
    if (daysElapsed > milestones.expectedHatchDay) {
      return AppColors.stageOverdue;
    }
    if (daysElapsed >= milestones.sensitivePeriodDay) {
      return AppColors.stageNearHatch;
    }
    if (daysElapsed >= milestones.candlingDay) {
      return AppColors.stageOngoing;
    }
    if (daysElapsed > 0) {
      return AppColors.stageNew;
    }
    return AppColors.stageNew;
  }

  /// Returns a human-readable stage label based on elapsed days.
  static String getStageLabel(
    int daysElapsed, {
    Species? species,
    int? totalDays,
  }) {
    final milestones = _resolveMilestones(
      species: species,
      totalDays: totalDays,
    );
    if (daysElapsed > milestones.expectedHatchDay) {
      return 'incubation.stage_overdue'.tr();
    }
    if (daysElapsed >= milestones.sensitivePeriodDay) {
      return 'incubation.stage_near_hatch'.tr();
    }
    if (daysElapsed >= milestones.candlingDay) {
      return 'incubation.stage_ongoing'.tr();
    }
    return 'incubation.stage_new'.tr();
  }

  /// Returns the stage color for a completed incubation.
  static Color getCompletedStageColor() => AppColors.stageCompleted;

  /// Generates all milestones for an incubation starting at [startDate].
  static List<IncubationMilestone> getMilestones(
    DateTime startDate, {
    Species? species,
    int? totalDays,
  }) {
    final now = DateTime.now();
    final milestones = _resolveMilestones(
      species: species,
      totalDays: totalDays,
    );
    return [
      IncubationMilestone(
        day: milestones.candlingDay,
        title: 'incubation.milestone_candling'.tr(),
        description: 'incubation.milestone_candling_desc'.tr(),
        type: MilestoneType.candling,
        date: startDate.add(Duration(days: milestones.candlingDay)),
        isPassed: now.isAfter(
          startDate.add(Duration(days: milestones.candlingDay)),
        ),
      ),
      IncubationMilestone(
        day: milestones.secondCheckDay,
        title: 'incubation.milestone_second_check'.tr(),
        description: 'incubation.milestone_second_check_desc'.tr(),
        type: MilestoneType.check,
        date: startDate.add(Duration(days: milestones.secondCheckDay)),
        isPassed: now.isAfter(
          startDate.add(Duration(days: milestones.secondCheckDay)),
        ),
      ),
      IncubationMilestone(
        day: milestones.sensitivePeriodDay,
        title: 'incubation.milestone_sensitive'.tr(),
        description: 'incubation.milestone_sensitive_desc'.tr(),
        type: MilestoneType.sensitive,
        date: startDate.add(Duration(days: milestones.sensitivePeriodDay)),
        isPassed: now.isAfter(
          startDate.add(Duration(days: milestones.sensitivePeriodDay)),
        ),
      ),
      IncubationMilestone(
        day: milestones.expectedHatchDay,
        title: 'incubation.milestone_hatch'.tr(),
        description: 'incubation.milestone_hatch_desc'.tr(),
        type: MilestoneType.hatch,
        date: startDate.add(Duration(days: milestones.expectedHatchDay)),
        isPassed: now.isAfter(
          startDate.add(Duration(days: milestones.expectedHatchDay)),
        ),
      ),
      IncubationMilestone(
        day: milestones.lateHatchDay,
        title: 'incubation.milestone_late'.tr(),
        description: 'incubation.milestone_late_desc'.tr(),
        type: MilestoneType.late,
        date: startDate.add(Duration(days: milestones.lateHatchDay)),
        isPassed: now.isAfter(
          startDate.add(Duration(days: milestones.lateHatchDay)),
        ),
      ),
    ];
  }

  /// Returns the next upcoming milestone, or null if all have passed.
  static IncubationMilestone? getNextMilestone(
    DateTime startDate, {
    Species? species,
    int? totalDays,
  }) {
    final milestones = getMilestones(
      startDate,
      species: species,
      totalDays: totalDays,
    );
    for (final milestone in milestones) {
      if (!milestone.isPassed) return milestone;
    }
    return null;
  }

  /// Whether the given temperature is within the valid range.
  static bool isTemperatureValid(double temp) =>
      temp >= IncubationConstants.temperatureMin &&
      temp <= IncubationConstants.temperatureMax;

  /// Whether the given humidity is within the valid range.
  static bool isHumidityValid(double humidity) =>
      humidity >= IncubationConstants.humidityMin &&
      humidity <= IncubationConstants.humidityMax;

  /// Returns the next egg number based on existing eggs.
  static int getNextEggNumber(List<Egg> eggs) {
    if (eggs.isEmpty) return 1;
    final maxNumber = eggs
        .where((e) => e.eggNumber != null)
        .fold<int>(0, (max, e) => e.eggNumber! > max ? e.eggNumber! : max);
    return maxNumber + 1;
  }

  /// Returns valid status transitions for a given [EggStatus].
  static List<EggStatus> getValidStatusTransitions(EggStatus current) {
    return switch (current) {
      EggStatus.laid => [
        EggStatus.fertile,
        EggStatus.infertile,
        EggStatus.damaged,
        EggStatus.discarded,
      ],
      EggStatus.fertile => [
        EggStatus.incubating,
        EggStatus.damaged,
        EggStatus.discarded,
      ],
      EggStatus.incubating => [
        EggStatus.hatched,
        EggStatus.damaged,
        EggStatus.discarded,
      ],
      EggStatus.hatched ||
      EggStatus.damaged ||
      EggStatus.discarded ||
      EggStatus.infertile => [],
      _ => [],
    };
  }
}
