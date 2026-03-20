import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/features/chicks/screens/chick_detail_screen.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_health_badge.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/development_stage_badge.dart';

/// Header section for the chick detail screen: avatar, name, badges.
class ChickDetailHeader extends StatelessWidget {
  final Chick chick;

  const ChickDetailHeader({super.key, required this.chick});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stage = chick.developmentStage;
    final stageColor = developmentStageColor(stage);
    final age = chick.age;

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          Hero(
            tag: 'chick_${chick.id}',
            child: CircleAvatar(
              radius: 48,
              backgroundColor: stageColor.withValues(alpha: 0.1),
              child: chick.photoUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: chick.photoUrl!,
                        width: 96,
                        height: 96,
                        memCacheWidth: 192,
                        memCacheHeight: 192,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => developmentStageIconWidget(
                          stage,
                          size: 48,
                          color: stageColor,
                        ),
                      ),
                    )
                  : developmentStageIconWidget(
                      stage,
                      size: 48,
                      color: stageColor,
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(chickDisplayName(chick), style: theme.textTheme.headlineSmall),
          if (chick.ringNumber != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'chicks.ring_label'.tr(args: [chick.ringNumber!]),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (age != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _formatAge(age),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DevelopmentStageBadge(stage: stage),
              const SizedBox(width: AppSpacing.sm),
              ChickHealthBadge(status: chick.healthStatus),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAge(({int weeks, int days, int totalDays}) age) {
    if (age.weeks > 0) {
      return 'chicks.age_weeks_days'.tr(
        args: [age.weeks.toString(), age.days.toString()],
      );
    }
    return 'chicks.age_days_only'.tr(args: [age.totalDays.toString()]);
  }
}
