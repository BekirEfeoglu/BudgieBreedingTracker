import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/status_badge.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/animations/pulse_animation.dart';

/// Status badge for a bird (alive, dead, sold, gifted).
class BirdStatusBadge extends StatelessWidget {
  final BirdStatus status;

  const BirdStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final badge = StatusBadge(label: _label, color: _color, icon: _icon);

    // Alive and Unknown are standard states, no need for animation.
    // Highlight special statuses with a subtle pulsing effect.
    if (status == BirdStatus.dead ||
        status == BirdStatus.sold ||
        status == BirdStatus.gifted) {
      return PulseAnimation(
        lowerBound: 0.95,
        upperBound: 1.05,
        duration: const Duration(seconds: 2),
        child: badge,
      );
    }

    return badge;
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
    BirdStatus.gifted => const AppIcon(AppIcons.heartHandshake),
    BirdStatus.unknown => const Icon(LucideIcons.helpCircle, size: 16),
  };
}
