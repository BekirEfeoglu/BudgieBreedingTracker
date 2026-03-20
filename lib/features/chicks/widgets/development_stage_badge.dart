import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/status_badge.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Development stage badge for a chick.
class DevelopmentStageBadge extends StatelessWidget {
  final DevelopmentStage stage;

  const DevelopmentStageBadge({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    return StatusBadge(label: _label, color: _color, icon: _icon);
  }

  String get _label => switch (stage) {
    DevelopmentStage.newborn => 'chicks.stage_newborn'.tr(),
    DevelopmentStage.nestling => 'chicks.stage_nestling'.tr(),
    DevelopmentStage.fledgling => 'chicks.stage_fledgling'.tr(),
    DevelopmentStage.juvenile => 'chicks.stage_juvenile'.tr(),
    DevelopmentStage.unknown => 'birds.unknown'.tr(),
  };

  Color get _color => developmentStageColor(stage);

  Widget get _icon => developmentStageIconWidget(stage);
}

/// Returns the stage color for use in avatars etc.
Color developmentStageColor(DevelopmentStage stage) => switch (stage) {
  DevelopmentStage.newborn => AppColors.stageNewborn,
  DevelopmentStage.nestling => AppColors.stageNestling,
  DevelopmentStage.fledgling => AppColors.stageFledgling,
  DevelopmentStage.juvenile => AppColors.stageJuvenile,
  DevelopmentStage.unknown => AppColors.neutral400,
};

/// Returns the stage icon widget for use in avatars etc.
Widget developmentStageIconWidget(
  DevelopmentStage stage, {
  double? size,
  Color? color,
}) => switch (stage) {
  DevelopmentStage.newborn => AppIcon(AppIcons.egg, size: size, color: color),
  DevelopmentStage.nestling => AppIcon(AppIcons.nest, size: size, color: color),
  DevelopmentStage.fledgling => AppIcon(
    AppIcons.chick,
    size: size,
    color: color,
  ),
  DevelopmentStage.juvenile => AppIcon(AppIcons.bird, size: size, color: color),
  DevelopmentStage.unknown => Icon(
    LucideIcons.helpCircle,
    size: size,
    color: color,
  ),
};

/// Returns the stage icon for legacy usage (IconData).
IconData developmentStageIcon(DevelopmentStage stage) => switch (stage) {
  DevelopmentStage.newborn => Icons.egg_alt,
  DevelopmentStage.nestling => Icons.nest_cam_wired_stand,
  DevelopmentStage.fledgling => Icons.flutter_dash,
  DevelopmentStage.juvenile => Icons.pets,
  DevelopmentStage.unknown => Icons.help_outline,
};
