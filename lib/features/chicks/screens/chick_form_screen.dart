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
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/date_picker_field.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_form_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';

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

  BirdGender _gender = BirdGender.unknown;
  ChickHealthStatus _healthStatus = ChickHealthStatus.healthy;
  DateTime? _hatchDate;
  bool _isEdit = false;
  bool _didPopulateFromExisting = false;
  Chick? _existingChick;

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
    _didPopulateFromExisting = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ringController.dispose();
    _hatchWeightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(chickFormStateProvider);

    ref.listen<ChickFormState>(chickFormStateProvider, (_, state) {
      if (state.isSuccess) {
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

  Scaffold _buildFormScaffold(BuildContext context, ChickFormState formState) {
    return Scaffold(
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
                  // Name (optional)
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'chicks.name_optional'.tr(),
                      border: const OutlineInputBorder(),
                      prefixIcon: const AppIcon(AppIcons.chick),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Gender - SegmentedButton
                  Text(
                    'chicks.gender'.tr(),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<BirdGender>(
                    segments: [
                      ButtonSegment(
                        value: BirdGender.male,
                        label: Text('chicks.male'.tr()),
                        icon: const AppIcon(AppIcons.male),
                      ),
                      ButtonSegment(
                        value: BirdGender.female,
                        label: Text('chicks.female'.tr()),
                        icon: const AppIcon(AppIcons.female),
                      ),
                      ButtonSegment(
                        value: BirdGender.unknown,
                        label: Text('chicks.unknown_gender'.tr()),
                        icon: const Icon(LucideIcons.helpCircle),
                      ),
                    ],
                    selected: {_gender},
                    onSelectionChanged: (selection) {
                      setState(() => _gender = selection.first);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Health Status - SegmentedButton
                  Text(
                    'chicks.health_status'.tr(),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<ChickHealthStatus>(
                    segments: [
                      ButtonSegment(
                        value: ChickHealthStatus.healthy,
                        label: Text('chicks.healthy'.tr()),
                        icon: const AppIcon(AppIcons.health),
                      ),
                      ButtonSegment(
                        value: ChickHealthStatus.sick,
                        label: Text('chicks.sick'.tr()),
                        icon: const AppIcon(AppIcons.health),
                      ),
                      ButtonSegment(
                        value: ChickHealthStatus.unknown,
                        label: Text('chicks.unknown_gender'.tr()),
                        icon: const Icon(LucideIcons.helpCircle),
                      ),
                    ],
                    selected: {_healthStatus},
                    onSelectionChanged: (selection) {
                      setState(() => _healthStatus = selection.first);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Hatch Date
                  DatePickerField(
                    label: 'chicks.hatch_date_required'.tr(),
                    value: _hatchDate,
                    onChanged: (date) => setState(() => _hatchDate = date),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    dateFormatter: ref.watch(dateFormatProvider).formatter(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Hatch Weight
                  TextFormField(
                    controller: _hatchWeightController,
                    decoration: InputDecoration(
                      labelText: 'chicks.birth_weight_label'.tr(),
                      border: const OutlineInputBorder(),
                      prefixIcon: const AppIcon(AppIcons.weight),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed <= 0) {
                        return 'chicks.invalid_number'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Ring Number
                  TextFormField(
                    controller: _ringController,
                    decoration: InputDecoration(
                      labelText: 'chicks.ring_number'.tr(),
                      border: const OutlineInputBorder(),
                      prefixIcon: const AppIcon(AppIcons.ring),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Notes
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
    );
  }

  void _submit() {
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
        ),
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
    );
  }

  double? _parseOptional(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.trim());
  }
}
