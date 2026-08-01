import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import '../../../data/models/profile_model.dart';
import '../../../domain/services/gamification/level_calculator.dart';
import '../../../shared/providers/gamification.dart' as gamification;
import '../../../shared/widgets/gamification.dart';
import '../providers/profile_providers.dart';
import 'avatar_widget.dart';

part 'profile_header_stats.dart';

/// Profile header with avatar, completion ring, name, email, badges, and stats.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.displayName,
    required this.email,
    required this.onEditProfile,
    required this.onEditAvatar,
    this.isAvatarUploading = false,
    this.stats,
    this.userLevel,
    this.unlockedBadges = const [],
    this.hasPremiumAccess,
  });

  final Profile? profile;
  final String displayName;
  final String email;
  final VoidCallback onEditProfile;
  final VoidCallback onEditAvatar;
  final bool isAvatarUploading;
  final ProfileStats? stats;
  final gamification.UserLevel? userLevel;
  final List<gamification.EnrichedBadge> unlockedBadges;
  final bool? hasPremiumAccess;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleUnlockedBadges = _profileHeaderBadges(unlockedBadges);
    final hiddenBadgeCount =
        unlockedBadges.length - visibleUnlockedBadges.length;
    final level = userLevel;
    final showPremium = hasPremiumAccess ?? profile?.hasPremium == true;
    final levelTitleKey = level == null
        ? null
        : level.title.isNotEmpty
        ? level.title
        : LevelCalculator.titleForLevel(level.level);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with edit overlay
            Stack(
              children: [
                AvatarWidget(
                  imageUrl: profile?.avatarUrl,
                  radius: 48,
                  isUploading: isAvatarUploading,
                  isPremium: showPremium,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    shape: const CircleBorder(),
                    elevation: 2,
                    color: theme.colorScheme.primary,
                    child: AppIconButton(
                      icon: const Icon(LucideIcons.camera),
                      onPressed: isAvatarUploading ? null : onEditAvatar,
                      semanticLabel: 'profile.edit_avatar'.tr(),
                      color: theme.colorScheme.onPrimary,
                      iconSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Display name
            Text(
              displayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),

            // Email
            Text(
              email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),

            // Badges
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                if (level != null && levelTitleKey != null)
                  _Badge(
                    icon: AnimatedRankIcon(
                      iconAsset: AppIcons.getLevelIcon(levelTitleKey),
                      size: 14,
                      isAnimated: false,
                    ),
                    label:
                        '${'community.level_prefix'.tr()}${level.level} - ${levelTitleKey.tr()}',
                    color: AppColors.accent,
                    foregroundColor: AppColors.neutral900,
                  ),
                if (showPremium)
                  _Badge(
                    icon: AppIcon(
                      AppIcons.premium,
                      size: 14,
                      color: theme.colorScheme.onPrimary,
                    ),
                    label: 'profile.premium_badge'.tr(),
                    color: AppColors.success,
                  ),
                if (profile?.isFounder == true)
                  _Badge(
                    icon: AppIcon(
                      AppIcons.security,
                      size: 14,
                      color: theme.colorScheme.onPrimary,
                    ),
                    label: 'profile.founder_badge'.tr(),
                    color: AppColors.primary,
                  )
                else if (profile?.isAdmin == true)
                  _Badge(
                    icon: AppIcon(
                      AppIcons.twoFactor,
                      size: 14,
                      color: theme.colorScheme.onPrimary,
                    ),
                    label: 'profile.admin_badge'.tr(),
                    color: AppColors.primary,
                  ),
                for (final enrichedBadge in visibleUnlockedBadges)
                  _Badge(
                    icon: AnimatedRankIcon(
                      iconAsset: AppIcons.getBadgeIcon(
                        enrichedBadge.badge.tier.name,
                      ),
                      size: 14,
                      isAnimated: false,
                    ),
                    label: enrichedBadge.badge.nameKey.tr(),
                    color: _badgeTierColor(enrichedBadge.badge.tier, theme),
                    foregroundColor: _badgeTierForegroundColor(
                      enrichedBadge.badge.tier,
                      theme,
                    ),
                  ),
                if (hiddenBadgeCount > 0)
                  _Badge(
                    icon: const AppIcon(AppIcons.rank, size: 14),
                    label: '+$hiddenBadgeCount',
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),

            // Stats row
            if (stats != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _ProfileStatsRow(stats: stats!),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Edit Profile button
            OutlinedButton.icon(
              onPressed: onEditProfile,
              icon: const AppIcon(AppIcons.edit, size: 16),
              label: Text('profile.edit_profile'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Badge --

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
    this.foregroundColor,
  });

  final Widget icon;
  final String label;
  final Color color;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveForeground = foregroundColor ?? theme.colorScheme.onPrimary;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(size: 14, color: effectiveForeground),
              child: icon,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: effectiveForeground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<gamification.EnrichedBadge> _profileHeaderBadges(
  List<gamification.EnrichedBadge> badges,
) {
  if (badges.isEmpty) return const [];

  for (final badge in badges) {
    if (badge.badge.key == 'verified_breeder') {
      return [badge];
    }
  }

  return [badges.first];
}

Color _badgeTierColor(gamification.BadgeTier tier, ThemeData theme) =>
    switch (tier) {
      gamification.BadgeTier.bronze => AppColors.tierBronze,
      gamification.BadgeTier.silver => AppColors.tierSilver,
      gamification.BadgeTier.gold => AppColors.tierGold,
      gamification.BadgeTier.platinum => AppColors.tierPlatinum,
      gamification.BadgeTier.unknown => theme.colorScheme.primary,
    };

Color _badgeTierForegroundColor(gamification.BadgeTier tier, ThemeData theme) =>
    switch (tier) {
      gamification.BadgeTier.silver ||
      gamification.BadgeTier.gold ||
      gamification.BadgeTier.platinum => AppColors.neutral900,
      gamification.BadgeTier.bronze ||
      gamification.BadgeTier.unknown => theme.colorScheme.onPrimary,
    };
