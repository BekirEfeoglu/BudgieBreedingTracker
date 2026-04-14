import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_form_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/unsaved_changes_scope.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_form_fields.dart';
import 'package:budgie_breeding_tracker/data/providers/date_format_providers.dart';

/// Form screen for creating or editing a chick.
class ChickFormScreen extends ConsumerStatefulWidget {
  final String? editChickId;

  const ChickFormScreen({super.key, this.editChickId});

  @override
  ConsumerState<ChickFormScreen> createState() => _ChickFormScreenState();
}

class _ChickFormScreenState extends ConsumerState<ChickFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ringController = TextEditingController();
  final _hatchWeightController = TextEditingController();
  final _notesController = TextEditingController();
  final _bandingDayController = TextEditingController(text: '10');

  BirdGender _gender = BirdGender.unknown;
  ChickHealthStatus _healthStatus = ChickHealthStatus.healthy;
  DateTime? _hatchDate;
  bool _isEdit = false;
  bool _didPopulateFromExisting = false;
  Chick? _existingChick;
  bool _savedSuccessfully = false;

  bool get _isDirty {
    if (_savedSuccessfully) return false;
    if (_isEdit) return true;
    return _nameController.text.isNotEmpty ||
        _ringController.text.isNotEmpty ||
        _hatchDate != null ||
        _notesController.text.isNotEmpty ||
        _hatchWeightController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _isEdit = widget.editChickId != null;
  }

  void _populateFromExisting(Chick chick) {
    _existingChick = chick;
    _nameController.text = chick.name ?? '';
    _gender = chick.gender;
    _healthStatus = chick.healthStatus;
    _ringController.text = chick.ringNumber ?? '';
    _hatchDate = chick.hatchDate;
    _hatchWeightController.text = chick.hatchWeight != null
        ? chick.hatchWeight!.toStringAsFixed(1)
        : '';
    _notesController.text = chick.notes ?? '';
    _bandingDayController.text = chick.bandingDay.toString();
    _didPopulateFromExisting = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ringController.dispose();
    _hatchWeightController.dispose();
    _notesController.dispose();
    _bandingDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(chickFormStateProvider);

    ref.listen<ChickFormState>(chickFormStateProvider, (_, state) {
      if (!mounted) return;
      if (state.warning != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.warning!)));
      }
      if (state.isSuccess) {
        _savedSuccessfully = true;
        ref.read(chickFormStateProvider.notifier).reset();
        context.pop();
      }
      if (state.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error!)));
      }
    });

    if (_isEdit) {
      final editId = widget.editChickId!;
      final existingAsync = ref.watch(chickByIdProvider(editId));

      return existingAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: Text('common.loading'.tr())),
          body: const LoadingState(),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: Text('common.error'.tr())),
          body: ErrorState(
            message: 'common.data_load_error'.tr(),
            onRetry: () => ref.invalidate(chickByIdProvider(editId)),
          ),
        ),
        data: (existing) {
          if (existing == null) {
            return Scaffold(
              appBar: AppBar(title: Text('common.not_found'.tr())),
              body: ErrorState(
                message: 'chicks.not_found'.tr(),
                onRetry: () => ref.invalidate(chickByIdProvider(editId)),
              ),
            );
          }

          if (!_didPopulateFromExisting) {
            _populateFromExisting(existing);
          }
          return _buildFormScaffold(context, formState);
        },
      );
    }

    return _buildFormScaffold(context, formState);
  }

  Widget _buildFormScaffold(BuildContext context, ChickFormState formState) {
    return UnsavedChangesScope(
      isDirty: _isDirty,
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'chicks.edit_chick'.tr() : 'chicks.new_chick'.tr(),
        ),
      ),
      body: Form(
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
                  ChickFormFields(
                    nameController: _nameController,
                    ringController: _ringController,
                    hatchWeightController: _hatchWeightController,
                    notesController: _notesController,
                    gender: _gender,
                    healthStatus: _healthStatus,
                    hatchDate: _hatchDate,
                    dateFormatter: ref.watch(dateFormatProvider).formatter(),
                    onGenderChanged: (g) => setState(() => _gender = g),
                    onHealthStatusChanged: (h) =>
                        setState(() => _healthStatus = h),
                    onHatchDateChanged: (d) => setState(() => _hatchDate = d),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Banding Day
                  TextFormField(
                    controller: _bandingDayController,
                    enabled: _existingChick?.isBanded != true,
                    decoration: InputDecoration(
                      labelText: 'chicks.banding_day_label'.tr(),
                      hintText: 'chicks.banding_day_hint'.tr(),
                      border: const OutlineInputBorder(),
                      prefixIcon: const AppIcon(AppIcons.ring),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'validation.required'.tr();
                      }
                      final parsed = int.tryParse(value.trim());
                      if (parsed == null || parsed < 5 || parsed > 21) {
                        return 'chicks.banding_day_validation'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Submit
                  PrimaryButton(
                    label: _isEdit ? 'common.update'.tr() : 'common.save'.tr(),
                    isLoading: formState.isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_hatchDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('chicks.hatch_date_select'.tr())));
      return;
    }
    AppHaptics.lightImpact();

    final userId = ref.read(currentUserIdProvider);
    final notifier = ref.read(chickFormStateProvider.notifier);

    if (_isEdit) {
      if (_existingChick == null) return;
      notifier.updateChick(
        _existingChick!.copyWith(
          name: _nameController.text.isEmpty
              ? null
              : _nameController.text.trim(),
          gender: _gender,
          healthStatus: _healthStatus,
          hatchDate: _hatchDate,
          hatchWeight: _parseOptional(_hatchWeightController.text),
          ringNumber: _ringController.text.isEmpty
              ? null
              : _ringController.text.trim(),
          notes: _notesController.text.isEmpty
              ? null
              : _notesController.text.trim(),
          bandingDay: int.tryParse(_bandingDayController.text.trim()) ?? 10,
        ),
        previous: _existingChick,
      );
      return;
    }

    notifier.createChick(
      userId: userId,
      name: _nameController.text.isEmpty ? null : _nameController.text.trim(),
      gender: _gender,
      healthStatus: _healthStatus,
      hatchDate: _hatchDate!,
      hatchWeight: _parseOptional(_hatchWeightController.text),
      ringNumber: _ringController.text.isEmpty
          ? null
          : _ringController.text.trim(),
      notes: _notesController.text.isEmpty
          ? null
          : _notesController.text.trim(),
      bandingDay: int.tryParse(_bandingDayController.text.trim()) ?? 10,
    );
  }

  double? _parseOptional(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.trim());
  }
}
