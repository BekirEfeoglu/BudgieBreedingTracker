import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/incubation_constants.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/progress_bar.dart';
import 'package:budgie_breeding_tracker/core/widgets/dialogs/confirm_dialog.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_calculator.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_form_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_pair_info_section.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_eggs_section.dart';

/// Detail screen for a breeding pair showing incubation, eggs, milestones.
class BreedingDetailScreen extends ConsumerWidget {
  final String pairId;

  const BreedingDetailScreen({super.key, required this.pairId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairAsync = ref.watch(breedingPairByIdProvider(pairId));

    return pairAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text('common.loading'.tr())),
        body: const LoadingState(),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text('common.error'.tr())),
        body: ErrorState(message: error.toString()),
      ),
      data: (pair) {
        if (pair == null) {
          return Scaffold(
            appBar: AppBar(title: Text('common.not_found'.tr())),
            body: ErrorState(message: 'breeding.not_found'.tr()),
          );
        }
        return _DetailContent(pair: pair);
      },
    );
  }
}

class _DetailContent extends ConsumerWidget {
  final BreedingPair pair;

  const _DetailContent({required this.pair});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incubationsAsync = ref.watch(incubationsByPairProvider(pair.id));

    // Side effects: success after complete/cancel/delete → pop + snackbar
    ref.listen<BreedingFormState>(breedingFormStateProvider, (_, state) {
      if (state.isSuccess) {
        ref.read(breedingFormStateProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('common.saved_successfully'.tr())),
        );
      }
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('breeding.detail'.tr()),
        actions: [
          IconButton(
            icon: const AppIcon(AppIcons.edit),
            tooltip: 'common.edit'.tr(),
            onPressed: () =>
                context.push('/breeding/form?editId=${pair.id}'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) =>
                _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'complete',
                child: Text('breeding.complete'.tr()),
              ),
              PopupMenuItem(
                value: 'cancel',
                child: Text('breeding.cancel_breeding'.tr()),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('common.delete'.tr()),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BreedingPairInfoSection(pair: pair),
            incubationsAsync.when(
              loading: () => const Padding(
                padding: AppSpacing.screenPadding,
                child: LinearProgressIndicator(),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (incubations) {
                if (incubations.isEmpty) return const SizedBox.shrink();
                final incubation = incubations.first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IncubationSection(incubation: incubation),
                    BreedingEggsSection(
                      incubationId: incubation.id,
                      pairId: pair.id,
                    ),
                    if (incubation.startDate != null)
                      BreedingMilestoneSection(
                        startDate: incubation.startDate!,
                      ),
                  ],
                );
              },
            ),
            if (pair.notes != null && pair.notes!.isNotEmpty)
              BreedingNotesSection(notes: pair.notes!),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final formNotifier = ref.read(breedingFormStateProvider.notifier);

    switch (action) {
      case 'complete':
        final confirmed = await showConfirmDialog(
          context,
          title: 'breeding.complete'.tr(),
          message: 'breeding.complete_confirm'.tr(),
          confirmLabel: 'breeding.complete'.tr(),
        );
        if (confirmed == true) {
          await formNotifier.completeBreeding(pair.id);
        }
      case 'cancel':
        final confirmed = await showConfirmDialog(
          context,
          title: 'breeding.cancel_breeding'.tr(),
          message: 'breeding.cancel_confirm'.tr(),
          confirmLabel: 'breeding.cancel_breeding'.tr(),
          isDestructive: true,
        );
        if (confirmed == true) {
          await formNotifier.cancelBreeding(pair.id);
        }
      case 'delete':
        final confirmed = await showConfirmDialog(
          context,
          title: 'common.delete'.tr(),
          message: 'breeding.delete_confirm'.tr(),
          confirmLabel: 'common.delete'.tr(),
          isDestructive: true,
        );
        if (confirmed == true) {
          await formNotifier.deleteBreeding(pair.id);
          if (context.mounted) {
            context.pop();
          }
        }
    }
  }
}

class _IncubationSection extends StatelessWidget {
  final Incubation incubation;

  const _IncubationSection({required this.incubation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');
    final daysElapsed = incubation.daysElapsed;
    final isComplete = incubation.isComplete;
    final stageColor = isComplete
        ? IncubationCalculator.getCompletedStageColor()
        : IncubationCalculator.getStageColor(daysElapsed);
    final stageLabel = isComplete
        ? 'breeding.completed'.tr()
        : IncubationCalculator.getStageLabel(daysElapsed);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('breeding.incubation_process'.tr(),
                  style: theme.textTheme.titleMedium),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: stageColor.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  stageLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: stageColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppProgressBar(
            value: incubation.percentageComplete,
            color: stageColor,
            label:
                '${'breeding.day'.tr()} $daysElapsed / ${IncubationConstants.incubationPeriodDays}',
            showPercentage: true,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (incubation.startDate != null)
                Flexible(
                  child: Text(
                    '${'breeding.start_date'.tr()}: ${dateFormat.format(incubation.startDate!)}',
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (incubation.computedExpectedHatchDate != null)
                Flexible(
                  child: Text(
                    '${'breeding.expected_date'.tr()}: ${dateFormat.format(incubation.computedExpectedHatchDate!)}',
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
