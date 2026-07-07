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
}) {
  final feedState = ref.watch(communityFeedProvider);
  final posts = feedState.posts;
  final visiblePosts = ref.watch(communityVisiblePostsProvider(tab));
  final isFollowing = tab == CommunityFeedTab.following;
  // Story strip lives on the "Takip" (following) tab per the redesign — a
  // horizontal ring of recently-active followed users above their feed.
  final showFollowingStories = isFollowing && visiblePosts.isNotEmpty;
  final isGuides = tab == CommunityFeedTab.guides;
  final defaultCreateType = tab == CommunityFeedTab.guides
      ? CommunityPostType.guide
      : CommunityPostType.general;

  if (feedState.error != null && posts.isEmpty) {
    return Center(
      child: app.ErrorState(
        message: _feedErrorMessage(feedState.error),
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
    final isFounder = ref.watch(isFounderProvider).value == true;
    return _buildGuidesLibraryView(
      context: context,
      ref: ref,
      feedState: feedState,
      visiblePosts: visiblePosts,
      scrollController: scrollController,
      isFounder: isFounder,
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
            // Story strip (following tab only)
            if (showFollowingStories)
              SliverToBoxAdapter(
                child: CommunityStoryStrip(
                  stories: CommunityStoryStrip.fromPosts(visiblePosts),
                  onCreatePost: () =>
                      context.push(_buildCreatePostRoute(defaultCreateType)),
                ),
              ),
            // Empty states or post list
            ..._buildFeedBody(
              context: context,
              ref: ref,
              tab: tab,
              feedState: feedState,
              visiblePosts: visiblePosts,
            ),
          ],
        ),
      ),
      // "New posts" floating banner with slide-in animation
      _NewPostsBannerOverlay(newPostCount: newPostCount, onTap: onScrollToTop),
      // Swipe onboarding hint
      if (showSwipeHint) _SwipeHintOverlay(onDismiss: onDismissSwipeHint),
    ],
  );
}

/// Builds either empty states or the post list slivers.
List<Widget> _buildFeedBody({
  required BuildContext context,
  required WidgetRef ref,
  required CommunityFeedTab tab,
  required FeedState feedState,
  required List<CommunityPost> visiblePosts,
}) {
  // Explore has no user-facing search/filter UI, so an empty Explore feed is a
  // "be the first to post" moment — not a "no search results" one. Route it to
  // the welcoming empty state (with a create CTA) rather than the filtered one.
  // Source of truth lives in `communityShowWelcomeEmptyProvider` so the
  // CommunityScreen FAB can hide while this CTA is on screen.
  final showWelcomeEmpty = ref.watch(communityShowWelcomeEmptyProvider(tab));

  if (showWelcomeEmpty) {
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
                child: LoadingState(),
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

String _feedErrorMessage(String? error) {
  final title = 'community.feed_load_error'.tr();
  if (error == null || error.isEmpty) return title;

  final safeErrorKey = _isLocalizationKey(error)
      ? error
      : 'errors.unknown_error';
  return '$title: ${safeErrorKey.tr()}';
}

bool _isLocalizationKey(String value) {
  return RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$').hasMatch(value);
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
