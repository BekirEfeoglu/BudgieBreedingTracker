part of 'bird_form_screen.dart';

extension _BirdFormScreenHelpers on _BirdFormScreenState {
  Future<void> setDefaultBirdName() async {
    final userId = ref.read(currentUserIdProvider);
    final prefix = 'birds.default_name_prefix'.tr();
    if (userId.isEmpty || userId == 'anonymous') {
      if (_nameController.text.trim().isEmpty) {
        _applyGeneratedDefaultName('${prefix}1');
      }
      return;
    }
    try {
      final birds = await ref.read(birdRepositoryProvider).getAll(userId);
      if (!mounted || _nameController.text.trim().isNotEmpty) return;
      _applyGeneratedDefaultName(
        nextDefaultBirdName(prefix, birds.map((b) => b.name).toList()),
      );
    } catch (e) {
      AppLogger.error('[BirdFormScreen]', e, StackTrace.current);
      if (mounted && _nameController.text.trim().isEmpty) {
        _applyGeneratedDefaultName('${prefix}1');
      }
    }
  }

  void loadExistingBird() {
    final editBirdId = widget.editBirdId;
    if (editBirdId == null) return;

    _editBirdSubscription?.close();
    setState(() {
      _isEditLoading = true;
      _isEditNotFound = false;
      _editLoadError = null;
    });
    _editBirdSubscription = ref.listenManual<AsyncValue<Bird?>>(
      birdByIdProvider(editBirdId),
      (_, next) {
        if (!mounted) return;
        next.when(
          loading: () {
            if (!_isEditLoading) {
              setState(() {
                _isEditLoading = true;
                _isEditNotFound = false;
                _editLoadError = null;
              });
            }
          },
          error: (error, _) => setState(() {
            _existingBird = null;
            _isEditLoading = false;
            _isEditNotFound = false;
            _editLoadError = error;
          }),
          data: (bird) {
            if (bird == null) {
              setState(() {
                _existingBird = null;
                _isEditLoading = false;
                _isEditNotFound = true;
                _editLoadError = null;
              });
              return;
            }
            if (_existingBird != null && !_isEditLoading) return;
            _hydrateFromBird(bird);
          },
        );
      },
      fireImmediately: true,
    );
  }

  void _hydrateFromBird(Bird bird) {
    final isOtherColor = bird.colorMutation == BirdColor.other;
    _isProgrammaticControllerUpdate = true;
    try {
      setState(() {
        _existingBird = bird;
        _generatedDefaultName = null;
        _nameController.text = bird.name;
        _gender = bird.gender;
        _species = bird.species;
        _colorMutation = bird.colorMutation == BirdColor.unknown
            ? null
            : bird.colorMutation;
        _genotype = normalizeGenotypeForGender(
          genotype: BirdGenotypeMapper.birdToGenotype(bird),
          gender: bird.gender,
        );
        _ringController.text = bird.ringNumber ?? '';
        _birthDate = bird.birthDate;
        _fatherId = bird.fatherId;
        _motherId = bird.motherId;
        _cageController.text = bird.cageNumber ?? '';
        _colorNoteController.text = isOtherColor
            ? (extractColorNote(bird.notes) ?? '')
            : '';
        _notesController.text = isOtherColor
            ? (notesBody(bird.notes) ?? '')
            : (bird.notes ?? '');
        _isEditLoading = false;
        _isEditNotFound = false;
        _editLoadError = null;
      });
    } finally {
      _isProgrammaticControllerUpdate = false;
    }
  }

  void _applyGeneratedDefaultName(String defaultName) {
    if (!mounted || _nameController.text.trim().isNotEmpty) return;
    _isProgrammaticControllerUpdate = true;
    try {
      setState(() {
        _generatedDefaultName = defaultName;
        _nameController.text = defaultName;
      });
    } finally {
      _isProgrammaticControllerUpdate = false;
    }
  }
}
