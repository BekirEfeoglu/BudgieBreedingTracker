import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';

/// A dropdown field for selecting a bird from a list.
class BirdSelectorField extends StatelessWidget {
  final String label;
  final List<Bird> birds;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final BirdGender? gender;

  const BirdSelectorField({
    super.key,
    required this.label,
    required this.birds,
    this.selectedId,
    required this.onChanged,
    this.gender,
  });

  @override
  Widget build(BuildContext context) {
    final validSelectedId =
        selectedId != null && birds.any((bird) => bird.id == selectedId)
        ? selectedId
        : null;

    return DropdownButtonFormField<String>(
      key: ValueKey(validSelectedId),
      initialValue: validSelectedId,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: AppIcon(
          gender == BirdGender.male ? AppIcons.male : AppIcons.female,
          color: gender == BirdGender.male
              ? AppColors.genderMale
              : AppColors.genderFemale,
        ),
      ),
      items: birds.map((bird) {
        return DropdownMenuItem<String>(
          value: bird.id,
          child: Row(
            children: [
              Flexible(child: Text(bird.name, overflow: TextOverflow.ellipsis)),
              if (bird.ringNumber != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '(${bird.ringNumber})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'validation.field_required'.tr(args: [label]);
        }
        return null;
      },
      isExpanded: true,
    );
  }
}
