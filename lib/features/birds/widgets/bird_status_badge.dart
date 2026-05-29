import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/status_badge.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Status badge for a bird (alive, dead, sold, gifted).
class BirdStatusBadge extends StatelessWidget {
  final BirdStatus status;

  const BirdStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return StatusBadge(label: _label, color: _color, icon: _icon);
  }

  String get _label => switch (status) {
    BirdStatus.alive => 'birds.status_alive'.tr(),
    BirdStatus.dead => 'birds.status_dead'.tr(),
    BirdStatus.sold => 'birds.status_sold'.tr(),
    BirdStatus.gifted => 'birds.status_gifted'.tr(),
    BirdStatus.unknown => 'birds.unknown'.tr(),
  };

  Color get _color => switch (status) {
    BirdStatus.alive => AppColors.success,
    BirdStatus.dead => AppColors.error,
    BirdStatus.sold => AppColors.warning,
    BirdStatus.gifted => AppColors.info,
    BirdStatus.unknown => AppColors.neutral400,
  };

  Widget get _icon => switch (status) {
    BirdStatus.alive => const AppIcon(AppIcons.statusAlive),
    BirdStatus.dead => const AppIcon(AppIcons.statusDead),
    BirdStatus.sold => const AppIcon(AppIcons.statusSold),
    // TODO(birds-audit #14): domain "gifted" status has no SVG yet. Add an
    // `AppIcons.statusGifted` asset (sibling of statusAlive/Sold/Dead) and
    // switch to `AppIcon(AppIcons.statusGifted)`. LucideIcons.gift is a
    // generic-UI fallback until that asset exists.
    BirdStatus.gifted => const Icon(LucideIcons.gift, size: 16),
    BirdStatus.unknown => const Icon(LucideIcons.helpCircle, size: 16),
  };
}
