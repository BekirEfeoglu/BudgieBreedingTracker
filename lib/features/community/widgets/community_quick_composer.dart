import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/enums/community_enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../profile/providers/profile_providers.dart';

/// Compact post creation bar with user avatar and quick actions.
class CommunityQuickComposer extends ConsumerWidget {
  final String currentUserId;
  final VoidCallback onCreatePost;
  final ValueChanged<CommunityPostType> onCreateTypedPost;

  const CommunityQuickComposer({
    super.key,
    required this.currentUserId,
    required this.onCreatePost,
    required this.onCreateTypedPost,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider).value;
    final avatarUrl = profile?.avatarUrl;
    final initial = _resolveInitial(profile?.fullName, currentUserId);

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      onTap: onCreatePost,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.24),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.12,
              ),
              foregroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      initial,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'community.quick_hint'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _CompactAction(
              icon: LucideIcons.image,
              tooltip: 'community.add_photo'.tr(),
              onTap: () => onCreateTypedPost(CommunityPostType.photo),
            ),
            _CompactAction(
              icon: LucideIcons.helpCircle,
              tooltip: 'community.post_type_question'.tr(),
              onTap: () => onCreateTypedPost(CommunityPostType.question),
            ),
            _CompactAction(
              icon: LucideIcons.bookOpen,
              tooltip: 'community.post_type_guide'.tr(),
              onTap: () => onCreateTypedPost(CommunityPostType.guide),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveInitial(String? fullName, String userId) {
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim().substring(0, 1).toUpperCase();
    }
    if (userId.isNotEmpty) {
      return userId.substring(0, 1).toUpperCase();
    }
    return '?';
  }
}

class _CompactAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CompactAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Icon(
                icon,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
