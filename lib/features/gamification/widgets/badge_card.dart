import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/gamification_providers.dart';

class BadgeCard extends StatelessWidget {
  final EnrichedBadge enrichedBadge;
  final VoidCallback? onTap;

  const BadgeCard({super.key, required this.enrichedBadge, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = enrichedBadge.badge;
    final isUnlocked = enrichedBadge.isUnlocked;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? _tierColor(badge.tier, theme).withValues(alpha: 0.2)
                      : theme.colorScheme.surfaceContainerHighest,
                ),
                child: Icon(
                  isUnlocked ? LucideIcons.award : LucideIcons.lock,
                  size: 28,
                  color: isUnlocked
                      ? _tierColor(badge.tier, theme)
                      : theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                badge.nameKey.tr(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? null : theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              if (!isUnlocked) ...[
                LinearProgressIndicator(
                  value: enrichedBadge.progressPercent,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${enrichedBadge.progress}/${badge.requirement}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
              if (isUnlocked)
                Icon(
                  LucideIcons.checkCircle,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _tierColor(BadgeTier tier, ThemeData theme) => switch (tier) {
        BadgeTier.bronze => AppColors.tierBronze,
        BadgeTier.silver => AppColors.tierSilver,
        BadgeTier.gold => AppColors.tierGold,
        BadgeTier.platinum => AppColors.tierPlatinum,
        BadgeTier.unknown => theme.colorScheme.outline,
      };
}
