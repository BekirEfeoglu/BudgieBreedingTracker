import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/date_picker_field.dart';

/// Form fields for the chick form (name, gender, health, hatch date,
/// hatch weight, ring number, notes).
class ChickFormFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController ringController;
  final TextEditingController hatchWeightController;
  final TextEditingController notesController;
  final BirdGender gender;
  final ChickHealthStatus healthStatus;
  final DateTime? hatchDate;
  final DateFormat? dateFormatter;
  final ValueChanged<BirdGender> onGenderChanged;
  final ValueChanged<ChickHealthStatus> onHealthStatusChanged;
  final ValueChanged<DateTime?> onHatchDateChanged;

  const ChickFormFields({
    super.key,
    required this.nameController,
    required this.ringController,
    required this.hatchWeightController,
    required this.notesController,
    required this.gender,
    required this.healthStatus,
    required this.hatchDate,
    required this.dateFormatter,
    required this.onGenderChanged,
    required this.onHealthStatusChanged,
    required this.onHatchDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name (optional)
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'chicks.name_optional'.tr(),
            border: const OutlineInputBorder(),
            prefixIcon: const AppIcon(AppIcons.chick),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Gender
        _GenderSelector(gender: gender, onChanged: onGenderChanged),
        const SizedBox(height: AppSpacing.lg),

        // Health Status
        _HealthStatusSelector(
          healthStatus: healthStatus,
          onChanged: onHealthStatusChanged,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Hatch Date
        DatePickerField(
          label: 'chicks.hatch_date_required'.tr(),
          value: hatchDate,
          onChanged: onHatchDateChanged,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          dateFormatter: dateFormatter,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Hatch Weight
        TextFormField(
          controller: hatchWeightController,
          decoration: InputDecoration(
            labelText: 'chicks.birth_weight_label'.tr(),
            border: const OutlineInputBorder(),
            prefixIcon: const AppIcon(AppIcons.weight),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          controller: ringController,
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
          controller: notesController,
          decoration: InputDecoration(
            labelText: 'common.notes'.tr(),
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

/// Gender segmented button selector.
class _GenderSelector extends StatelessWidget {
  final BirdGender gender;
  final ValueChanged<BirdGender> onChanged;

  const _GenderSelector({required this.gender, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          selected: {gender},
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
      ],
    );
  }
}

/// Health status segmented button selector.
class _HealthStatusSelector extends StatelessWidget {
  final ChickHealthStatus healthStatus;
  final ValueChanged<ChickHealthStatus> onChanged;

  const _HealthStatusSelector({
    required this.healthStatus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              label: Text('chicks.unknown_status'.tr()),
              icon: const Icon(LucideIcons.helpCircle),
            ),
          ],
          selected: {healthStatus},
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
      ],
    );
  }
}
