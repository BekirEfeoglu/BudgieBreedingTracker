import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/status_badge.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';

/// Card header showing male/female bird names, status badge, and cage number.
class BreedingCardHeader extends ConsumerWidget {
  final BreedingPair pair;

  const BreedingCardHeader({super.key, required this.pair});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final maleName = pair.maleId != null
        ? ref
              .watch(birdByIdProvider(pair.maleId!))
              .whenOrNull(data: (bird) => bird?.name)
        : null;

    final femaleName = pair.femaleId != null
        ? ref
              .watch(birdByIdProvider(pair.femaleId!))
              .whenOrNull(data: (bird) => bird?.name)
        : null;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppIcon(
                    AppIcons.male,
                    size: 16,
                    color: AppColors.genderMale,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      maleName ?? 'breeding.male_not_selected'.tr(),
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    '×',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const AppIcon(
                    AppIcons.female,
                    size: 16,
                    color: AppColors.genderFemale,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      femaleName ?? 'breeding.female_not_selected'.tr(),
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (pair.cageNumber != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${'breeding.cage_label'.tr()}: ${pair.cageNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        StatusBadge(
          label: _getStatusLabel(pair.status),
          color: _getStatusColor(pair.status),
          icon: pair.status == BreedingStatus.completed
              ? const AppIcon(AppIcons.breedingComplete)
              : null,
        ),
      ],
    );
  }

  static String _getStatusLabel(BreedingStatus status) {
    return switch (status) {
      BreedingStatus.active => 'breeding.active'.tr(),
      BreedingStatus.ongoing => 'breeding.in_progress'.tr(),
      BreedingStatus.completed => 'breeding.completed'.tr(),
      BreedingStatus.cancelled => 'breeding.cancelled'.tr(),
      BreedingStatus.unknown => 'common.unknown'.tr(),
    };
  }

  static Color _getStatusColor(BreedingStatus status) {
    return switch (status) {
      BreedingStatus.active => AppColors.primaryLight,
      BreedingStatus.ongoing => AppColors.warning,
      BreedingStatus.completed => AppColors.success,
      BreedingStatus.cancelled ||
      BreedingStatus.unknown => AppColors.neutral400,
    };
  }
}
