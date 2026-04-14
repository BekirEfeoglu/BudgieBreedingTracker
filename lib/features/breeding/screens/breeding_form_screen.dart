import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
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
import 'package:budgie_breeding_tracker/data/providers/date_format_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/providers/bird_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_form_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/unsaved_changes_scope.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/bird_selector_field.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';

part 'breeding_form_body.dart';

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
    } catch (e, st) {
      AppLogger.error('[BreedingFormScreen] Failed to load pair', e, st);
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
      if (!mounted) return;
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

            return buildFormBody(
              allBirds: allBirds,
              availableMaleBirds: availableMaleBirds,
              availableFemaleBirds: availableFemaleBirds,
              selectedMale: selectedMale,
              selectedFemale: selectedFemale,
              formState: formState,
            );
          },
        ),
      ),
    );
  }
}
