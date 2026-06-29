import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/birds/utils/bird_display_utils.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_gender_icon.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_status_badge.dart';
import 'package:budgie_breeding_tracker/shared/widgets/sync_conflict_badge.dart';

/// Photo-forward card used by the bird list grid view.
class BirdGridCard extends StatelessWidget {
  final Bird bird;
  final VoidCallback? onTap;

  const BirdGridCard({super.key, required this.bird, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final age = bird.age;

    final cardWidget = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.push('/birds/${bird.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'bird_${bird.id}',
                    child: _GridPhoto(bird: bird),
                  ),
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: BirdStatusBadge(status: bird.status),
                  ),
                  Positioned(
                    top: AppSpacing.xs,
                    left: AppSpacing.xs,
                    child: RecordSyncConflictBadge(
                      tableName: SupabaseConstants.birdsTable,
                      recordId: bird.id,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    bird.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (bird.ringNumber != null) ...[
                        AppIcon(
                          AppIcons.ring,
                          size: 14,
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
                      ] else if (age != null)
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
                ],
              ),
            ),
          ],
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

class _GridPhoto extends StatelessWidget {
  final Bird bird;

  const _GridPhoto({required this.bird});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photoUrl = bird.photoUrl;

    if (photoUrl != null) {
      return CachedNetworkImage(
        imageUrl: photoUrl,
        memCacheWidth: 360,
        memCacheHeight: 360,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _GridFallback(bird: bird),
      );
    }

    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      child: Center(child: BirdGenderIcon(gender: bird.gender, size: 44)),
    );
  }
}

class _GridFallback extends StatelessWidget {
  final Bird bird;

  const _GridFallback({required this.bird});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(child: BirdGenderIcon(gender: bird.gender, size: 44)),
    );
  }
}
