import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_form_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_form_body.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_form_helpers.dart';

/// Form screen for creating or editing a bird.
class BirdFormScreen extends ConsumerStatefulWidget {
  final String? editBirdId;

  const BirdFormScreen({super.key, this.editBirdId});

  @override
  ConsumerState<BirdFormScreen> createState() => _BirdFormScreenState();
}

class _BirdFormScreenState extends ConsumerState<BirdFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ringController = TextEditingController();
  final _cageController = TextEditingController();
  final _notesController = TextEditingController();
  final _colorNoteController = TextEditingController();

  BirdGender _gender = BirdGender.unknown;
  Species _species = Species.budgie;
  BirdColor? _colorMutation;
  DateTime? _birthDate;
  String? _fatherId;
  String? _motherId;
  ParentGenotype _genotype = const ParentGenotype.empty(
    gender: BirdGender.unknown,
  );
  bool _isEdit = false;
  bool _isEditLoading = false;
  bool _isEditNotFound = false;
  Object? _editLoadError;
  ProviderSubscription<AsyncValue<Bird?>>? _editBirdSubscription;
  Bird? _existingBird;

  @override
  void initState() {
    super.initState();
    if (widget.editBirdId != null) {
      _isEdit = true;
      _isEditLoading = true;
      _loadExistingBird();
    } else {
      _setDefaultBirdName();
    }
  }

  Future<void> _setDefaultBirdName() async {
    final userId = ref.read(currentUserIdProvider);
    final prefix = 'birds.default_name_prefix'.tr();
    if (userId.isEmpty || userId == 'anonymous') {
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = '${prefix}1';
      }
      return;
    }
    try {
      final birds = await ref.read(birdRepositoryProvider).getAll(userId);
      if (!mounted || _nameController.text.trim().isNotEmpty) return;
      _nameController.text = nextDefaultBirdName(
        prefix,
        birds.map((b) => b.name).toList(),
      );
    } catch (e) {
      AppLogger.error('[BirdFormScreen]', e, StackTrace.current);
      if (mounted && _nameController.text.trim().isEmpty) {
        _nameController.text = '${prefix}1';
      }
    }
  }

  void _loadExistingBird() {
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
    setState(() {
      _existingBird = bird;
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
  }

  @override
  void dispose() {
    _editBirdSubscription?.close();
    _nameController.dispose();
    _ringController.dispose();
    _cageController.dispose();
    _notesController.dispose();
    _colorNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(birdFormStateProvider);

    ref.listen<BirdFormState>(birdFormStateProvider, (_, state) {
      final notifier = ref.read(birdFormStateProvider.notifier);
      if (state.isSuccess) {
        notifier.reset();
        handleBirdFormSuccess(context, remainingBirds: state.remainingBirds);
      } else if (state.isBirdLimitReached) {
        notifier.reset();
        showBirdLimitDialog(context, errorMessage: state.error);
      } else if (state.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error!)));
      }
    });

    if (_isEdit && _isEditLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('common.loading'.tr())),
        body: const LoadingState(),
      );
    }

    if (_isEdit && _existingBird == null) {
      final errorMessage = _isEditNotFound
          ? 'birds.not_found'.tr()
          : _editLoadError?.toString() ?? 'common.data_load_error'.tr();
      return Scaffold(
        appBar: AppBar(title: Text('birds.edit_bird'.tr())),
        body: ErrorState(
          message: errorMessage,
          onRetry: () {
            _loadExistingBird();
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'birds.edit_bird'.tr() : 'birds.new_bird'.tr()),
      ),
      body: BirdFormBody(
        formKey: _formKey,
        nameController: _nameController,
        ringController: _ringController,
        cageController: _cageController,
        notesController: _notesController,
        colorNoteController: _colorNoteController,
        gender: _gender,
        species: _species,
        colorMutation: _colorMutation,
        birthDate: _birthDate,
        fatherId: _fatherId,
        motherId: _motherId,
        editBirdId: widget.editBirdId,
        genotype: _genotype,
        isEdit: _isEdit,
        isLoading: formState.isLoading,
        onGenderChanged: (g) => setState(() {
          _gender = g;
          _genotype = normalizeGenotypeForGender(
            genotype: _genotype,
            gender: g,
          );
        }),
        onSpeciesChanged: (s) => setState(() => _species = s),
        onColorChanged: (c) => setState(() => _colorMutation = c),
        onGenotypeChanged: (genotype) => setState(() {
          _genotype = normalizeGenotypeForGender(
            genotype: genotype,
            gender: _gender,
          );
        }),
        onBirthDateChanged: (d) => setState(() => _birthDate = d),
        onFatherChanged: (id) => setState(() => _fatherId = id),
        onMotherChanged: (id) => setState(() => _motherId = id),
        onSubmit: _submit,
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    AppHaptics.lightImpact();
    submitBirdForm(
      notifier: ref.read(birdFormStateProvider.notifier),
      userId: ref.read(currentUserIdProvider),
      existingBird: (_isEdit && _existingBird != null) ? _existingBird : null,
      name: _nameController.text.trim(),
      gender: _gender,
      species: _species,
      colorMutation: _colorMutation,
      genotype: _genotype,
      ringNumber: _ringController.text.trim(),
      cageNumber: _cageController.text.trim(),
      birthDate: _birthDate,
      fatherId: _fatherId,
      motherId: _motherId,
      colorNoteText: _colorNoteController.text,
      notesText: _notesController.text,
    );
  }
}
