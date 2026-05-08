import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';

/// Returns the display color for an [EggStatus].
///
/// Shared across egg widgets (EggListItem, EggSummaryRow, etc.).
Color getEggStatusColor(EggStatus status) {
  return switch (status) {
    EggStatus.laid => AppColors.stageNew,
    EggStatus.fertile => AppColors.success,
    EggStatus.infertile => AppColors.neutral400,
    EggStatus.incubating => AppColors.stageOngoing,
    EggStatus.hatched => AppColors.stageCompleted,
    EggStatus.damaged => AppColors.error,
    EggStatus.discarded => AppColors.neutral500,
    EggStatus.empty => AppColors.neutral300,
    EggStatus.unknown => AppColors.neutral300,
  };
}
