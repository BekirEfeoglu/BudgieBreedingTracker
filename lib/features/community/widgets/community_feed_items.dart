part of 'community_feed_list.dart';

/// Builds the main scrollable feed content for [_CommunityFeedListState].
///
/// Called from the main file's build method after handling the following tab.
Widget _buildFeedScrollView({
  required BuildContext context,
  required WidgetRef ref,
  required CommunityFeedTab tab,
  required ScrollController scrollController,
  required bool mounted,
  required int newPostCount,
  required int lastSeenCount,
  required bool showSwipeHint,
  required bool showScrollToTop,
  required void Function(int) onUpdateNewPostCount,
  required void Function(int) onUpdateLastSeenCount,
  required VoidCallback onScrollToTop,
  required VoidCallback onDismissSwipeHint,
  required void Function(CommunityExploreSort) onChangeSort,
}) {
  final feedState = ref.watch(communityFeedProvider);
  final posts = feedState.posts;
  final currentUserId = ref.watch(currentUserIdProvider);
  final visiblePosts = ref.watch(communityVisiblePostsProvider(tab));
  final isExplore = tab == CommunityFeedTab.explore;
  final showExploreExtras = isExplore && visiblePosts.isNotEmpty;
  final exploreSort = ref.watch(exploreSortProvider);
  final isGuides = tab == CommunityFeedTab.guides;
  final defaultCreateType = tab == CommunityFeedTab.guides
      ? CommunityPostType.guide
      : CommunityPostType.general;

  if (feedState.error != null && posts.isEmpty) {
    return Center(
      child: app.ErrorState(
        message: '${'community.feed_load_error'.tr()}: ${feedState.error}',
        onRetry: () => ref.read(communityFeedProvider.notifier).refresh(),
      ),
    );
  }

  if (feedState.isLoading && posts.isEmpty) {
    return isGuides
        ? const GuidesLibrarySkeleton()
        : const CommunityFeedSkeleton();
  }

  if (isGuides) {
    return _buildGuidesLibraryView(
      context: context,
      ref: ref,
      feedState: feedState,
      visiblePosts: visiblePosts,
      scrollController: scrollController,
    );
  }

  return Stack(
    children: [
      RefreshIndicator(
        onRefresh: () async {
          await ref.read(communityFeedProvider.notifier).refresh();
          if (!mounted) return;
          onUpdateNewPostCount(0);
          onUpdateLastSeenCount(ref.read(communityFeedProvider).posts.length);
        },
        child: CustomScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Quick Composer
            if (!isGuides)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: CommunityQuickComposer(
                    currentUserId: currentUserId,
                    onCreatePost: () =>
                        context.push(_buildCreatePostRoute(defaultCreateType)),
                    onCreateTypedPost: (type) =>
                        context.push(_buildCreatePostRoute(type)),
                  ),
                ),
              ),
            // 2. Story Strip (explore only)
            if (isExplore && showExploreExtras)
              SliverToBoxAdapter(
                child: CommunityStoryStrip(
                  stories: CommunityStoryStrip.fromPosts(visiblePosts),
                  onCreatePost: () =>
                      context.push(_buildCreatePostRoute(defaultCreateType)),
                ),
              ),
            // 3. Section Bar
            if (visiblePosts.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: CommunitySectionBar(
                    tab: tab,
                    visibleCount: visiblePosts.length,
                    exploreSort: exploreSort,
                    onExploreSortChanged: onChangeSort,
                  ),
                ),
              ),
            // 4. Empty states or post list
            ..._buildFeedBody(
              context: context,
              ref: ref,
              tab: tab,
              feedState: feedState,
              posts: posts,
              visiblePosts: visiblePosts,
            ),
          ],
        ),
      ),
      // "New posts" floating banner with slide-in animation
      _NewPostsBannerOverlay(newPostCount: newPostCount, onTap: onScrollToTop),
      // Swipe onboarding hint
      if (showSwipeHint) _SwipeHintOverlay(onDismiss: onDismissSwipeHint),
      // Scroll-to-top mini FAB (bottom-left to avoid conflict with create-post FAB)
      Positioned(
        left: AppSpacing.md,
        bottom: AppSpacing.md,
        child: AnimatedScale(
          scale: showScrollToTop ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: FloatingActionButton.small(
            heroTag: 'scrollToTop',
            onPressed: () {
              HapticFeedback.lightImpact();
              scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
              );
            },
            child: const Icon(LucideIcons.arrowUp, size: 18),
          ),
        ),
      ),
    ],
  );
}

Widget _buildGuidesLibraryView({
  required BuildContext context,
  required WidgetRef ref,
  required FeedState feedState,
  required List<CommunityPost> visiblePosts,
  required ScrollController scrollController,
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
          const FilteredFeedEmptyState(tab: CommunityFeedTab.guides, onReset: null),
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

/// Builds either empty states or the post list slivers.
List<Widget> _buildFeedBody({
  required BuildContext context,
  required WidgetRef ref,
  required CommunityFeedTab tab,
  required FeedState feedState,
  required List<CommunityPost> posts,
  required List<CommunityPost> visiblePosts,
}) {
  if (!feedState.isLoading && posts.isEmpty) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxxl * 2,
          ),
          child: EmptyState(
            icon: const AppIcon(AppIcons.community),
            title: 'community.no_posts'.tr(),
            subtitle: 'community.no_posts_hint'.tr(),
            actionLabel: 'community.create_post'.tr(),
            onAction: () => context.push(AppRoutes.communityCreatePost),
          ),
        ),
      ),
    ];
  }

  if (!feedState.isLoading && visiblePosts.isEmpty) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          child: FilteredFeedEmptyState(
            tab: tab,
            onReset: tab == CommunityFeedTab.explore
                ? null
                : () => context.pushReplacement(AppRoutes.community),
          ),
        ),
      ),
    ];
  }

  return [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxxl * 3,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index >= visiblePosts.length) {
            if (feedState.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return const SizedBox.shrink();
          }
          final post = visiblePosts[index];
          return SwipeablePostCard(key: ValueKey(post.id), post: post);
        }, childCount: visiblePosts.length + (feedState.hasMore ? 1 : 0)),
      ),
    ),
  ];
}

String _buildCreatePostRoute(CommunityPostType type) {
  return type == CommunityPostType.general
      ? AppRoutes.communityCreatePost
      : '${AppRoutes.communityCreatePost}?type=${type.toJson()}';
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

/// Floating banner overlay for new posts notification.
class _NewPostsBannerOverlay extends StatelessWidget {
  final int newPostCount;
  final VoidCallback onTap;

  const _NewPostsBannerOverlay({
    required this.newPostCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppSpacing.sm,
      left: 0,
      right: 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        offset: newPostCount > 0 ? Offset.zero : const Offset(0, -2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: newPostCount > 0 ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: newPostCount == 0,
            child: NewPostsBanner(count: newPostCount, onTap: onTap),
          ),
        ),
      ),
    );
  }
}

/// Swipe onboarding hint overlay.
class _SwipeHintOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const _SwipeHintOverlay({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: AppSpacing.xxxl * 3 + AppSpacing.lg,
      left: AppSpacing.xl,
      right: AppSpacing.xl,
      child: GestureDetector(
        onTap: onDismiss,
        child: SwipeOnboardingHint(onDismiss: onDismiss),
      ),
    );
  }
}
