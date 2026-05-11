import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/shared/providers/chicks.dart';
import 'package:budgie_breeding_tracker/features/chicks/screens/chick_detail_screen.dart'
    show chickDisplayName;
import 'package:budgie_breeding_tracker/router/route_names.dart';

import 'chick_age_formatter.dart';
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
        onTap: onTap ?? () => context.push('${AppRoutes.chicks}/${chick.id}'),
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
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              chick.ringNumber!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        if (age != null)
                          Flexible(
                            child: Text(
                              formatChickAge(age, short: true),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
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
                        final cageNumber = parents.cageNumber;
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (cageNumber != null &&
                                  cageNumber.isNotEmpty) ...[
                                Text(
                                  '${'breeding.cage_label'.tr()}: $cageNumber',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: 2,
                                    children: [
                                      _ParentNameLabel(
                                        icon: const AppIcon(
                                          AppIcons.male,
                                          size: 14,
                                          color: AppColors.genderMale,
                                        ),
                                        label: maleName,
                                        color: AppColors.genderMale,
                                        maxWidth: constraints.maxWidth,
                                      ),
                                      _ParentNameLabel(
                                        icon: const AppIcon(
                                          AppIcons.female,
                                          size: 14,
                                          color: AppColors.genderFemale,
                                        ),
                                        label: femaleName,
                                        color: AppColors.genderFemale,
                                        maxWidth: constraints.maxWidth,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        ChickHealthBadge(status: chick.healthStatus),
                        DevelopmentStageBadge(stage: stage),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentNameLabel extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color color;
  final double maxWidth;

  const _ParentNameLabel({
    required this.icon,
    required this.label,
    required this.color,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
