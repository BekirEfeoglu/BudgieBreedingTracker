import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/incubation_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';

import 'incubation_milestone.dart';

/// Static utility class for incubation-related calculations.
///
/// Provides stage colors, milestone generation, validation helpers,
/// and egg status transition rules for the breeding module.
abstract class IncubationCalculator {
  /// Returns the stage color based on elapsed incubation days.
  static Color getStageColor(int daysElapsed) {
    if (daysElapsed > IncubationConstants.incubationPeriodDays) {
      return AppColors.stageOverdue;
    }
    if (daysElapsed >= IncubationConstants.sensitivePeriodDay) {
      return AppColors.stageNearHatch;
    }
    if (daysElapsed >= IncubationConstants.candlingDay) {
      return AppColors.stageOngoing;
    }
    if (daysElapsed > 0) {
      return AppColors.stageNew;
    }
    return AppColors.stageNew;
  }

  /// Returns a human-readable stage label based on elapsed days.
  static String getStageLabel(int daysElapsed) {
    if (daysElapsed > IncubationConstants.incubationPeriodDays) {
      return 'incubation.stage_overdue'.tr();
    }
    if (daysElapsed >= IncubationConstants.sensitivePeriodDay) {
      return 'incubation.stage_near_hatch'.tr();
    }
    if (daysElapsed >= IncubationConstants.candlingDay) {
      return 'incubation.stage_ongoing'.tr();
    }
    return 'incubation.stage_new'.tr();
  }

  /// Returns the stage color for a completed incubation.
  static Color getCompletedStageColor() => AppColors.stageCompleted;

  /// Generates all milestones for an incubation starting at [startDate].
  static List<IncubationMilestone> getMilestones(DateTime startDate) {
    final now = DateTime.now();
    return [
      IncubationMilestone(
        day: IncubationConstants.candlingDay,
        title: 'incubation.milestone_candling'.tr(),
        description: 'incubation.milestone_candling_desc'.tr(),
        type: MilestoneType.candling,
        date: startDate.add(
          const Duration(days: IncubationConstants.candlingDay),
        ),
        isPassed: now.isAfter(
          startDate.add(
            const Duration(days: IncubationConstants.candlingDay),
          ),
        ),
      ),
      IncubationMilestone(
        day: IncubationConstants.secondCheckDay,
        title: 'incubation.milestone_second_check'.tr(),
        description: 'incubation.milestone_second_check_desc'.tr(),
        type: MilestoneType.check,
        date: startDate.add(
          const Duration(days: IncubationConstants.secondCheckDay),
        ),
        isPassed: now.isAfter(
          startDate.add(
            const Duration(days: IncubationConstants.secondCheckDay),
          ),
        ),
      ),
      IncubationMilestone(
        day: IncubationConstants.sensitivePeriodDay,
        title: 'incubation.milestone_sensitive'.tr(),
        description: 'incubation.milestone_sensitive_desc'.tr(),
        type: MilestoneType.sensitive,
        date: startDate.add(
          const Duration(days: IncubationConstants.sensitivePeriodDay),
        ),
        isPassed: now.isAfter(
          startDate.add(
            const Duration(days: IncubationConstants.sensitivePeriodDay),
          ),
        ),
      ),
      IncubationMilestone(
        day: IncubationConstants.expectedHatchDay,
        title: 'incubation.milestone_hatch'.tr(),
        description: 'incubation.milestone_hatch_desc'.tr(),
        type: MilestoneType.hatch,
        date: startDate.add(
          const Duration(days: IncubationConstants.expectedHatchDay),
        ),
        isPassed: now.isAfter(
          startDate.add(
            const Duration(days: IncubationConstants.expectedHatchDay),
          ),
        ),
      ),
      IncubationMilestone(
        day: IncubationConstants.lateHatchDay,
        title: 'incubation.milestone_late'.tr(),
        description: 'incubation.milestone_late_desc'.tr(),
        type: MilestoneType.late,
        date: startDate.add(
          const Duration(days: IncubationConstants.lateHatchDay),
        ),
        isPassed: now.isAfter(
          startDate.add(
            const Duration(days: IncubationConstants.lateHatchDay),
          ),
        ),
      ),
    ];
  }

  /// Returns the next upcoming milestone, or null if all have passed.
  static IncubationMilestone? getNextMilestone(DateTime startDate) {
    final milestones = getMilestones(startDate);
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
      EggStatus.infertile =>
        [],
      _ => [],
    };
  }
}
