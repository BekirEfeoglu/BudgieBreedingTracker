part of 'community_story_strip.dart';

class _CreateStoryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateStoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        onTap: () {
          AppHaptics.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme.colorScheme.primary, AppColors.accent],
                  ),
                ),
                child: Icon(
                  LucideIcons.plus,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'community.create_post'.tr(),
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final StoryPreview story;

  const _StoryAvatar({required this.story});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVeryRecent = story.isVeryRecent;
    final borderColors = story.hasFreshPhoto
        ? [theme.colorScheme.primary, AppColors.accent]
        : [theme.colorScheme.outlineVariant, theme.colorScheme.outlineVariant];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        onTap: () {
          AppHaptics.selectionClick();
          context.push(
            AppRoutes.communityUserPosts.replaceFirst(':userId', story.userId),
          );
        },
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: EdgeInsets.all(isVeryRecent ? 3.5 : 3.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: borderColors,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.surface,
                      foregroundImage: story.avatarUrl != null
                          ? CachedNetworkImageProvider(
                              story.avatarUrl!,
                              maxWidth: 72,
                              maxHeight: 72,
                            )
                          : null,
                      child: story.avatarUrl == null
                          ? Text(
                              story.username.isNotEmpty
                                  ? story.username[0].toUpperCase()
                                  : '?',
                              style: theme.textTheme.titleMedium,
                            )
                          : null,
                    ),
                  ),
                  // Post count badge (top-right)
                  if (story.postCount > 1)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '${story.postCount}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onError,
                          ),
                        ),
                      ),
                    ),
                  // Time badge
                  Positioned(
                    bottom: -2,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isVeryRecent
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _formatStoryTime(story.lastPostAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isVeryRecent
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                story.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: isVeryRecent ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatStoryTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 5) return formatCommunityDate(date);
    if (diff.inMinutes < 60) {
      return 'community.minutes_ago_short'.tr(
        args: [diff.inMinutes.toString()],
      );
    }
    return 'community.hours_ago_short'.tr(
      args: [diff.inHours.toString()],
    );
  }
}
