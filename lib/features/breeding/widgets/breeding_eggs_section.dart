import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_calculator.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/milestone_timeline.dart';
import 'package:budgie_breeding_tracker/shared/widgets/eggs.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';
import 'package:budgie_breeding_tracker/shared/providers/eggs.dart';
import 'package:budgie_breeding_tracker/data/providers/action_feedback_providers.dart';

class BreedingEggsSection extends ConsumerWidget {
  final String incubationId;
  final String pairId;

  const BreedingEggsSection({
    super.key,
    required this.incubationId,
    required this.pairId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final eggsAsync = ref.watch(eggsByIncubationProvider(incubationId));

    // Show SnackBar when chick is auto-created from hatched egg
    ref.listen<EggActionsState>(eggActionsProvider, (_, state) {
      if (!context.mounted) return;
      if (state.warning != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.warning!)));
      }
      if (state.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error!)));
      }
      if (state.chickCreated) {
        ActionFeedbackService.show(
          'eggs.chick_created_from_egg'.tr(),
          actionRoute: '/chicks',
          actionLabel: 'eggs.go_to_chicks'.tr(),
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.screenPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('breeding.eggs'.tr(), style: theme.textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => context.push('/breeding/$pairId/eggs'),
                icon: const AppIcon(AppIcons.add, size: 18),
                label: Text('breeding.manage'.tr()),
              ),
            ],
          ),
        ),
        eggsAsync.when(
          loading: () => const Padding(
            padding: AppSpacing.screenPadding,
            child: LinearProgressIndicator(),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (eggs) {
            if (eggs.isEmpty) {
              return Padding(
                padding: AppSpacing.screenPadding,
                child: Text(
                  'breeding.no_eggs'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            // Filter out hatched eggs (they become chicks)
            final activeEggs = eggs
                .where((e) => e.status != EggStatus.hatched)
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: EggSummaryRow(eggs: eggs),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (activeEggs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: AppSpacing.cardPadding,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.checkCircle2,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'breeding.all_eggs_hatched'.tr(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...activeEggs.map(
                    (egg) => EggListItem(
                      egg: egg,
                      onStatusUpdate: () async {
                        final newStatus = await showEggStatusUpdateSheet(
                          context,
                          egg,
                        );
                        if (newStatus != null) {
                          ref
                              .read(eggActionsProvider.notifier)
                              .updateEggStatus(egg, newStatus);
                        }
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class BreedingMilestoneSection extends StatelessWidget {
  final DateTime startDate;
  final int? totalDays;

  const BreedingMilestoneSection({
    super.key,
    required this.startDate,
    this.totalDays,
  });

  @override
  Widget build(BuildContext context) {
    final milestones = IncubationCalculator.getMilestones(
      startDate,
      totalDays: totalDays,
    );

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            'breeding.milestones'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          MilestoneTimeline(milestones: milestones),
        ],
      ),
    );
  }
}

class BreedingNotesSection extends StatelessWidget {
  final String notes;

  const BreedingNotesSection({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            'common.notes'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(notes, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
