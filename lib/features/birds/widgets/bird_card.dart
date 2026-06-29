import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/birds/utils/bird_display_utils.dart';
import 'package:budgie_breeding_tracker/shared/widgets/birds.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_status_badge.dart';
import 'package:budgie_breeding_tracker/shared/widgets/sync_conflict_badge.dart';

/// Card displaying a bird's summary in the list.
class BirdCard extends StatelessWidget {
  final Bird bird;
  final VoidCallback? onTap;

  const BirdCard({super.key, required this.bird, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final age = bird.age;

    final cardWidget = Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.push('/birds/${bird.id}'),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Hero(
                tag: 'bird_${bird.id}',
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: birdGenderColor(
                    bird.gender,
                  ).withValues(alpha: 0.1),
                  child: bird.photoUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: bird.photoUrl!,
                            width: 48,
                            height: 48,
                            memCacheWidth: 96,
                            memCacheHeight: 96,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                BirdGenderIcon(gender: bird.gender, size: 28),
                          ),
                        )
                      : BirdGenderIcon(gender: bird.gender, size: 28),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bird.name,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (bird.ringNumber != null) ...[
                          AppIcon(
                            AppIcons.ring,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              bird.ringNumber!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        if (age != null)
                          Flexible(
                            child: Text(
                              formatBirdAgeShort(age),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (bird.species != Species.budgie) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          speciesIconWidget(
                            bird.species,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            speciesLabel(bird.species),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RecordSyncConflictBadge(
                    tableName: SupabaseConstants.birdsTable,
                    recordId: bird.id,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  BirdStatusBadge(status: bird.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return CupertinoContextMenu(
      actions: [
        CupertinoContextMenuAction(
          onPressed: () {
            Navigator.pop(context);
            if (onTap != null) {
              onTap!();
            } else {
              context.push('/birds/${bird.id}');
            }
          },
          trailingIcon: CupertinoIcons.eye,
          child: Text('common.view'.tr()),
        ),
        CupertinoContextMenuAction(
          onPressed: () {
            Navigator.pop(context);
            context.push('/birds/${bird.id}/edit');
          },
          trailingIcon: CupertinoIcons.pencil,
          child: Text('common.edit'.tr()),
        ),
      ],
      child: cardWidget,
    );
  }
}
