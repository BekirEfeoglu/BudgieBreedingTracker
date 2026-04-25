import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/species/species_profile.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/cards/info_card.dart';
import 'package:budgie_breeding_tracker/core/widgets/date_picker_field.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/birds/utils/bird_display_utils.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/mutation_selector.dart'; // Cross-feature import: birds↔genetics mutation selection UI
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_parent_selector.dart';

export 'bird_form_basic_info_section.dart';

/// Genetics section: optional detailed mutation and allele-state profile.
class BirdFormGeneticsSection extends StatelessWidget {
  final Species species;
  final GeneticsMode geneticsMode;
  final BirdGender gender;
  final ParentGenotype genotype;
  final ValueChanged<ParentGenotype> onGenotypeChanged;

  const BirdFormGeneticsSection({
    super.key,
    required this.species,
    required this.geneticsMode,
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

    final helpKey = switch (geneticsMode) {
      GeneticsMode.full => 'birds.genetics_help_full',
      GeneticsMode.limited => 'birds.genetics_help_limited',
      GeneticsMode.none => 'birds.genetics_help_none',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BirdFormSectionHeader('genetics.title'.tr()),
        if (geneticsMode == GeneticsMode.full)
          MutationSelector(
            label: 'genetics.individual_mutations'.tr(),
            icon: const AppIcon(AppIcons.dna),
            genotype: normalized,
            onGenotypeChanged: onGenotypeChanged,
          )
        else
          InfoCard(
            icon: const AppIcon(AppIcons.info),
            title: 'genetics.title'.tr(),
            subtitle: helpKey.tr(args: [speciesLabel(species)]),
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
  final DateFormat? dateFormatter;

  const BirdFormIdentitySection({
    super.key,
    required this.ringController,
    required this.cageController,
    required this.birthDate,
    required this.onBirthDateChanged,
    this.dateFormatter,
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
          dateFormatter: dateFormatter,
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
  final Species species;
  final String? fatherId;
  final String? motherId;
  final String? editBirdId;
  final ValueChanged<String?> onFatherChanged;
  final ValueChanged<String?> onMotherChanged;

  const BirdFormParentsSection({
    super.key,
    required this.species,
    required this.fatherId,
    required this.motherId,
    this.editBirdId,
    required this.onFatherChanged,
    required this.onMotherChanged,
  });

  @override
  Widget build(BuildContext context) {
    final parentSpeciesFilter = species == Species.unknown ? null : species;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BirdFormSectionHeader('birds.parents'.tr()),
        BirdParentSelector(
          label: 'birds.select_father'.tr(),
          icon: const AppIcon(AppIcons.male, size: 20),
          selectedId: fatherId,
          excludeId: editBirdId,
          speciesFilter: parentSpeciesFilter,
          genderFilter: BirdGender.male,
          onChanged: onFatherChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        BirdParentSelector(
          label: 'birds.select_mother'.tr(),
          icon: const AppIcon(AppIcons.female, size: 20),
          selectedId: motherId,
          excludeId: editBirdId,
          speciesFilter: parentSpeciesFilter,
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
