import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_form_sections.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';

/// Form body containing all bird form sections and the submit button.
class BirdFormBody extends ConsumerWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController ringController;
  final TextEditingController cageController;
  final TextEditingController notesController;
  final TextEditingController colorNoteController;
  final BirdGender gender;
  final Species species;
  final BirdColor? colorMutation;
  final DateTime? birthDate;
  final String? fatherId;
  final String? motherId;
  final String? editBirdId;
  final ParentGenotype genotype;
  final bool isEdit;
  final bool isLoading;
  final ValueChanged<BirdGender> onGenderChanged;
  final ValueChanged<Species> onSpeciesChanged;
  final ValueChanged<BirdColor?> onColorChanged;
  final ValueChanged<ParentGenotype> onGenotypeChanged;
  final ValueChanged<DateTime?> onBirthDateChanged;
  final ValueChanged<String?> onFatherChanged;
  final ValueChanged<String?> onMotherChanged;
  final VoidCallback onSubmit;

  const BirdFormBody({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.ringController,
    required this.cageController,
    required this.notesController,
    required this.colorNoteController,
    required this.gender,
    required this.species,
    required this.colorMutation,
    required this.birthDate,
    required this.fatherId,
    required this.motherId,
    required this.editBirdId,
    required this.genotype,
    required this.isEdit,
    required this.isLoading,
    required this.onGenderChanged,
    required this.onSpeciesChanged,
    required this.onColorChanged,
    required this.onGenotypeChanged,
    required this.onBirthDateChanged,
    required this.onFatherChanged,
    required this.onMotherChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BirdFormBasicInfoSection(
                  nameController: nameController,
                  gender: gender,
                  species: species,
                  colorMutation: colorMutation,
                  colorNoteController: colorNoteController,
                  onGenderChanged: onGenderChanged,
                  onSpeciesChanged: onSpeciesChanged,
                  onColorChanged: onColorChanged,
                ),
                const SizedBox(height: AppSpacing.xl),
                BirdFormGeneticsSection(
                  gender: gender,
                  genotype: genotype,
                  onGenotypeChanged: onGenotypeChanged,
                ),
                const SizedBox(height: AppSpacing.xl),
                BirdFormIdentitySection(
                  ringController: ringController,
                  cageController: cageController,
                  birthDate: birthDate,
                  onBirthDateChanged: onBirthDateChanged,
                  dateFormatter: ref.watch(dateFormatProvider).formatter(),
                ),
                const SizedBox(height: AppSpacing.xl),
                BirdFormParentsSection(
                  fatherId: fatherId,
                  motherId: motherId,
                  editBirdId: editBirdId,
                  onFatherChanged: onFatherChanged,
                  onMotherChanged: onMotherChanged,
                ),
                const SizedBox(height: AppSpacing.xl),
                BirdFormNotesSection(notesController: notesController),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: isEdit ? 'common.update'.tr() : 'common.save'.tr(),
                  isLoading: isLoading,
                  onPressed: onSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
