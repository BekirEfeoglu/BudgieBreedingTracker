import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';

/// Returns the localized display label for a [BirdColor].
String birdColorLabel(BirdColor color) => switch (color) {
  BirdColor.green => 'birds.color_green'.tr(),
  BirdColor.blue => 'birds.color_blue'.tr(),
  BirdColor.yellow => 'birds.color_yellow'.tr(),
  BirdColor.white => 'birds.color_white'.tr(),
  BirdColor.grey => 'birds.color_grey'.tr(),
  BirdColor.violet => 'birds.color_violet'.tr(),
  BirdColor.lutino => 'birds.color_lutino'.tr(),
  BirdColor.albino => 'birds.color_albino'.tr(),
  BirdColor.cinnamon => 'birds.color_cinnamon'.tr(),
  BirdColor.opaline => 'birds.color_opaline'.tr(),
  BirdColor.spangle => 'birds.color_spangle'.tr(),
  BirdColor.pied => 'birds.color_pied'.tr(),
  BirdColor.clearwing => 'birds.color_clearwing'.tr(),
  BirdColor.other => 'birds.color_other'.tr(),
  BirdColor.unknown => 'birds.color_other'.tr(),
};

/// Returns the visual [Color] for a [BirdColor] enum value.
Color birdColorToColor(BirdColor color) => switch (color) {
  BirdColor.green => AppColors.birdGreen,
  BirdColor.blue => AppColors.birdBlue,
  BirdColor.yellow => AppColors.birdYellow,
  BirdColor.white => AppColors.birdWhite,
  BirdColor.grey => AppColors.birdGrey,
  BirdColor.violet => AppColors.birdViolet,
  BirdColor.lutino => AppColors.birdLutino,
  BirdColor.albino => AppColors.birdAlbino,
  BirdColor.cinnamon => AppColors.birdCinnamon,
  BirdColor.opaline => AppColors.birdOpaline,
  BirdColor.spangle => AppColors.birdSpangle,
  BirdColor.pied => AppColors.birdPied,
  BirdColor.clearwing => AppColors.birdClearwing,
  BirdColor.other => AppColors.birdOther,
  BirdColor.unknown => AppColors.birdOther,
};
