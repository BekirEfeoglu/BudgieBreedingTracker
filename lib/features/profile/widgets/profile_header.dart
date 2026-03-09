import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/models/profile_model.dart';
import '../providers/profile_providers.dart';
import 'avatar_widget.dart';
import 'profile_completion_indicator.dart';

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
    this.completion,
  });

  final Profile? profile;
  final String displayName;
  final String email;
  final VoidCallback onEditProfile;
  final VoidCallback onEditAvatar;
  final bool isAvatarUploading;
  final ProfileStats? stats;
  final ProfileCompletion? completion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            // Avatar with completion ring and edit overlay
            Stack(
              children: [
                ProfileCompletionIndicator(
                  completionFraction: completion?.percentage ?? 0,
                  child: AvatarWidget(
                    imageUrl: profile?.avatarUrl,
                    radius: 48,
                    isUploading: isAvatarUploading,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    shape: const CircleBorder(),
                    elevation: 2,
                    color: theme.colorScheme.primary,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: isAvatarUploading ? null : onEditAvatar,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Icon(
                          LucideIcons.camera,
                          size: 16,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
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
            ),
            const SizedBox(height: AppSpacing.xs),

            // Email
            Text(
              email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Badges
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                if (profile?.hasPremium == true)
                  _Badge(
                    icon: AppIcon(AppIcons.premium,
                        size: 14, color: theme.colorScheme.onPrimary),
                    label: 'profile.premium_badge'.tr(),
                    color: AppColors.success,
                  ),
                if (profile?.isFounder == true)
                  _Badge(
                    icon: AppIcon(AppIcons.security,
                        size: 14, color: theme.colorScheme.onPrimary),
                    label: 'profile.founder_badge'.tr(),
                    color: AppColors.primary,
                  )
                else if (profile?.isAdmin == true)
                  _Badge(
                    icon: AppIcon(AppIcons.twoFactor,
                        size: 14, color: theme.colorScheme.onPrimary),
                    label: 'profile.admin_badge'.tr(),
                    color: AppColors.primary,
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
  });

  final Widget icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          icon,
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

// -- Stats Row --

class _ProfileStatsRow extends StatelessWidget {
  const _ProfileStatsRow({required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _AnimatedStatItem(
          count: stats.totalBirds,
          label: 'profile.total_birds_stat'.tr(),
          color: theme.colorScheme.primary,
        ),
        _AnimatedStatItem(
          count: stats.totalPairs,
          label: 'profile.total_pairs_stat'.tr(),
          color: AppColors.success,
        ),
        _AnimatedStatItem(
          count: stats.totalEggs,
          label: 'profile.total_eggs_stat'.tr(),
          color: AppColors.info,
        ),
        _AnimatedStatItem(
          count: stats.totalChicks,
          label: 'profile.total_chicks_stat'.tr(),
          color: AppColors.warning,
        ),
      ],
    );
  }
}

class _AnimatedStatItem extends StatelessWidget {
  const _AnimatedStatItem({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$label: $count',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: count),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (_, value, __) => Text(
              value.toString(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
