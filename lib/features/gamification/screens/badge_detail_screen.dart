import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../../../data/models/badge_model.dart' as badge_model;
import '../../breeding/providers/breeding_providers.dart';
import '../providers/gamification_providers.dart';

class BadgeDetailScreen extends ConsumerWidget {
  final String badgeId;

  const BadgeDetailScreen({super.key, required this.badgeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final badgesAsync = ref.watch(badgesProvider);
    final userBadgesAsync = ref.watch(userBadgesProvider(userId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('badges.detail'.tr()),
      ),
      body: badgesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => app.ErrorState(
          message: '${'common.data_load_error'.tr()}: $error',
        ),
        data: (badges) {
          final badge = badges.where((b) => b.id == badgeId).firstOrNull;
          if (badge == null) {
            return app.ErrorState(message: 'error.not_found'.tr());
          }

          return userBadgesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildDetail(context, theme, badge, null),
            data: (userBadges) {
              final userBadge =
                  userBadges.where((ub) => ub.badgeId == badgeId).firstOrNull;
              return _buildDetail(context, theme, badge, userBadge);
            },
          );
        },
      ),
    );
  }

  Widget _buildDetail(
    BuildContext context,
    ThemeData theme,
    badge_model.Badge badge,
    UserBadge? userBadge,
  ) {
    final isUnlocked = userBadge?.isUnlocked ?? false;
    final progress = userBadge?.progress ?? 0;
    final progressPercent = userBadge?.progressPercent(badge.requirement) ?? 0;

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          // Badge icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? _tierColor(badge.tier, theme)
                  : theme.colorScheme.surfaceContainerHighest,
            ),
            child: Icon(
              isUnlocked ? LucideIcons.award : LucideIcons.lock,
              size: 56,
              color: isUnlocked
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Badge name
          Text(
            badge.nameKey.tr(),
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Tier chip
          Chip(
            label: Text(_tierLabel(badge.tier)),
            backgroundColor:
                _tierColor(badge.tier, theme).withValues(alpha: 0.2),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Description
          Text(
            badge.descriptionKey.tr(),
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          // Progress (locked badges only)
          if (!isUnlocked) ...[
            LinearProgressIndicator(
              value: progressPercent,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$progress / ${badge.requirement}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
          // Unlocked date (unlocked badges only)
          if (isUnlocked && userBadge?.unlockedAt != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.check,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'badges.unlocked_at'.tr(args: [
                    '${userBadge!.unlockedAt!.day}/${userBadge.unlockedAt!.month}/${userBadge.unlockedAt!.year}',
                  ]),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          // XP Reward
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.zap, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${badge.xpReward} XP',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _tierColor(BadgeTier tier, ThemeData theme) => switch (tier) {
        BadgeTier.bronze => const Color(0xFFCD7F32),
        BadgeTier.silver => const Color(0xFFC0C0C0),
        BadgeTier.gold => const Color(0xFFFFD700),
        BadgeTier.platinum => const Color(0xFFE5E4E2),
        BadgeTier.unknown => theme.colorScheme.outline,
      };

  String _tierLabel(BadgeTier tier) => switch (tier) {
        BadgeTier.bronze => 'badges.tier_bronze'.tr(),
        BadgeTier.silver => 'badges.tier_silver'.tr(),
        BadgeTier.gold => 'badges.tier_gold'.tr(),
        BadgeTier.platinum => 'badges.tier_platinum'.tr(),
        BadgeTier.unknown => '',
      };
}
