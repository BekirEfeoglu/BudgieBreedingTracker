import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/development_stage_badge.dart';

/// Section showing recent chicks on the dashboard.
class RecentChicksSection extends ConsumerWidget {
  final List<Chick> chicks;
  final String userId;

  const RecentChicksSection({
    super.key,
    required this.chicks,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentsByEggAsync = ref.watch(chickParentsByEggProvider(userId));
    final parentsByEgg = switch (parentsByEggAsync) {
      AsyncData(:final value) => value,
      _ => const <String, ChickParentsInfo>{},
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'home.recent_chicks'.tr(),
            onViewAll: () => context.push('/chicks'),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (chicks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'home.no_chicks'.tr(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...chicks.map(
              (chick) => _ChickTile(
                chick: chick,
                parents: chick.eggId == null
                    ? null
                    : parentsByEgg[chick.eggId!],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        TextButton(onPressed: onViewAll, child: Text('common.view_all'.tr())),
      ],
    );
  }
}

class _ChickTile extends StatelessWidget {
  final Chick chick;
  final ChickParentsInfo? parents;

  const _ChickTile({required this.chick, required this.parents});

  @override
  Widget build(BuildContext context) {
    final displayName =
        chick.name ??
        (chick.ringNumber != null
            ? '${'chicks.chick_label'.tr()} #${chick.ringNumber}'
            : '${'chicks.chick_label'.tr()} #${chick.id.substring(0, 4)}');
    final age = chick.age;
    final bool isBornToday =
        chick.hatchDate != null &&
        DateUtils.isSameDay(chick.hatchDate, DateTime.now());
    final String ageText;
    if (isBornToday) {
      ageText = 'home.born_today'.tr();
    } else if (age != null) {
      ageText =
          '${age.weeks}${'chicks.weeks_short'.tr()} ${age.days}${'chicks.days_short'.tr()}';
    } else {
      ageText = '';
    }
    final stage = chick.developmentStage;

    return Card(
      child: InkWell(
        onTap: () => context.push('/chicks/${chick.id}'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: developmentStageColor(
                  stage,
                ).withValues(alpha: 0.15),
                child: Icon(
                  developmentStageIcon(stage),
                  size: 18,
                  color: developmentStageColor(stage),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (ageText.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        ageText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    // Parent info
                    if (parents != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const AppIcon(
                              AppIcons.male,
                              size: 12,
                              color: AppColors.genderMale,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                parents!.maleName ?? '?',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.genderMale,
                                      fontSize: 11,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            const AppIcon(
                              AppIcons.female,
                              size: 12,
                              color: AppColors.genderFemale,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                parents!.femaleName ?? '?',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.genderFemale,
                                      fontSize: 11,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
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
}
