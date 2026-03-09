import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_gender_icon.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_status_badge.dart';

/// Header section for bird detail screen showing avatar, name, ring and status.
class BirdDetailHeader extends StatelessWidget {
  final Bird bird;

  const BirdDetailHeader({super.key, required this.bird});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          Hero(
            tag: 'bird_${bird.id}',
            child: CircleAvatar(
              radius: 48,
              backgroundColor: birdGenderColor(bird.gender).withValues(alpha: 0.1),
              child: bird.photoUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: bird.photoUrl!,
                        width: 96,
                        height: 96,
                        memCacheWidth: 192,
                        memCacheHeight: 192,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            BirdGenderIcon(gender: bird.gender, size: 48),
                      ),
                    )
                  : BirdGenderIcon(gender: bird.gender, size: 48),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(bird.name, style: theme.textTheme.headlineSmall),
          if (bird.ringNumber != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${'birds.ring_number'.tr()}: ${bird.ringNumber}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          BirdStatusBadge(status: bird.status),
        ],
      ),
    );
  }

}
