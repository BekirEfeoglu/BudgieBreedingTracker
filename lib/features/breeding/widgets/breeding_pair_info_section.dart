import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_gender_icon.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';

class BreedingPairInfoSection extends ConsumerWidget {
  final BreedingPair pair;

  const BreedingPairInfoSection({super.key, required this.pair});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final maleBird = pair.maleId != null
        ? ref
              .watch(birdByIdProvider(pair.maleId!))
              .whenOrNull(data: (bird) => bird)
        : null;

    final femaleBird = pair.femaleId != null
        ? ref
              .watch(birdByIdProvider(pair.femaleId!))
              .whenOrNull(data: (bird) => bird)
        : null;

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('breeding.pair_info'.tr(), style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: BirdPairCard(
                  bird: maleBird,
                  gender: BirdGender.male,
                  label: 'breeding.male'.tr(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: BirdPairCard(
                  bird: femaleBird,
                  gender: BirdGender.female,
                  label: 'breeding.female'.tr(),
                ),
              ),
            ],
          ),
          if (pair.cageNumber != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                AppIcon(
                  AppIcons.nest,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${'breeding.cage_number'.tr()}: ${pair.cageNumber!}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class BirdPairCard extends StatelessWidget {
  final Bird? bird;
  final BirdGender gender;
  final String label;

  const BirdPairCard({
    super.key,
    required this.bird,
    required this.gender,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final genderColor = birdGenderColor(gender);
    final name = bird?.name ?? 'common.loading'.tr();

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: genderColor.withValues(alpha: 0.1),
              child: bird?.photoUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: bird!.photoUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        memCacheWidth: 80,
                        memCacheHeight: 80,
                        placeholder: (_, __) => AppIcon(
                          gender == BirdGender.male
                              ? AppIcons.male
                              : AppIcons.female,
                          size: 20,
                          color: genderColor,
                        ),
                        errorWidget: (_, __, ___) => AppIcon(
                          gender == BirdGender.male
                              ? AppIcons.male
                              : AppIcons.female,
                          size: 20,
                          color: genderColor,
                        ),
                      ),
                    )
                  : AppIcon(
                      gender == BirdGender.male
                          ? AppIcons.male
                          : AppIcons.female,
                      size: 20,
                      color: genderColor,
                    ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(label, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
