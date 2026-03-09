import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

/// Extracts initials from a display name (first+last or single letter).
String getProfileInitials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2 &&
      parts.first.isNotEmpty &&
      parts.last.isNotEmpty) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : '?';
}

/// Header section of the profile menu dialog showing avatar, name, email, and badges.
class ProfileMenuHeader extends StatelessWidget {
  const ProfileMenuHeader({
    super.key,
    required this.profile,
    required this.displayName,
    required this.displayEmail,
    required this.hasBadges,
    required this.isPremium,
    required this.isFounder,
  });

  final Profile? profile;
  final String displayName;
  final String displayEmail;
  final bool hasBadges;
  final bool isPremium;
  final bool isFounder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surfaceContainerHighest
          .withValues(alpha: 0.35),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          // Avatar with ring
          CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primary,
              backgroundImage: profile?.avatarUrl != null
                  ? CachedNetworkImageProvider(profile!.avatarUrl!,
                      maxWidth: 96, maxHeight: 96)
                  : null,
              child: profile?.avatarUrl == null
                  ? Text(
                      getProfileInitials(displayName),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  displayEmail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (hasBadges) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (isPremium)
                        ProfileMenuBadge(
                          label: 'profile.premium_badge'.tr(),
                          color: AppColors.success,
                        ),
                      if (isFounder)
                        ProfileMenuBadge(
                          label: 'profile.founder_badge'.tr(),
                          color: AppColors.primary,
                        )
                      else if (profile?.isAdmin == true)
                        ProfileMenuBadge(
                          label: 'profile.admin_badge'.tr(),
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small colored badge chip (e.g. Premium, Founder, Admin).
class ProfileMenuBadge extends StatelessWidget {
  const ProfileMenuBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}
