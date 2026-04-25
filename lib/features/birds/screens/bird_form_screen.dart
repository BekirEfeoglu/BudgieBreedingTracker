import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/species/species_profile.dart';
import 'package:budgie_breeding_tracker/core/species/species_registry.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_detail_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_form_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/unsaved_changes_scope.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_form_body.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_form_helpers.dart';

part 'bird_form_screen_helpers.dart';

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
  Species _species = Species.unknown;
  BirdColor? _colorMutation;
  DateTime? _birthDate;
  XFile? _photoFile;
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
  bool _savedSuccessfully = false;
  String? _generatedDefaultName;
  bool _isProgrammaticControllerUpdate = false;

  bool get _isDirty {
    if (_savedSuccessfully) return false;
    if (_isEdit) {
      final existing = _existingBird;
      if (existing == null) return true;
      final existingColor = existing.colorMutation == BirdColor.unknown
          ? null
          : existing.colorMutation;
      final notes = buildNotes(
        colorMutation: _colorMutation,
        colorNoteText: _colorNoteController.text,
        notesText: _notesController.text,
      );
      final genotypeData = prepareBirdGenotypeData(
        genotype: _genotype,
        gender: _gender,
        species: _species,
        colorMutation: _colorMutation,
      );
      final ring = _ringController.text.trim().isEmpty
          ? null
          : _ringController.text.trim();
      final cage = _cageController.text.trim().isEmpty
          ? null
          : _cageController.text.trim();
      return _nameController.text.trim() != existing.name ||
          _gender != existing.gender ||
          _species != existing.species ||
          _colorMutation != existingColor ||
          ring != existing.ringNumber ||
          _birthDate != existing.birthDate ||
          _fatherId != existing.fatherId ||
          _motherId != existing.motherId ||
          cage != existing.cageNumber ||
          notes != existing.notes ||
          !listEquals(genotypeData.mutationIds, existing.mutations) ||
          !mapEquals(genotypeData.genotypeInfo, existing.genotypeInfo);
    }
    final name = _nameController.text.trim();
    final generatedName = _generatedDefaultName;
    return (name.isNotEmpty && name != generatedName) ||
        _gender != BirdGender.unknown ||
        _species != Species.unknown ||
        _colorMutation != null ||
        _photoFile != null ||
        _ringController.text.trim().isNotEmpty ||
        _cageController.text.trim().isNotEmpty ||
        _notesController.text.trim().isNotEmpty ||
        _colorNoteController.text.trim().isNotEmpty ||
        _birthDate != null ||
        _fatherId != null ||
        _motherId != null ||
        _genotype.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_handleControllerChanged);
    _ringController.addListener(_handleControllerChanged);
    _cageController.addListener(_handleControllerChanged);
    _notesController.addListener(_handleControllerChanged);
    _colorNoteController.addListener(_handleControllerChanged);
    if (widget.editBirdId != null) {
      _isEdit = true;
      _isEditLoading = true;
      loadExistingBird();
    } else {
      setDefaultBirdName();
    }
  }

  @override
  void dispose() {
    _editBirdSubscription?.close();
    _nameController.removeListener(_handleControllerChanged);
    _ringController.removeListener(_handleControllerChanged);
    _cageController.removeListener(_handleControllerChanged);
    _notesController.removeListener(_handleControllerChanged);
    _colorNoteController.removeListener(_handleControllerChanged);
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
      if (!mounted) return;
      final notifier = ref.read(birdFormStateProvider.notifier);
      if (state.isSuccess) {
        _savedSuccessfully = true;
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
            loadExistingBird();
          },
        ),
      );
    }

    return UnsavedChangesScope(
      isDirty: _isDirty,
      child: Scaffold(
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
          photoFile: _isEdit ? null : _photoFile,
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
          onPickPhotoSource: _isEdit ? null : _pickPhoto,
          onRemovePhoto: _isEdit
              ? null
              : () => setState(() => _photoFile = null),
          onGenderChanged: (g) => setState(() {
            _gender = g;
            _genotype = normalizeGenotypeForGender(
              genotype: _genotype,
              gender: g,
            );
          }),
          onSpeciesChanged: (s) => setState(() {
            final profile = SpeciesRegistry.of(s);
            _species = s;
            _fatherId = null;
            _motherId = null;
            if (!profile.supportedColors.contains(_colorMutation)) {
              _colorMutation = null;
              _colorNoteController.clear();
            }
            if (profile.geneticsMode != GeneticsMode.full) {
              _genotype = ParentGenotype.empty(gender: _gender);
            }
          }),
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
      ),
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
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
      photoFile: _isEdit ? null : _photoFile,
    );
  }

  Future<void> _pickPhoto() async {
    final source = await _pickPhotoSource();
    if (source == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (!mounted || picked == null) return;
      setState(() => _photoFile = picked);
    } catch (e) {
      AppLogger.warning('Failed to pick bird form photo: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('birds.photo_upload_error'.tr())));
    }
  }

  Future<ImageSource?> _pickPhotoSource() {
    final theme = Theme.of(context);

    return showModalBottomSheet<ImageSource>(
      context: context,
      constraints: const BoxConstraints(maxWidth: AppSpacing.maxSheetWidth),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'birds.add_photo'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const AppIcon(AppIcons.photo),
                title: Text('birds.photo_source_gallery'.tr()),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(LucideIcons.camera),
                title: Text('birds.photo_source_camera'.tr()),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleControllerChanged() {
    if (_isProgrammaticControllerUpdate || !mounted) return;
    setState(() {});
  }
}
