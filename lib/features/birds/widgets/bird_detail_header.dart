import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/shared/widgets/birds.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_status_badge.dart';

/// Header section for bird detail screen showing avatar, name, ring and status.
class BirdDetailHeader extends StatelessWidget {
  final Bird bird;

  const BirdDetailHeader({super.key, required this.bird});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Hero(
            tag: 'bird_${bird.id}',
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: birdGenderColor(bird.gender).withValues(alpha: 0.16),
                  width: 1,
                ),
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: birdGenderColor(
                  bird.gender,
                ).withValues(alpha: 0.1),
                child: bird.photoUrl != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: bird.photoUrl!,
                          width: 96,
                          height: 96,
                          memCacheWidth: 224,
                          memCacheHeight: 224,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              BirdGenderIcon(gender: bird.gender, size: 46),
                        ),
                      )
                    : BirdGenderIcon(gender: bird.gender, size: 46),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bird.name,
                  style: theme.textTheme.headlineSmall?.copyWith(height: 1.1),
                  overflow: TextOverflow.ellipsis,
                ),
                if (bird.ringNumber != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${'birds.ring_number'.tr()}: ${bird.ringNumber}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                BirdStatusBadge(status: bird.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
