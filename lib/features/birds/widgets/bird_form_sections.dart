import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/date_picker_field.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/mutation_selector.dart';
import 'package:budgie_breeding_tracker/features/birds/utils/bird_color_utils.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_parent_selector.dart';
import 'package:budgie_breeding_tracker/features/birds/utils/bird_display_utils.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Basic info section: name, gender, species, color mutation.
class BirdFormBasicInfoSection extends StatelessWidget {
  final TextEditingController nameController;
  final BirdGender gender;
  final Species species;
  final BirdColor? colorMutation;
  final TextEditingController colorNoteController;
  final ValueChanged<BirdGender> onGenderChanged;
  final ValueChanged<Species> onSpeciesChanged;
  final ValueChanged<BirdColor?> onColorChanged;

  const BirdFormBasicInfoSection({
    super.key,
    required this.nameController,
    required this.gender,
    required this.species,
    required this.colorMutation,
    required this.colorNoteController,
    required this.onGenderChanged,
    required this.onSpeciesChanged,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedColorMutation = colorMutation == BirdColor.unknown
        ? null
        : colorMutation;
    final selectableSpecies = <Species>[
      Species.budgie,
      if (species != Species.budgie && species != Species.unknown) species,
    ];
    final selectedSpecies = selectableSpecies.contains(species)
        ? species
        : Species.budgie;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BirdFormSectionHeader('birds.section_basic'.tr()),
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'birds.name_label'.tr(),
            border: const OutlineInputBorder(),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: AppIcon(AppIcons.bird, size: 20),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'birds.name_required'.tr();
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'birds.gender'.tr(),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<BirdGender>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: BirdGender.male,
              label: Text('birds.male'.tr()),
              icon: const AppIcon(AppIcons.male),
            ),
            ButtonSegment(
              value: BirdGender.female,
              label: Text('birds.female'.tr()),
              icon: const AppIcon(AppIcons.female),
            ),
            ButtonSegment(
              value: BirdGender.unknown,
              label: Text('birds.unknown'.tr()),
              icon: const Icon(LucideIcons.helpCircle),
            ),
          ],
          selected: {gender},
          onSelectionChanged: (selection) {
            onGenderChanged(selection.first);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<Species>(
          initialValue: selectedSpecies,
          decoration: InputDecoration(
            labelText: 'birds.species'.tr(),
            border: const OutlineInputBorder(),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: speciesIconWidget(selectedSpecies, size: 20),
            ),
          ),
          items: selectableSpecies
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      speciesIconWidget(s, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(speciesLabel(s)),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onSpeciesChanged(value);
            }
          },
          isExpanded: true,
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<BirdColor?>(
          initialValue: normalizedColorMutation,
          decoration: InputDecoration(
            labelText: 'birds.color'.tr(),
            border: const OutlineInputBorder(),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: AppIcon(AppIcons.colorPalette, size: 20),
            ),
          ),
          items: [
            DropdownMenuItem<BirdColor?>(
              value: null,
              child: Text(
                'birds.no_color_selected'.tr(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ...BirdColor.values
                .where((color) => color != BirdColor.unknown)
                .map(
                  (color) => DropdownMenuItem<BirdColor?>(
                    value: color,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: birdColorToColor(color),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.3),
                              width: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(birdColorLabel(color)),
                      ],
                    ),
                  ),
                ),
          ],
          onChanged: (value) {
            onColorChanged(value);
          },
          isExpanded: true,
        ),
        if (colorMutation == BirdColor.other) ...[
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: colorNoteController,
            decoration: InputDecoration(
              labelText: 'birds.color_name'.tr(),
              border: const OutlineInputBorder(),
              prefixIcon: const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: AppIcon(AppIcons.colorPalette, size: 20),
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
        ],
      ],
    );
  }
}

/// Genetics section: optional detailed mutation and allele-state profile.
class BirdFormGeneticsSection extends StatelessWidget {
  final BirdGender gender;
  final ParentGenotype genotype;
  final ValueChanged<ParentGenotype> onGenotypeChanged;

  const BirdFormGeneticsSection({
    super.key,
    required this.gender,
    required this.genotype,
    required this.onGenotypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = ParentGenotype(
      mutations: Map<String, AlleleState>.from(genotype.mutations),
      gender: gender,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BirdFormSectionHeader('genetics.title'.tr()),
        MutationSelector(
          label: 'genetics.individual_mutations'.tr(),
          icon: const AppIcon(AppIcons.dna),
          genotype: normalized,
          onGenotypeChanged: onGenotypeChanged,
        ),
      ],
    );
  }
}

/// Identity section: ring number, birth date, cage number.
class BirdFormIdentitySection extends StatelessWidget {
  final TextEditingController ringController;
  final TextEditingController cageController;
  final DateTime? birthDate;
  final ValueChanged<DateTime?> onBirthDateChanged;

  const BirdFormIdentitySection({
    super.key,
    required this.ringController,
    required this.cageController,
    required this.birthDate,
    required this.onBirthDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BirdFormSectionHeader('birds.section_identity'.tr()),
        TextFormField(
          controller: ringController,
          decoration: InputDecoration(
            labelText: 'birds.ring_number'.tr(),
            border: const OutlineInputBorder(),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: AppIcon(AppIcons.ring, size: 20),
            ),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.md),
        DatePickerField(
          label: 'birds.birth_date'.tr(),
          value: birthDate,
          onChanged: onBirthDateChanged,
          firstDate: DateTime(2015),
          lastDate: DateTime.now(),
          isRequired: false,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: cageController,
          decoration: InputDecoration(
            labelText: 'birds.cage_number'.tr(),
            border: const OutlineInputBorder(),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: AppIcon(AppIcons.nest, size: 20),
            ),
          ),
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }
}

/// Parents section: father and mother selectors.
class BirdFormParentsSection extends StatelessWidget {
  final String? fatherId;
  final String? motherId;
  final String? editBirdId;
  final ValueChanged<String?> onFatherChanged;
  final ValueChanged<String?> onMotherChanged;

  const BirdFormParentsSection({
    super.key,
    required this.fatherId,
    required this.motherId,
    this.editBirdId,
    required this.onFatherChanged,
    required this.onMotherChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BirdFormSectionHeader('birds.parents'.tr()),
        BirdParentSelector(
          label: 'birds.select_father'.tr(),
          icon: const AppIcon(AppIcons.male, size: 20),
          selectedId: fatherId,
          excludeId: editBirdId,
          genderFilter: BirdGender.male,
          onChanged: onFatherChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        BirdParentSelector(
          label: 'birds.select_mother'.tr(),
          icon: const AppIcon(AppIcons.female, size: 20),
          selectedId: motherId,
          excludeId: editBirdId,
          genderFilter: BirdGender.female,
          onChanged: onMotherChanged,
        ),
      ],
    );
  }
}

/// Notes section: optional notes text field.
class BirdFormNotesSection extends StatelessWidget {
  final TextEditingController notesController;

  const BirdFormNotesSection({super.key, required this.notesController});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: notesController,
      decoration: InputDecoration(
        labelText: 'common.notes_optional'.tr(),
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      maxLines: 4,
      maxLength: 300,
      textInputAction: TextInputAction.done,
    );
  }
}
