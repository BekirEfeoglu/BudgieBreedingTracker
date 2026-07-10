import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/bird_genotype_mapper.dart';
import 'package:budgie_breeding_tracker/shared/widgets/genetics.dart';
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
      speciesFilter: Species.budgie,
    );
    if (bird == null || !context.mounted) return;

    // Map to a genotype excluding any mutation the engine can't resolve, and
    // report those so the user is warned instead of them being silently
    // dropped at the engine boundary (I1).
    final mapping = BirdGenotypeMapper.birdToGenotypeMapping(bird);
    final genotype = mapping.genotype;
    final SelectedParentBird identity = (id: bird.id, name: bird.name);

    if (gender == BirdGender.male) {
      ref.read(fatherGenotypeProvider.notifier).state = genotype;
      ref.read(selectedFatherBirdProvider.notifier).state = identity;
      ref.read(fatherGenotypeSourceProvider.notifier).state =
          ParentGenotypeSource.fromBird;
    } else {
      ref.read(motherGenotypeProvider.notifier).state = genotype;
      ref.read(selectedMotherBirdProvider.notifier).state = identity;
      ref.read(motherGenotypeSourceProvider.notifier).state =
          ParentGenotypeSource.fromBird;
    }

    final String message;
    if (mapping.unmappedMutationIds.isNotEmpty) {
      message = 'genetics.bird_unmapped_mutations'.tr(
        args: [
          bird.name,
          mapping.unmappedMutationIds.length.toString(),
        ],
      );
    } else if (genotype.isNotEmpty) {
      message = 'genetics.bird_selected'.tr(args: [bird.name]);
    } else {
      message = 'genetics.no_mutations_hint'.tr();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Localized provenance label for a parent genotype, or `null` when the
  /// genotype was typed by hand (no badge needed).
  static String? _provenanceLabel(ParentGenotypeSource source) {
    return switch (source) {
      ParentGenotypeSource.manual => null,
      ParentGenotypeSource.fromBird => 'genetics.genotype_from_bird'.tr(),
      ParentGenotypeSource.fromBirdEdited =>
        'genetics.genotype_from_bird_edited'.tr(),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedFather = ref.watch(selectedFatherBirdProvider);
    final selectedMother = ref.watch(selectedMotherBirdProvider);
    final fatherProvenance = _provenanceLabel(
      ref.watch(fatherGenotypeSourceProvider),
    );
    final motherProvenance = _provenanceLabel(
      ref.watch(motherGenotypeSourceProvider),
    );

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
                          // A hand-edit after a bird seed marks provenance.
                          if (ref.read(fatherGenotypeSourceProvider) !=
                              ParentGenotypeSource.manual) {
                            ref
                                    .read(fatherGenotypeSourceProvider.notifier)
                                    .state =
                                ParentGenotypeSource.fromBirdEdited;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickBird(context, ref, BirdGender.male),
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
                            selectedFather.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onDeleted: () {
                            ref
                                .read(fatherGenotypeProvider.notifier)
                                .state = const ParentGenotype.empty(
                              gender: BirdGender.male,
                            );
                            ref
                                .read(selectedFatherBirdProvider.notifier)
                                .state = null;
                            ref
                                    .read(fatherGenotypeSourceProvider.notifier)
                                    .state =
                                ParentGenotypeSource.manual;
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                ),
                if (fatherProvenance != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _ProvenanceLabel(text: fatherProvenance),
                ],
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
                          if (ref.read(motherGenotypeSourceProvider) !=
                              ParentGenotypeSource.manual) {
                            ref
                                    .read(motherGenotypeSourceProvider.notifier)
                                    .state =
                                ParentGenotypeSource.fromBirdEdited;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          _pickBird(context, ref, BirdGender.female),
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
                            selectedMother.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onDeleted: () {
                            ref
                                .read(motherGenotypeProvider.notifier)
                                .state = const ParentGenotype.empty(
                              gender: BirdGender.female,
                            );
                            ref
                                .read(selectedMotherBirdProvider.notifier)
                                .state = null;
                            ref
                                    .read(motherGenotypeSourceProvider.notifier)
                                    .state =
                                ParentGenotypeSource.manual;
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ],
                ),
                if (motherProvenance != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _ProvenanceLabel(text: motherProvenance),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small muted label showing where a parent genotype came from (seeded from a
/// bird, or seeded then hand-edited).
class _ProvenanceLabel extends StatelessWidget {
  final String text;

  const _ProvenanceLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.info_outline,
          size: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
