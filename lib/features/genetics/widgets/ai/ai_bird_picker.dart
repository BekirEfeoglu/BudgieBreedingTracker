import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';

class AiBirdPicker extends StatelessWidget {
  const AiBirdPicker({
    super.key,
    required this.selectedFather,
    required this.selectedMother,
    required this.onSelectFather,
    required this.onSelectMother,
    required this.onClearFather,
    required this.onClearMother,
  });

  final Bird? selectedFather;
  final Bird? selectedMother;
  final VoidCallback onSelectFather;
  final VoidCallback onSelectMother;
  final VoidCallback onClearFather;
  final VoidCallback onClearMother;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _BirdSlot(
            bird: selectedFather,
            gender: BirdGender.male,
            placeholder: 'genetics.ai_select_father'.tr(),
            onTap: onSelectFather,
            onClear: onClearFather,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            '\u00D7',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: _BirdSlot(
            bird: selectedMother,
            gender: BirdGender.female,
            placeholder: 'genetics.ai_select_mother'.tr(),
            onTap: onSelectMother,
            onClear: onClearMother,
          ),
        ),
      ],
    );
  }
}

class _BirdSlot extends StatelessWidget {
  const _BirdSlot({
    required this.bird,
    required this.gender,
    required this.placeholder,
    required this.onTap,
    required this.onClear,
  });

  final Bird? bird;
  final BirdGender gender;
  final String placeholder;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final genderColor = gender == BirdGender.male
        ? AppColors.genderMale
        : AppColors.genderFemale;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: bird != null
                ? genderColor.withValues(alpha: 0.4)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: genderColor.withValues(alpha: 0.12),
              child: AppIcon(
                gender == BirdGender.male ? AppIcons.male : AppIcons.female,
                size: 18,
                color: genderColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: bird != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          bird!.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (bird!.ringNumber != null)
                          Text(
                            bird!.ringNumber!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    )
                  : Text(
                      placeholder,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            if (bird != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  LucideIcons.x,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
