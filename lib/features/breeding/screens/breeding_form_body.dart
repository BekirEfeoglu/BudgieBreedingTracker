part of 'breeding_form_screen.dart';

extension _BreedingFormBody on _BreedingFormScreenState {
  Widget buildFormBody({
    required List<Bird> allBirds,
    required List<Bird> availableMaleBirds,
    required List<Bird> availableFemaleBirds,
    required Bird? selectedMale,
    required Bird? selectedFemale,
    required BreedingFormState formState,
  }) {
    return Form(
      key: _formKey,
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
                BirdSelectorField(
                  label:
                      '${'breeding.male_bird'.tr()} (${availableMaleBirds.length})',
                  birds: availableMaleBirds,
                  selectedId: _maleId,
                  onChanged: (id) => setState(() {
                    _maleId = id;
                    Bird? nextMale;
                    for (final bird in allBirds) {
                      if (bird.id == id) {
                        nextMale = bird;
                        break;
                      }
                    }
                    if (nextMale != null &&
                        selectedFemale != null &&
                        nextMale.species != selectedFemale.species) {
                      _femaleId = null;
                    }
                  }),
                  gender: BirdGender.male,
                ),
                const SizedBox(height: AppSpacing.lg),
                BirdSelectorField(
                  label:
                      '${'breeding.female_bird'.tr()} (${availableFemaleBirds.length})',
                  birds: availableFemaleBirds,
                  selectedId: _femaleId,
                  onChanged: (id) => setState(() {
                    _femaleId = id;
                    Bird? nextFemale;
                    for (final bird in allBirds) {
                      if (bird.id == id) {
                        nextFemale = bird;
                        break;
                      }
                    }
                    if (nextFemale != null &&
                        selectedMale != null &&
                        nextFemale.species != selectedMale.species) {
                      _maleId = null;
                    }
                  }),
                  gender: BirdGender.female,
                ),
                if (selectedMale != null &&
                    selectedFemale != null &&
                    selectedMale.species != selectedFemale.species) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'breeding.same_species_required'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                DatePickerField(
                  label: 'breeding.pairing_date'.tr(),
                  value: _pairingDate,
                  onChanged: (date) => setState(() => _pairingDate = date),
                  dateFormatter: ref.watch(dateFormatProvider).formatter(),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _cageController,
                  decoration: InputDecoration(
                    labelText: 'breeding.cage_number'.tr(),
                    border: const OutlineInputBorder(),
                    prefixIcon: const AppIcon(AppIcons.nest),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'common.notes'.tr(),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(LucideIcons.stickyNote),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.xxl),
                PrimaryButton(
                  label:
                      _isEdit ? 'common.update'.tr() : 'common.save'.tr(),
                  isLoading: formState.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    AppHaptics.lightImpact();

    final userId = ref.read(currentUserIdProvider);
    final notifier = ref.read(breedingFormStateProvider.notifier);

    if (_isEdit && widget.editPairId != null) {
      final existingPair = _existingPair;
      if (existingPair == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('common.data_load_error'.tr())));
        return;
      }
      if (_maleId == null || _femaleId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('breeding.select_birds_required'.tr())),
        );
        return;
      }
      notifier.updateBreeding(
        existingPair.copyWith(
          maleId: _maleId,
          femaleId: _femaleId,
          pairingDate: _pairingDate,
          cageNumber:
              _cageController.text.isEmpty ? null : _cageController.text,
          notes:
              _notesController.text.isEmpty ? null : _notesController.text,
        ),
      );
    } else {
      if (_maleId == null || _femaleId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('breeding.select_birds_required'.tr())),
        );
        return;
      }
      notifier.createBreeding(
        userId: userId,
        maleId: _maleId!,
        femaleId: _femaleId!,
        pairingDate: _pairingDate,
        cageNumber:
            _cageController.text.isEmpty ? null : _cageController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
    }
  }
}
