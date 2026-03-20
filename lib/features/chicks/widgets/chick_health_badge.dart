import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/status_badge.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Health status badge for a chick.
class ChickHealthBadge extends StatelessWidget {
  final ChickHealthStatus status;

  const ChickHealthBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return StatusBadge(label: _label, color: _color, icon: _icon);
  }

  String get _label => switch (status) {
    ChickHealthStatus.healthy => 'chicks.status_healthy'.tr(),
    ChickHealthStatus.sick => 'chicks.status_sick'.tr(),
    ChickHealthStatus.deceased => 'chicks.status_deceased'.tr(),
    ChickHealthStatus.unknown => 'chicks.status_unknown'.tr(),
  };

  Color get _color => switch (status) {
    ChickHealthStatus.healthy => AppColors.success,
    ChickHealthStatus.sick => AppColors.warning,
    ChickHealthStatus.deceased => AppColors.error,
    ChickHealthStatus.unknown => AppColors.genderUnknown,
  };

  Widget get _icon => switch (status) {
    ChickHealthStatus.healthy => const AppIcon(AppIcons.health),
    ChickHealthStatus.sick => const AppIcon(AppIcons.care),
    ChickHealthStatus.deceased => const Icon(LucideIcons.heartCrack),
    ChickHealthStatus.unknown => const Icon(LucideIcons.helpCircle),
  };
}
