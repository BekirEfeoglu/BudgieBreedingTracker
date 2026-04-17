import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/user_level_model.dart';

class LeaderboardTile extends StatelessWidget {
  final int rank;
  final UserLevel userLevel;

  const LeaderboardTile({
    super.key,
    required this.rank,
    required this.userLevel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTopThree = rank <= 3;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isTopThree
              ? _rankColor(rank).withValues(alpha: 0.2)
              : theme.colorScheme.surfaceContainerHighest,
        ),
        child: Center(
          child: isTopThree
              ? Icon(LucideIcons.trophy, size: 20, color: _rankColor(rank))
              : Text(
                  '$rank',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
      title: Text(
        userLevel.userId.substring(0, 8),
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Text(
        userLevel.title.isNotEmpty ? userLevel.title : 'Lv.${userLevel.level}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.zap, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${userLevel.totalXp}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Color _rankColor(int rank) => switch (rank) {
        1 => AppColors.tierGold,
        2 => AppColors.tierSilver,
        3 => AppColors.tierBronze,
        _ => AppColors.tierDefault,
      };
}
