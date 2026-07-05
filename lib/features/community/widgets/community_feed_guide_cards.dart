part of 'community_feed_list.dart';

int _guideReadMinutes(CommunityPost post) {
  final totalWords = '${post.title ?? ''} ${post.content}'
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .length;
  return (totalWords / 180).ceil().clamp(1, 99);
}

/// "Lv.X · Title · date" (or just the date) for a guide author row.
String _guideAuthorMeta(CommunityPost post) {
  final date = formatCommunityDate(post.createdAt);
  final level = post.authorLevel;
  if (level == null) return date;
  // authorTitle is an l10n key (profiles.xp_title) — resolve it for display.
  final title = post.authorTitle;
  final levelPart = (title != null && title.isNotEmpty)
      ? '${'community.level_prefix'.tr()}$level · ${title.tr()}'
      : '${'community.level_prefix'.tr()}$level';
  return '$levelPart · $date';
}

/// Featured guide card (first item on the guides tab).
class _FeaturedGuideCard extends StatelessWidget {
  const _FeaturedGuideCard({required this.post});

  final CommunityPost post;

  void _open(BuildContext context) => context.push(
    AppRoutes.communityPostDetail.replaceFirst(':postId', post.id),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GuideCardHeader(
              post: post,
              badgeLabel: 'community.guides_featured'.tr(),
              minHeight: 150,
              titleStyle: theme.textTheme.headlineSmall,
              subtitle: post.content,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CommunityAvatar(
                        username: post.username,
                        avatarUrl: post.avatarUrl,
                        radius: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    post.username,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (post.authorIsVerified) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  Semantics(
                                    label: 'community.verified_breeder'.tr(),
                                    child: Icon(
                                      LucideIcons.badgeCheck,
                                      size: 15,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              _guideAuthorMeta(post),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _GuideOpenButton(onTap: () => _open(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact guide card used in the guides library list.
class _GuideLibraryCard extends StatelessWidget {
  const _GuideLibraryCard({required this.post, required this.highlightTone});

  final CommunityPost post;
  final bool highlightTone;

  void _open(BuildContext context) => context.push(
    AppRoutes.communityPostDetail.replaceFirst(':postId', post.id),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GuideCardHeader(
              post: post,
              badgeLabel: 'community.guide_badge'.tr(),
              minHeight: 116,
              ringColors: highlightTone
                  ? const [AppColors.primaryDark, AppColors.primaryLight]
                  : const [AppColors.info, AppColors.primaryLight],
              titleStyle: theme.textTheme.titleLarge,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CommunityAvatar(
                        username: post.username,
                        avatarUrl: post.avatarUrl,
                        radius: 16,
                        ring: false,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          post.username,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (post.authorIsVerified) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Semantics(
                          label: 'community.verified_breeder'.tr(),
                          child: Icon(
                            LucideIcons.badgeCheck,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _GuideOpenButton(onTap: () => _open(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Saturated brand-gradient header shared by both guide cards. Renders the
/// optional cover image under a legibility scrim, a faint bird watermark, the
/// amber badge + read-time chip, and the white title (plus optional subtitle).
class _GuideCardHeader extends StatelessWidget {
  const _GuideCardHeader({
    required this.post,
    required this.badgeLabel,
    required this.minHeight,
    this.subtitle,
    this.titleStyle,
    this.ringColors,
  });

  final CommunityPost post;
  final String badgeLabel;
  final double minHeight;
  final String? subtitle;
  final TextStyle? titleStyle;

  /// Gradient colors for the header background (defaults to the primary ramp).
  final List<Color>? ringColors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage =
        post.primaryImageUrl != null && post.primaryImageUrl!.isNotEmpty;
    final headerColors =
        ringColors ??
        const [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight];

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: headerColors,
        ),
      ),
      child: Stack(
        children: [
          if (hasImage) ...[
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: post.primaryImageUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 900,
                maxWidthDiskCache: 900,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryDark.withValues(alpha: 0.55),
                      AppColors.primaryDark.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
            ),
          ],
          Positioned(
            right: -24,
            top: -20,
            child: AppIcon(
              AppIcons.bird,
              size: 150,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _GuideBadge(label: badgeLabel),
                    const Spacer(),
                    _GuideGlassChip(
                      icon: LucideIcons.clock,
                      label: 'community.guide_read_time'.tr(
                        args: ['${_guideReadMinutes(post)}'],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  post.title ?? 'community.tab_guides'.tr(),
                  style: (titleStyle ?? theme.textTheme.titleLarge)?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

/// Amber pill badge ("Rehber" / "Öne çıkan rehber") on the guide header.
class _GuideBadge extends StatelessWidget {
  const _GuideBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accentLight, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon(
            AppIcons.guide,
            size: 12,
            color: AppColors.premiumBadgeText,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.premiumBadgeText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Translucent white chip (read-time) on the guide header.
class _GuideGlassChip extends StatelessWidget {
  const _GuideGlassChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Outline "Detaylı rehber olarak aç" button below the guide header.
class _GuideOpenButton extends StatelessWidget {
  const _GuideOpenButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.06),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.55),
            width: 1.5,
          ),
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'community.guide_open_hint'.tr(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(LucideIcons.arrowRight, size: 18),
          ],
        ),
      ),
    );
  }
}
