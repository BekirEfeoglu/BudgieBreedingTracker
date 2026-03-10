import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/screens/chick_detail_screen.dart'
    show chickDisplayName;

import 'chick_health_badge.dart';
import 'development_stage_badge.dart';

/// Card displaying a chick's summary in the list.
class ChickCard extends ConsumerWidget {
  final Chick chick;
  final ChickParentsInfo? parents;
  final bool resolveParents;
  final VoidCallback? onTap;

  const ChickCard({
    super.key,
    required this.chick,
    this.parents,
    this.resolveParents = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final age = chick.age;
    final stage = chick.developmentStage;
    final stageColor = developmentStageColor(stage);
    final parentsAsync = !resolveParents
        ? const AsyncData<ChickParentsInfo?>(null)
        : parents != null
        ? AsyncValue.data(parents)
        : ref.watch(chickParentsProvider(chick.eggId));

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.push('/chicks/${chick.id}'),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Hero(
                tag: 'chick_${chick.id}',
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: stageColor.withValues(alpha: 0.1),
                  child: developmentStageIconWidget(
                    stage,
                    size: 28,
                    color: stageColor,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chickDisplayName(chick),
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (chick.ringNumber != null) ...[
                          AppIcon(
                            AppIcons.ring,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            chick.ringNumber!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        if (age != null)
                          Text(
                            _formatAge(age),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    // Parent info
                    parentsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (parents) {
                        if (parents == null) return const SizedBox.shrink();
                        final maleName =
                            parents.maleName ?? 'chicks.unknown_gender'.tr();
                        final femaleName =
                            parents.femaleName ?? 'chicks.unknown_gender'.tr();
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const AppIcon(
                                AppIcons.male,
                                size: 14,
                                color: AppColors.genderMale,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  maleName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.genderMale,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              const AppIcon(
                                AppIcons.female,
                                size: 14,
                                color: AppColors.genderFemale,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  femaleName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.genderFemale,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ChickHealthBadge(status: chick.healthStatus),
                  ],
                ),
              ),
              DevelopmentStageBadge(stage: stage),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAge(({int weeks, int days, int totalDays}) age) {
    if (age.weeks > 0) {
      return 'chicks.age_weeks_days_short'.tr(
        args: [age.weeks.toString(), age.days.toString()],
      );
    }
    return 'chicks.age_days_only_short'.tr(args: [age.totalDays.toString()]);
  }
}
