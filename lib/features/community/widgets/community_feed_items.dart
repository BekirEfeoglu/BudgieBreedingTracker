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
    return const CommunityFeedSkeleton();
  }

  return Stack(
    children: [
      RefreshIndicator(
        onRefresh: () async {
          await ref.read(communityFeedProvider.notifier).refresh();
          if (!mounted) return;
          onUpdateNewPostCount(0);
          onUpdateLastSeenCount(
            ref.read(communityFeedProvider).posts.length,
          );
        },
        child: CustomScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Quick Composer
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
                  onCreatePost: () => context.push(
                    _buildCreatePostRoute(defaultCreateType),
                  ),
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
                  onCreatePost: () => context.push(
                    _buildCreatePostRoute(defaultCreateType),
                  ),
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
      _NewPostsBannerOverlay(
        newPostCount: newPostCount,
        onTap: onScrollToTop,
      ),
      // Swipe onboarding hint
      if (showSwipeHint)
        _SwipeHintOverlay(onDismiss: onDismissSwipeHint),
    ],
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
                : () => context.go(AppRoutes.community),
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
        delegate: SliverChildBuilderDelegate(
          (context, index) {
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
            return SwipeablePostCard(
              key: ValueKey(post.id),
              post: post,
            );
          },
          childCount: visiblePosts.length + (feedState.hasMore ? 1 : 0),
        ),
      ),
    ),
  ];
}

String _buildCreatePostRoute(CommunityPostType type) {
  return type == CommunityPostType.general
      ? AppRoutes.communityCreatePost
      : '${AppRoutes.communityCreatePost}?type=${type.toJson()}';
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
            child: NewPostsBanner(
              count: newPostCount,
              onTap: onTap,
            ),
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
