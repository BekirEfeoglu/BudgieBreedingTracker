import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/date_picker_field.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_form_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/unsaved_changes_scope.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/bird_selector_field.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

/// Form screen for creating or editing a breeding pair.
class BreedingFormScreen extends ConsumerStatefulWidget {
  final String? editPairId;

  const BreedingFormScreen({super.key, this.editPairId});

  @override
  ConsumerState<BreedingFormScreen> createState() => _BreedingFormScreenState();
}

class _BreedingFormScreenState extends ConsumerState<BreedingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _maleId;
  String? _femaleId;
  DateTime _pairingDate = DateTime.now();
  final _cageController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isEdit = false;
  bool _isLoadingExistingPair = false;
  BreedingPair? _existingPair;
  bool _savedSuccessfully = false;

  bool get _isDirty {
    if (_savedSuccessfully) return false;
    if (_isEdit) {
      final existing = _existingPair;
      if (existing == null) return true;
      return _maleId != existing.maleId ||
          _femaleId != existing.femaleId ||
          _pairingDate != existing.pairingDate ||
          _cageController.text != (existing.cageNumber ?? '') ||
          _notesController.text != (existing.notes ?? '');
    }
    return _maleId != null ||
        _femaleId != null ||
        _cageController.text.isNotEmpty ||
        _notesController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    if (widget.editPairId != null) {
      _isEdit = true;
      _loadExistingPair();
    }
  }

  Future<void> _loadExistingPair() async {
    final editPairId = widget.editPairId;
    if (editPairId == null) return;

    setState(() => _isLoadingExistingPair = true);
    try {
      final pair = await ref.read(breedingPairByIdProvider(editPairId).future);
      if (!mounted) return;

      if (pair != null) {
        setState(() {
          _existingPair = pair;
          _maleId = pair.maleId;
          _femaleId = pair.femaleId;
          _pairingDate = pair.pairingDate ?? DateTime.now();
          _cageController.text = pair.cageNumber ?? '';
          _notesController.text = pair.notes ?? '';
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('common.data_load_error'.tr())));
    } finally {
      if (mounted) {
        setState(() => _isLoadingExistingPair = false);
      }
    }
  }

  @override
  void dispose() {
    _cageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final birdsAsync = ref.watch(birdsStreamProvider(userId));
    final maleBirds = ref.watch(maleBirdsProvider(userId));
    final femaleBirds = ref.watch(femaleBirdsProvider(userId));
    final formState = ref.watch(breedingFormStateProvider);

    ref.listen<BreedingFormState>(breedingFormStateProvider, (_, state) {
      if (state.isSuccess) {
        _savedSuccessfully = true;
        ref.read(breedingFormStateProvider.notifier).reset();
        context.pop();
      }
      if (state.isBreedingLimitReached || state.isIncubationLimitReached) {
        final errorMessage = state.error ?? '';
        ref.read(breedingFormStateProvider.notifier).reset();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('premium.title'.tr()),
            content: Text(errorMessage),
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

    return UnsavedChangesScope(
      isDirty: _isDirty,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEdit
                ? 'breeding.edit_breeding'.tr()
                : 'breeding.new_breeding'.tr(),
          ),
        ),
        body: birdsAsync.when(
          loading: () => const LoadingState(),
          error: (_, __) => ErrorState(
            message: 'common.data_load_error'.tr(),
            onRetry: () => ref.invalidate(birdsStreamProvider(userId)),
          ),
          data: (allBirds) {
            Bird? selectedMale;
            Bird? selectedFemale;
            for (final bird in allBirds) {
              if (bird.id == _maleId) selectedMale = bird;
              if (bird.id == _femaleId) selectedFemale = bird;
            }

            final availableMaleBirds = maleBirds.where((bird) {
              if (selectedFemale == null) return true;
              return bird.species == selectedFemale.species;
            }).toList();
            final availableFemaleBirds = femaleBirds.where((bird) {
              if (selectedMale == null) return true;
              return bird.species == selectedMale.species;
            }).toList();

            if (_isEdit && _isLoadingExistingPair) {
              return const LoadingState();
            }
            if (_isEdit && _existingPair == null) {
              return Center(child: Text('breeding.not_found'.tr()));
            }

            if (allBirds.isEmpty && !_isEdit) {
              return EmptyState(
                icon: const AppIcon(AppIcons.bird),
                title: 'breeding.no_birds_to_pair'.tr(),
                subtitle: 'breeding.no_birds_to_pair_hint'.tr(),
                actionLabel: 'birds.add_bird'.tr(),
                onAction: () => context.push('/birds/form'),
              );
            }

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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        DatePickerField(
                          label: 'breeding.pairing_date'.tr(),
                          value: _pairingDate,
                          onChanged: (date) =>
                              setState(() => _pairingDate = date),
                          dateFormatter: ref
                              .watch(dateFormatProvider)
                              .formatter(),
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
                          label: _isEdit
                              ? 'common.update'.tr()
                              : 'common.save'.tr(),
                          isLoading: formState.isLoading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
          cageNumber: _cageController.text.isEmpty
              ? null
              : _cageController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
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
        cageNumber: _cageController.text.isEmpty ? null : _cageController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
    }
  }
}
