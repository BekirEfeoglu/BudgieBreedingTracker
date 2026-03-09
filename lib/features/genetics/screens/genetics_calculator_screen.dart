import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_history_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/genetics_wizard_stepper.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/parent_selection_step.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/genotype_preview_step.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/genetics_results_step.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

/// Screen with father/mother mutation selectors, offspring prediction results,
/// Punnett square, and probability bar chart.
///
/// Uses a 3-step wizard flow:
/// Step 0: Parent mutation selection with carrier/visual toggle
/// Step 1: Genotype preview (selection summary)
/// Step 2: Results (offspring predictions, charts, Punnett square)
class GeneticsCalculatorScreen extends ConsumerWidget {
  const GeneticsCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizardStep = ref.watch(wizardStepProvider);
    final fatherGenotype = ref.watch(fatherGenotypeProvider);
    final motherGenotype = ref.watch(motherGenotypeProvider);
    final hasSelections =
        fatherGenotype.isNotEmpty || motherGenotype.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('genetics.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeftRight),
            tooltip: 'genetics.reverse_calculator'.tr(),
            onPressed: () => context.push(AppRoutes.geneticsReverse),
          ),
          IconButton(
            icon: const Icon(LucideIcons.history),
            tooltip: 'genetics.history'.tr(),
            onPressed: () => context.push(AppRoutes.geneticsHistory),
          ),
          if (hasSelections)
            IconButton(
              icon: const AppIcon(AppIcons.sync),
              tooltip: 'genetics.reset'.tr(),
              onPressed: () => _confirmReset(context, ref),
            ),
        ],
      ),
      body: Column(
        children: [
          // Stepper indicator
          GeneticsWizardStepper(
            currentStep: wizardStep,
            hasSelections: hasSelections,
            onStepTap: (step) {
              if (step <= wizardStep || hasSelections) {
                ref.read(wizardStepProvider.notifier).state = step;
              }
            },
          ),
          const Divider(height: 1),

          // Step content
          Expanded(
            child: switch (wizardStep) {
              0 => ParentSelectionStep(
                  fatherGenotype: fatherGenotype,
                  motherGenotype: motherGenotype,
                ),
              1 => GenotypePreviewStep(
                  fatherGenotype: fatherGenotype,
                  motherGenotype: motherGenotype,
                ),
              _ => const GeneticsResultsStep(),
            },
          ),
        ],
      ),
      bottomNavigationBar: _WizardNavBar(
        currentStep: wizardStep,
        hasSelections: hasSelections,
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('genetics.confirm_reset'.tr()),
        content: Text('genetics.confirm_reset_desc'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('genetics.reset'.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _reset(ref);
    }
  }

  void _reset(WidgetRef ref) {
    ref.read(fatherGenotypeProvider.notifier).state =
        const ParentGenotype.empty(gender: BirdGender.male);
    ref.read(motherGenotypeProvider.notifier).state =
        const ParentGenotype.empty(gender: BirdGender.female);
    ref.read(wizardStepProvider.notifier).state = 0;
    ref.read(selectedPunnettLocusProvider.notifier).state = null;
    ref.read(selectedFatherBirdNameProvider.notifier).state = null;
    ref.read(selectedMotherBirdNameProvider.notifier).state = null;
  }
}

/// Bottom navigation bar with Back/Next buttons for wizard flow.
class _WizardNavBar extends ConsumerWidget {
  final int currentStep;
  final bool hasSelections;

  const _WizardNavBar({
    required this.currentStep,
    required this.hasSelections,
  });

  Future<void> _saveCalculation(BuildContext context, WidgetRef ref) async {
    final saved = await ref
        .read(geneticsHistorySaveProvider.notifier)
        .saveCurrentCalculation();
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('genetics.calculation_saved'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            OutlinedButton.icon(
              onPressed: () {
                ref.read(wizardStepProvider.notifier).state = currentStep - 1;
              },
              icon: const Icon(LucideIcons.chevronLeft, size: 18),
              label: Text('genetics.back'.tr()),
            )
          else
            const Spacer(),
          const Spacer(),
          if (currentStep < 2)
            FilledButton(
              onPressed: hasSelections
                  ? () {
                      ref.read(wizardStepProvider.notifier).state =
                          currentStep + 1;
                    }
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('genetics.next'.tr()),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(LucideIcons.chevronRight, size: 18),
                ],
              ),
            )
          else if (hasSelections)
            FilledButton.icon(
              onPressed: () => _saveCalculation(context, ref),
              icon: const Icon(LucideIcons.save, size: 18),
              label: Text('genetics.save_calculation'.tr()),
            ),
        ],
      ),
    );
  }
}
