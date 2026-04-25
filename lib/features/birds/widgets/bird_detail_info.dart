import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/cards/info_card.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/birds/utils/bird_color_utils.dart';
import 'package:budgie_breeding_tracker/features/birds/utils/bird_display_utils.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_form_helpers.dart';

/// Info section for bird detail screen showing gender, species, age, color, cage, dates.
class BirdDetailInfo extends StatelessWidget {
  final Bird bird;

  const BirdDetailInfo({super.key, required this.bird});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');
    final age = bird.age;

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text('common.info'.tr(), style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _DetailInfoTile(
                  icon: _genderWidget,
                  title: _genderLabel,
                  subtitle: 'birds.gender'.tr(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DetailInfoTile(
                  icon: speciesIconWidget(bird.species),
                  title: speciesLabel(bird.species),
                  subtitle: 'birds.species'.tr(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _DetailInfoTile(
                  icon: const Icon(LucideIcons.cake),
                  title: bird.birthDate != null
                      ? dateFormat.format(bird.birthDate!)
                      : 'birds.unknown'.tr(),
                  subtitle: 'birds.birth_date'.tr(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DetailInfoTile(
                  icon: const Icon(LucideIcons.timer),
                  title: age != null
                      ? formatBirdAge(age)
                      : 'birds.unknown'.tr(),
                  subtitle: 'birds.age'.tr(),
                ),
              ),
            ],
          ),
          if (bird.colorMutation != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailInfoTile(
              icon: const AppIcon(AppIcons.colorPalette),
              title: _colorLabel,
              subtitle: 'birds.color'.tr(),
            ),
          ],
          if (bird.cageNumber != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailInfoTile(
              icon: const AppIcon(AppIcons.nest),
              title: bird.cageNumber!,
              subtitle: 'birds.cage_number'.tr(),
            ),
          ],
          if (bird.status == BirdStatus.dead && bird.deathDate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailInfoTile(
              icon: const AppIcon(AppIcons.statusDead),
              title: dateFormat.format(bird.deathDate!),
              subtitle: 'birds.death_date'.tr(),
            ),
          ],
          if (bird.status == BirdStatus.sold && bird.soldDate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailInfoTile(
              icon: const AppIcon(AppIcons.statusSold),
              title: dateFormat.format(bird.soldDate!),
              subtitle: 'birds.sell_date'.tr(),
            ),
          ],
        ],
      ),
    );
  }

  Widget get _genderWidget => switch (bird.gender) {
    BirdGender.male => const AppIcon(AppIcons.male),
    BirdGender.female => const AppIcon(AppIcons.female),
    BirdGender.unknown => const Icon(LucideIcons.helpCircle),
  };

  String get _genderLabel => switch (bird.gender) {
    BirdGender.male => 'birds.male'.tr(),
    BirdGender.female => 'birds.female'.tr(),
    BirdGender.unknown => 'birds.unknown'.tr(),
  };

  String get _colorLabel {
    final color = bird.colorMutation;
    if (color == BirdColor.other) {
      final colorNote = extractColorNote(bird.notes);
      if (colorNote != null && colorNote.trim().isNotEmpty) {
        return colorNote.trim();
      }
    }
    return birdColorLabel(color!);
  }
}

class _DetailInfoTile extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;

  const _DetailInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InfoCard(
      icon: Container(
        width: AppSpacing.touchTargetMin,
        height: AppSpacing.touchTargetMin,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: icon,
      ),
      title: title,
      subtitle: subtitle,
    );
  }
}
