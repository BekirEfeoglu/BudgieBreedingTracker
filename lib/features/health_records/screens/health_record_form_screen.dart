import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/date_picker_field.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_form_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/widgets/health_record_animal_selector.dart';
import 'package:budgie_breeding_tracker/features/health_records/widgets/health_record_card.dart';

/// Form screen for creating/editing a health record.
class HealthRecordFormScreen extends ConsumerStatefulWidget {
  final String? editRecordId;
  final String? preselectedBirdId;

  const HealthRecordFormScreen({
    super.key,
    this.editRecordId,
    this.preselectedBirdId,
  });

  @override
  ConsumerState<HealthRecordFormScreen> createState() =>
      _HealthRecordFormScreenState();
}

class _HealthRecordFormScreenState
    extends ConsumerState<HealthRecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _vetController = TextEditingController();
  final _notesController = TextEditingController();
  final _weightController = TextEditingController();
  final _costController = TextEditingController();

  HealthRecordType _type = HealthRecordType.checkup;
  DateTime _date = DateTime.now();
  DateTime? _followUpDate;
  String? _birdId;
  bool _isEdit = false;
  HealthRecord? _existingRecord;

  @override
  void initState() {
    super.initState();
    _birdId = widget.preselectedBirdId;
    if (widget.editRecordId != null) {
      _isEdit = true;
      _loadExistingRecord();
    }
  }

  void _loadExistingRecord() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final recordAsync =
          ref.read(healthRecordByIdProvider(widget.editRecordId!));
      recordAsync.whenData((record) {
        if (record != null && mounted) {
          setState(() {
            _existingRecord = record;
            _titleController.text = record.title;
            _type = record.type;
            _date = record.date;
            _birdId = record.birdId;
            _descriptionController.text = record.description ?? '';
            _treatmentController.text = record.treatment ?? '';
            _vetController.text = record.veterinarian ?? '';
            _notesController.text = record.notes ?? '';
            _weightController.text =
                record.weight != null ? record.weight.toString() : '';
            _costController.text =
                record.cost != null ? record.cost.toString() : '';
            _followUpDate = record.followUpDate;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _treatmentController.dispose();
    _vetController.dispose();
    _notesController.dispose();
    _weightController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(healthRecordFormStateProvider);
    final userId = ref.watch(currentUserIdProvider);
    final birdsAsync = ref.watch(birdsStreamProvider(userId));
    final chicksAsync = ref.watch(chicksStreamProvider(userId));

    ref.listen<HealthRecordFormState>(healthRecordFormStateProvider,
        (_, state) {
      if (state.isSuccess) {
        ref.read(healthRecordFormStateProvider.notifier).reset();
        context.pop();
      }
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!)),
        );
      }
    });

    if (_isEdit && _existingRecord == null) {
      return Scaffold(
        appBar: AppBar(title: Text('common.loading'.tr())),
        body: const LoadingState(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit
            ? 'health_records.edit_record'.tr()
            : 'health_records.new_record'.tr()),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'health_records.record_title'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(LucideIcons.type),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'health_records.title_required'.tr();
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Type
              Text(
                'common.type'.tr(),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: HealthRecordType.values.where((t) => t != HealthRecordType.unknown).map((type) {
                  final isSelected = _type == type;
                  return ChoiceChip(
                    avatar: Icon(
                      healthRecordTypeIcon(type),
                      size: 18,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : healthRecordTypeColor(type),
                    ),
                    label: Text(healthRecordTypeLabel(type)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _type = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Date
              DatePickerField(
                label: 'common.date'.tr(),
                value: _date,
                onChanged: (date) => setState(() => _date = date),
                firstDate: DateTime(2015),
                lastDate: DateTime.now(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Bird / Chick selector
              HealthRecordAnimalSelector(
                selectedId: _birdId,
                birds: birdsAsync.value ?? [],
                chicks: chicksAsync.value ?? [],
                isLoading: birdsAsync.isLoading || chicksAsync.isLoading,
                onChanged: (value) => setState(() => _birdId = value),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'common.description'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(LucideIcons.fileText),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Treatment
              TextFormField(
                controller: _treatmentController,
                decoration: InputDecoration(
                  labelText: 'health_records.treatment'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const AppIcon(AppIcons.health),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Veterinarian
              TextFormField(
                controller: _vetController,
                decoration: InputDecoration(
                  labelText: 'health_records.veterinarian'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const AppIcon(AppIcons.profile),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Weight and Cost row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: InputDecoration(
                        labelText: 'health_records.weight'.tr(),
                        border: const OutlineInputBorder(),
                        suffixText: 'g',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value.trim()) == null) {
                            return 'chicks.invalid_number'.tr();
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      decoration: InputDecoration(
                        labelText: 'health_records.cost'.tr(),
                        border: const OutlineInputBorder(),
                        suffixText: 'settings.currency_symbol'.tr(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value.trim()) == null) {
                            return 'chicks.invalid_number'.tr();
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Follow-up date
              DatePickerField(
                label: 'health_records.follow_up'.tr(),
                value: _followUpDate,
                onChanged: (date) =>
                    setState(() => _followUpDate = date),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                isRequired: false,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'common.notes_optional'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(LucideIcons.stickyNote),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Submit
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
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    AppHaptics.lightImpact();

    final userId = ref.read(currentUserIdProvider);
    final notifier = ref.read(healthRecordFormStateProvider.notifier);

    final weight = _weightController.text.trim().isNotEmpty
        ? double.tryParse(_weightController.text.trim())
        : null;
    final cost = _costController.text.trim().isNotEmpty
        ? double.tryParse(_costController.text.trim())
        : null;

    if (_isEdit && _existingRecord != null) {
      notifier.updateRecord(_existingRecord!.copyWith(
        title: _titleController.text.trim(),
        type: _type,
        date: _date,
        birdId: _birdId,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text.trim(),
        treatment: _treatmentController.text.isEmpty
            ? null
            : _treatmentController.text.trim(),
        veterinarian:
            _vetController.text.isEmpty ? null : _vetController.text.trim(),
        notes: _notesController.text.isEmpty
            ? null
            : _notesController.text.trim(),
        weight: weight,
        cost: cost,
        followUpDate: _followUpDate,
      ));
    } else {
      notifier.createRecord(
        userId: userId,
        title: _titleController.text.trim(),
        type: _type,
        date: _date,
        birdId: _birdId,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text.trim(),
        treatment: _treatmentController.text.isEmpty
            ? null
            : _treatmentController.text.trim(),
        veterinarian:
            _vetController.text.isEmpty ? null : _vetController.text.trim(),
        notes: _notesController.text.isEmpty
            ? null
            : _notesController.text.trim(),
        weight: weight,
        cost: cost,
        followUpDate: _followUpDate,
      );
    }
  }
}
