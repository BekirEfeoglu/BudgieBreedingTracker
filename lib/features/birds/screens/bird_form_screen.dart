import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_form_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_form_sections.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_form_helpers.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/bird_genotype_mapper.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

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
    if (userId.isEmpty || userId == 'anonymous') {
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = 'Kuş-1';
      }
      return;
    }

    try {
      final repo = ref.read(birdRepositoryProvider);
      final birds = await repo.getAll(userId);
      const prefix = 'Kuş-';
      final regex = RegExp(r'^Kuş-(\d+)$');
      var maxNumber = 0;

      for (final bird in birds) {
        final match = regex.firstMatch(bird.name.trim());
        if (match == null) continue;
        final current = int.tryParse(match.group(1)!);
        if (current != null && current > maxNumber) {
          maxNumber = current;
        }
      }

      if (!mounted || _nameController.text.trim().isNotEmpty) return;
      _nameController.text = '$prefix${maxNumber + 1}';
    } catch (_) {
      if (mounted && _nameController.text.trim().isEmpty) {
        _nameController.text = 'Kuş-1';
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
          error: (error, _) {
            setState(() {
              _existingBird = null;
              _isEditLoading = false;
              _isEditNotFound = false;
              _editLoadError = error;
            });
          },
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

            // Hydrate controllers only while loading; avoid overwriting user edits
            // if the source stream emits subsequent updates.
            if (_existingBird != null && !_isEditLoading) return;

            final isOtherColor = bird.colorMutation == BirdColor.other;
            setState(() {
              _existingBird = bird;
              _nameController.text = bird.name;
              _gender = bird.gender;
              _species = bird.species;
              _colorMutation = bird.colorMutation == BirdColor.unknown
                  ? null
                  : bird.colorMutation;
              _genotype = BirdGenotypeMapper.birdToGenotype(bird);
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
          },
        );
      },
      fireImmediately: true,
    );
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
      if (state.isSuccess) {
        final remaining = state.remainingBirds;
        ref.read(birdFormStateProvider.notifier).reset();
        if (remaining != null && remaining <= 5 && remaining > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'premium.limit_approaching_birds'.tr(args: ['$remaining']),
              ),
              action: SnackBarAction(
                label: 'premium.try_free_trial'.tr(),
                onPressed: () => context.push(AppRoutes.premium),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('common.saved_successfully'.tr())),
          );
        }
        context.pop();
      }
      if (state.isBirdLimitReached) {
        ref.read(birdFormStateProvider.notifier).reset();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('premium.title'.tr()),
            content: Text(state.error ?? ''),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('common.cancel'.tr()),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push(AppRoutes.premium);
                },
                child: Text('premium.upgrade_to_unlock'.tr()),
              ),
            ],
          ),
        );
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
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BirdFormBasicInfoSection(
                nameController: _nameController,
                gender: _gender,
                species: _species,
                colorMutation: _colorMutation,
                colorNoteController: _colorNoteController,
                onGenderChanged: (g) => setState(() {
                  _gender = g;
                  _genotype = normalizeGenotypeForGender(
                    genotype: _genotype,
                    gender: g,
                  );
                }),
                onSpeciesChanged: (s) => setState(() => _species = s),
                onColorChanged: (c) => setState(() => _colorMutation = c),
              ),
              const SizedBox(height: AppSpacing.xl),
              BirdFormGeneticsSection(
                gender: _gender,
                genotype: _genotype,
                onGenotypeChanged: (genotype) =>
                    setState(() => _genotype = genotype),
              ),
              const SizedBox(height: AppSpacing.xl),
              BirdFormIdentitySection(
                ringController: _ringController,
                cageController: _cageController,
                birthDate: _birthDate,
                onBirthDateChanged: (d) => setState(() => _birthDate = d),
              ),
              const SizedBox(height: AppSpacing.xl),
              BirdFormParentsSection(
                fatherId: _fatherId,
                motherId: _motherId,
                editBirdId: widget.editBirdId,
                onFatherChanged: (id) => setState(() => _fatherId = id),
                onMotherChanged: (id) => setState(() => _motherId = id),
              ),
              const SizedBox(height: AppSpacing.xl),
              BirdFormNotesSection(notesController: _notesController),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: _isEdit ? 'common.update'.tr() : 'common.save'.tr(),
                isLoading: formState.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final userId = ref.read(currentUserIdProvider);
    final notifier = ref.read(birdFormStateProvider.notifier);
    final notes = buildNotes(
      colorMutation: _colorMutation,
      colorNoteText: _colorNoteController.text,
      notesText: _notesController.text,
    );
    final selectedGenotype = ParentGenotype(
      mutations: Map<String, AlleleState>.from(_genotype.mutations),
      gender: _gender,
    );
    final genotypeForSave = selectedGenotype.isNotEmpty
        ? selectedGenotype
        : BirdGenotypeMapper.genotypeFromColor(
            gender: _gender,
            color: _colorMutation,
          );
    final mutationIds = BirdGenotypeMapper.mutationIdsFromGenotype(
      genotypeForSave,
    );
    final genotypeInfo = BirdGenotypeMapper.genotypeInfoFromGenotype(
      genotypeForSave,
    );
    final ringNumber = _ringController.text.trim();
    final cageNumber = _cageController.text.trim();

    if (_isEdit && _existingBird != null) {
      notifier.updateBird(
        _existingBird!.copyWith(
          name: _nameController.text.trim(),
          gender: _gender,
          species: _species,
          colorMutation: _colorMutation,
          ringNumber: ringNumber.isEmpty ? null : ringNumber,
          birthDate: _birthDate,
          fatherId: _fatherId,
          motherId: _motherId,
          cageNumber: cageNumber.isEmpty ? null : cageNumber,
          notes: notes,
          mutations: mutationIds,
          genotypeInfo: genotypeInfo,
        ),
      );
    } else {
      notifier.createBird(
        userId: userId,
        name: _nameController.text.trim(),
        gender: _gender,
        species: _species,
        colorMutation: _colorMutation,
        ringNumber: ringNumber.isEmpty ? null : ringNumber,
        birthDate: _birthDate,
        fatherId: _fatherId,
        motherId: _motherId,
        cageNumber: cageNumber.isEmpty ? null : cageNumber,
        notes: notes,
        mutations: mutationIds,
        genotypeInfo: genotypeInfo,
      );
    }
  }
}
