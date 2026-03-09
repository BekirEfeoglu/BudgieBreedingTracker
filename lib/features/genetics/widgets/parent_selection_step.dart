import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/mutation_selector.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/bird_picker_dialog.dart';

/// Step 0: Parent mutation selection.
class ParentSelectionStep extends ConsumerWidget {
  final ParentGenotype fatherGenotype;
  final ParentGenotype motherGenotype;

  const ParentSelectionStep({
    super.key,
    required this.fatherGenotype,
    required this.motherGenotype,
  });

  Future<void> _pickBird(
    BuildContext context,
    WidgetRef ref,
    BirdGender gender,
  ) async {
    final bird = await showBirdPickerDialog(
      context,
      genderFilter: gender,
    );
    if (bird == null || !context.mounted) return;

    final genotype = birdToGenotype(bird);
    if (gender == BirdGender.male) {
      ref.read(fatherGenotypeProvider.notifier).state = genotype;
      ref.read(selectedFatherBirdNameProvider.notifier).state = bird.name;
    } else {
      ref.read(motherGenotypeProvider.notifier).state = genotype;
      ref.read(selectedMotherBirdNameProvider.notifier).state = bird.name;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          genotype.isNotEmpty
              ? 'genetics.bird_selected'.tr(args: [bird.name])
              : 'genetics.no_mutations_hint'.tr(),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedFather = ref.watch(selectedFatherBirdNameProvider);
    final selectedMother = ref.watch(selectedMotherBirdNameProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Father: bird picker + mutation selector
          Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MutationSelector(
                        label: 'genetics.father_mutations'.tr(),
                        icon: const AppIcon(AppIcons.male),
                        genotype: fatherGenotype,
                        onGenotypeChanged: (genotype) {
                          ref.read(fatherGenotypeProvider.notifier).state =
                              genotype;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickBird(
                        context,
                        ref,
                        BirdGender.male,
                      ),
                      icon: const AppIcon(AppIcons.search, size: 16),
                      label: Text('genetics.select_from_birds'.tr()),
                    ),
                    if (selectedFather != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Chip(
                          avatar: AppIcon(
                            AppIcons.male,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          label: Text(
                            selectedFather,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onDeleted: () {
                            ref.read(fatherGenotypeProvider.notifier).state =
                                const ParentGenotype.empty(
                                    gender: BirdGender.male);
                            ref
                                .read(selectedFatherBirdNameProvider.notifier)
                                .state = null;
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: AppSpacing.xxl),

          // Mother: bird picker + mutation selector
          Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: MutationSelector(
                        label: 'genetics.mother_mutations'.tr(),
                        icon: const AppIcon(AppIcons.female),
                        genotype: motherGenotype,
                        onGenotypeChanged: (genotype) {
                          ref.read(motherGenotypeProvider.notifier).state =
                              genotype;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickBird(
                        context,
                        ref,
                        BirdGender.female,
                      ),
                      icon: const AppIcon(AppIcons.search, size: 16),
                      label: Text('genetics.select_from_birds'.tr()),
                    ),
                    if (selectedMother != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Chip(
                          avatar: AppIcon(
                            AppIcons.female,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          label: Text(
                            selectedMother,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onDeleted: () {
                            ref.read(motherGenotypeProvider.notifier).state =
                                const ParentGenotype.empty(
                                    gender: BirdGender.female);
                            ref
                                .read(selectedMotherBirdNameProvider.notifier)
                                .state = null;
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
