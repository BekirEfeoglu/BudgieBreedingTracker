import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/date_picker_field.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/features/health_records/widgets/health_record_animal_selector.dart';
import 'package:budgie_breeding_tracker/shared/widgets/health_records.dart';

/// Form fields for the health record form (title, type, date, animal,
/// description, treatment, vet, weight/cost, follow-up, notes).
class HealthRecordFormFields extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController treatmentController;
  final TextEditingController vetController;
  final TextEditingController notesController;
  final TextEditingController weightController;
  final TextEditingController costController;
  final HealthRecordType type;
  final DateTime date;
  final DateTime? followUpDate;
  final String? birdId;
  final List<Bird> birds;
  final List<Chick> chicks;
  final bool isAnimalsLoading;
  final DateFormat? dateFormatter;
  final ValueChanged<HealthRecordType> onTypeChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<DateTime?> onFollowUpDateChanged;
  final ValueChanged<String?> onBirdChanged;

  const HealthRecordFormFields({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.treatmentController,
    required this.vetController,
    required this.notesController,
    required this.weightController,
    required this.costController,
    required this.type,
    required this.date,
    required this.followUpDate,
    required this.birdId,
    required this.birds,
    required this.chicks,
    required this.isAnimalsLoading,
    required this.dateFormatter,
    required this.onTypeChanged,
    required this.onDateChanged,
    required this.onFollowUpDateChanged,
    required this.onBirdChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        TextFormField(
          controller: titleController,
          maxLength: 200,
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
        _TypeSelector(type: type, onTypeChanged: onTypeChanged),
        const SizedBox(height: AppSpacing.lg),

        // Date
        DatePickerField(
          label: 'common.date'.tr(),
          value: date,
          onChanged: onDateChanged,
          firstDate: DateTime(2015),
          lastDate: DateTime.now(),
          dateFormatter: dateFormatter,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Bird / Chick selector
        HealthRecordAnimalSelector(
          selectedId: birdId,
          birds: birds,
          chicks: chicks,
          isLoading: isAnimalsLoading,
          onChanged: onBirdChanged,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Description
        TextFormField(
          controller: descriptionController,
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
          controller: treatmentController,
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
          controller: vetController,
          decoration: InputDecoration(
            labelText: 'health_records.veterinarian'.tr(),
            border: const OutlineInputBorder(),
            prefixIcon: const AppIcon(AppIcons.profile),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Weight and Cost row
        _WeightCostRow(
          weightController: weightController,
          costController: costController,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Follow-up date
        DatePickerField(
          label: 'health_records.follow_up'.tr(),
          value: followUpDate,
          onChanged: onFollowUpDateChanged,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          isRequired: false,
          dateFormatter: dateFormatter,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Notes
        TextFormField(
          controller: notesController,
          decoration: InputDecoration(
            labelText: 'common.notes_optional'.tr(),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(LucideIcons.stickyNote),
          ),
          maxLines: 3,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

/// Record type chip selector.
class _TypeSelector extends StatelessWidget {
  final HealthRecordType type;
  final ValueChanged<HealthRecordType> onTypeChanged;

  const _TypeSelector({required this.type, required this.onTypeChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('common.type'.tr(), style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: HealthRecordType.values
              .where((t) => t != HealthRecordType.unknown)
              .map((t) {
                final isSelected = type == t;
                return ChoiceChip(
                  avatar: Icon(
                    healthRecordTypeIcon(t),
                    size: 18,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : healthRecordTypeColor(t),
                  ),
                  label: Text(healthRecordTypeLabel(t)),
                  selected: isSelected,
                  onSelected: (_) => onTypeChanged(t),
                );
              })
              .toList(),
        ),
      ],
    );
  }
}

/// Weight and cost input fields side by side.
class _WeightCostRow extends StatelessWidget {
  final TextEditingController weightController;
  final TextEditingController costController;

  const _WeightCostRow({
    required this.weightController,
    required this.costController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: weightController,
            decoration: InputDecoration(
              labelText: 'health_records.weight'.tr(),
              border: const OutlineInputBorder(),
              suffixText: 'g',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final parsed = double.tryParse(value.trim());
                if (parsed == null) {
                  return 'chicks.invalid_number'.tr();
                }
                if (parsed <= 0) {
                  return 'validation.weight_positive'.tr();
                }
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: TextFormField(
            controller: costController,
            decoration: InputDecoration(
              labelText: 'health_records.cost'.tr(),
              border: const OutlineInputBorder(),
              suffixText: 'settings.currency_symbol'.tr(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
    );
  }
}
