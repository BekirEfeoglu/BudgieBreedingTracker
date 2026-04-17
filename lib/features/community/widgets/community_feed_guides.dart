part of 'community_feed_list.dart';

/// Builds the guides library view with featured card and library list.
Widget _buildGuidesLibraryView({
  required BuildContext context,
  required WidgetRef ref,
  required FeedState feedState,
  required List<CommunityPost> visiblePosts,
  required ScrollController scrollController,
  required bool isFounder,
}) {
  if (!feedState.isLoading && visiblePosts.isEmpty) {
    return RefreshIndicator(
      onRefresh: () => ref.read(communityFeedProvider.notifier).refresh(),
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxxl * 2,
        ),
        children: [
          const _GuidesIntroHero(),
          const SizedBox(height: AppSpacing.lg),
          FilteredFeedEmptyState(
            tab: CommunityFeedTab.guides,
            onReset: isFounder
                ? () => context.push(
                      '${AppRoutes.communityCreatePost}?type=guide',
                    )
                : null,
          ),
        ],
      ),
    );
  }

  final featuredGuide = visiblePosts.isNotEmpty ? visiblePosts.first : null;
  final libraryGuides = visiblePosts.skip(1).toList();

  return RefreshIndicator(
    onRefresh: () => ref.read(communityFeedProvider.notifier).refresh(),
    child: CustomScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: _GuidesIntroHero(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: _GuidesLibraryHeader(count: visiblePosts.length),
          ),
        ),
        if (featuredGuide != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: _FeaturedGuideCard(post: featuredGuide),
            ),
          ),
        if (libraryGuides.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xxxl * 3,
            ),
            sliver: SliverList.separated(
              itemCount: libraryGuides.length,
              itemBuilder: (context, index) {
                final post = libraryGuides[index];
                return _GuideLibraryCard(
                  post: post,
                  highlightTone: index.isEven,
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            ),
          ),
      ],
    ),
  );
}

class _GuidesIntroHero extends StatelessWidget {
  const _GuidesIntroHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.16),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'community.tab_guides'.tr().toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'community.guides_library_title'.tr(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'community.guides_library_hint'.tr(),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidesLibraryHeader extends StatelessWidget {
  const _GuidesLibraryHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'community.guides_curated_title'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'community.guides_curated_hint'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            'community.filter_results'.tr(args: ['$count']),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturedGuideCard extends StatelessWidget {
  const _FeaturedGuideCard({required this.post});

  final CommunityPost post;

  int get _readMinutes {
    final totalWords = '${post.title ?? ''} ${post.content}'
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .length;
    return (totalWords / 180).ceil().clamp(1, 99);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.communityPostDetail.replaceFirst(':postId', post.id),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 156,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.22),
                    theme.colorScheme.surfaceContainerHighest,
                  ],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (post.primaryImageUrl != null)
                    CachedNetworkImage(
                      imageUrl: post.primaryImageUrl!,
                      fit: BoxFit.cover,
                      // Featured guide card is ~double-feed-card height;
                      // cap both memory and disk cache to sane bounds.
                      memCacheWidth: 900,
                      maxWidthDiskCache: 900,
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.14),
                          Colors.black.withValues(alpha: 0.10),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        _GuideTopChip(label: 'community.guides_featured'.tr()),
                        const Spacer(),
                        _GuideTopChip(
                          label: 'community.guide_read_time'.tr(
                            args: ['$_readMinutes'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title ?? 'community.tab_guides'.tr(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    post.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: post.avatarUrl != null
                            ? CachedNetworkImageProvider(post.avatarUrl!)
                            : null,
                        child: post.avatarUrl == null
                            ? Text(
                                post.username.isNotEmpty
                                    ? post.username[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.username,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              formatCommunityDate(post.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push(
                          AppRoutes.communityPostDetail.replaceFirst(
                            ':postId',
                            post.id,
                          ),
                        ),
                        icon: const Icon(LucideIcons.bookOpen, size: 18),
                        label: Text('community.guide_open_hint'.tr()),
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
  }
}

class _GuideTopChip extends StatelessWidget {
  const _GuideTopChip({required this.label});

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
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GuideLibraryCard extends StatelessWidget {
  const _GuideLibraryCard({required this.post, required this.highlightTone});

  final CommunityPost post;
  final bool highlightTone;

  int get _readMinutes {
    final totalWords = '${post.title ?? ''} ${post.content}'
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .length;
    return (totalWords / 180).ceil().clamp(1, 99);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = highlightTone
        ? theme.colorScheme.primary
        : theme.colorScheme.tertiary;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      onTap: () => context.push(
        AppRoutes.communityPostDetail.replaceFirst(':postId', post.id),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Icon(LucideIcons.bookOpen, color: accent),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.username,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${formatCommunityDate(post.createdAt)} • ${'community.guide_read_time'.tr(args: ['$_readMinutes'])}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              post.title ?? 'community.tab_guides'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              post.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final tag in post.tags.take(3))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      ),
                      child: Text(
                        tag.startsWith('#') ? tag : '#$tag',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  'community.guide_open_hint'.tr(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(LucideIcons.arrowUpRight, size: 18, color: accent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
