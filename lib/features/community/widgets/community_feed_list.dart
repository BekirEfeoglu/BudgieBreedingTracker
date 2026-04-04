import 'dart:async';

import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../router/route_names.dart';
import '../providers/community_feed_providers.dart';
import '../providers/community_post_providers.dart';
import '../providers/community_providers.dart';
import 'community_following_list.dart';
import 'community_post_card.dart';
import 'community_quick_composer.dart';
import 'community_section_bar.dart';
import 'community_story_strip.dart';

/// Scrollable feed list with infinite scroll and pull-to-refresh.
class CommunityFeedList extends ConsumerStatefulWidget {
  final CommunityFeedTab tab;

  const CommunityFeedList({super.key, this.tab = CommunityFeedTab.explore});

  @override
  ConsumerState<CommunityFeedList> createState() => _CommunityFeedListState();
}

class _CommunityFeedListState extends ConsumerState<CommunityFeedList> {
  static const _swipeOnboardingKey = 'pref_swipe_onboarding_shown';

  final _scrollController = ScrollController();
  Timer? _swipeHintTimer;
  int _lastSeenCount = 0;
  int _newPostCount = 0;
  bool _showSwipeHint = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkSwipeOnboarding();
  }

  @override
  void dispose() {
    _swipeHintTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkSwipeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_swipeOnboardingKey) == true) return;
      if (!mounted) return;
      setState(() => _showSwipeHint = true);
      await prefs.setBool(_swipeOnboardingKey, true);
      _swipeHintTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showSwipeHint = false);
      });
    } catch (_) {
      // SharedPreferences unavailable — skip onboarding
    }
  }

  void _dismissSwipeHint() {
    if (_showSwipeHint) setState(() => _showSwipeHint = false);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      ref.read(communityFeedProvider.notifier).fetchMore();
    }
  }

  void _scrollToTopAndDismiss() {
    setState(() {
      _newPostCount = 0;
      _lastSeenCount = ref.read(communityFeedProvider).posts.length;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Following tab shows a people list, not a post feed
    if (widget.tab == CommunityFeedTab.following) {
      return const CommunityFollowingList();
    }

    final feedState = ref.watch(communityFeedProvider);
    final posts = feedState.posts;

    // Detect new posts arriving while user is scrolled down
    ref.listen<FeedState>(communityFeedProvider, (prev, next) {
      if (prev == null || next.isLoading) return;
      final prevLen = prev.posts.length;
      final nextLen = next.posts.length;
      // Only show banner if new posts appeared at the beginning (refresh),
      // not from pagination (fetchMore appends at the end).
      if (nextLen > prevLen && _lastSeenCount > 0) {
        final isScrolledDown = _scrollController.hasClients &&
            _scrollController.position.pixels > 200;
        if (isScrolledDown) {
          setState(() => _newPostCount = nextLen - _lastSeenCount);
        }
      }
      _lastSeenCount = nextLen;
    });

    // Initialize last seen count on first build
    if (_lastSeenCount == 0 && posts.isNotEmpty) {
      _lastSeenCount = posts.length;
    }

    final currentUserId = ref.watch(currentUserIdProvider);
    final visiblePosts = ref.watch(communityVisiblePostsProvider(widget.tab));
    final isExplore = widget.tab == CommunityFeedTab.explore;
    final showExploreExtras = isExplore && visiblePosts.isNotEmpty;
    final exploreSort = ref.watch(exploreSortProvider);
    final defaultCreateType = widget.tab == CommunityFeedTab.guides
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
      return const _CommunityFeedSkeleton();
    }

    return Stack(
      children: [
      RefreshIndicator(
      onRefresh: () async {
        await ref.read(communityFeedProvider.notifier).refresh();
        if (!mounted) return;
        setState(() {
          _newPostCount = 0;
          _lastSeenCount = ref.read(communityFeedProvider).posts.length;
        });
      },
      child: CustomScrollView(
        controller: _scrollController,
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
                  tab: widget.tab,
                  visibleCount: visiblePosts.length,
                  exploreSort: exploreSort,
                  onExploreSortChanged: _changeSort,
                ),
              ),
            ),
          // 4. Empty states or post list
          if (!feedState.isLoading && posts.isEmpty)
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
            )
          else if (!feedState.isLoading && visiblePosts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxxl,
                ),
                child: _FilteredFeedEmptyState(
                  tab: widget.tab,
                  onReset: widget.tab == CommunityFeedTab.explore
                      ? null
                      : () => context.go(AppRoutes.community),
                ),
              ),
            )
          else
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
                    return _KeepAlivePostCard(
                      key: ValueKey(post.id),
                      post: post,
                    );
                  },
                  childCount: visiblePosts.length + (feedState.hasMore ? 1 : 0),
                ),
              ),
            ),
        ],
      ),
    ),
      // "New posts" floating banner with slide-in animation
      Positioned(
        top: AppSpacing.sm,
        left: 0,
        right: 0,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          offset: _newPostCount > 0 ? Offset.zero : const Offset(0, -2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _newPostCount > 0 ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: _newPostCount == 0,
              child: _NewPostsBanner(
                count: _newPostCount,
                onTap: _scrollToTopAndDismiss,
              ),
            ),
          ),
        ),
      ),
      // Swipe onboarding hint
      if (_showSwipeHint)
        Positioned(
          bottom: AppSpacing.xxxl * 3 + AppSpacing.lg,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          child: GestureDetector(
            onTap: _dismissSwipeHint,
            child: _SwipeOnboardingHint(onDismiss: _dismissSwipeHint),
          ),
        ),
      ],
    );
  }

  void _changeSort(CommunityExploreSort sort) {
    ref.read(exploreSortProvider.notifier).state = sort;

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _buildCreatePostRoute(CommunityPostType type) {
    return type == CommunityPostType.general
        ? AppRoutes.communityCreatePost
        : '${AppRoutes.communityCreatePost}?type=${type.toJson()}';
  }
}

class _CommunityFeedSkeleton extends StatelessWidget {
  const _CommunityFeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('community_feed_skeleton'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        // Compact composer skeleton
        const RepaintBoundary(
          child: SkeletonLoader(height: 48, borderRadius: AppSpacing.radiusXl),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Post card skeletons (x3)
        ...List.generate(
          3,
          (_) => const RepaintBoundary(
            child: Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar row
                Row(
                  children: [
                    SkeletonLoader(
                      width: 36,
                      height: 36,
                      borderRadius: AppSpacing.radiusFull,
                    ),
                    SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLoader(width: 120, height: 14),
                        SizedBox(height: AppSpacing.xs),
                        SkeletonLoader(width: 80, height: 10),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                // Content lines
                SkeletonLoader(height: 14),
                SizedBox(height: AppSpacing.sm),
                SkeletonLoader(width: 240, height: 14),
                SizedBox(height: AppSpacing.md),
                // Image placeholder
                SkeletonLoader(
                  height: 160,
                  borderRadius: AppSpacing.radiusLg,
                ),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }
}

class _FilteredFeedEmptyState extends StatelessWidget {
  final CommunityFeedTab tab;
  final VoidCallback? onReset;

  const _FilteredFeedEmptyState({required this.tab, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleKey = switch (tab) {
      CommunityFeedTab.explore => 'community.empty_filtered_title',
      CommunityFeedTab.following => 'community.empty_following_title',
      CommunityFeedTab.guides => 'community.empty_guides_title',
      CommunityFeedTab.questions => 'community.empty_questions_title',
    };
    final hintKey = switch (tab) {
      CommunityFeedTab.explore => 'community.empty_filtered_hint',
      CommunityFeedTab.following => 'community.empty_following_hint',
      CommunityFeedTab.guides => 'community.empty_guides_hint',
      CommunityFeedTab.questions => 'community.empty_questions_hint',
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.searchX, size: 32),
          const SizedBox(height: AppSpacing.md),
          Text(
            titleKey.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hintKey.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (onReset != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonal(
              onPressed: onReset,
              child: Text('community.show_all'.tr()),
            ),
          ],
        ],
      ),
    );
  }
}

/// Wraps a [CommunityPostCard] with [AutomaticKeepAliveClientMixin] and
/// swipe-to-like (right) / swipe-to-bookmark (left) gesture support.
class _KeepAlivePostCard extends ConsumerStatefulWidget {
  final CommunityPost post;

  const _KeepAlivePostCard({super.key, required this.post});

  @override
  ConsumerState<_KeepAlivePostCard> createState() => _KeepAlivePostCardState();
}

class _KeepAlivePostCardState extends ConsumerState<_KeepAlivePostCard>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  static const _swipeThreshold = 80.0;

  late final AnimationController _slideController;
  double _dragExtent = 0;
  bool _actionTriggered = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.delta.dx;
      // Clamp to prevent over-dragging
      _dragExtent = _dragExtent.clamp(-120.0, 120.0);
    });

    if (!_actionTriggered && _dragExtent.abs() >= _swipeThreshold) {
      _actionTriggered = true;
      AppHaptics.mediumImpact();
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent.abs() >= _swipeThreshold) {
      if (_dragExtent > 0) {
        // Swipe right → like
        ref.read(likeToggleProvider.notifier).toggleLike(widget.post.id);
      } else {
        // Swipe left → bookmark
        ref
            .read(bookmarkToggleProvider.notifier)
            .toggleBookmark(widget.post.id);
      }
    }
    setState(() {
      _dragExtent = 0;
      _actionTriggered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isRight = _dragExtent > 0;
    final progress = (_dragExtent.abs() / _swipeThreshold).clamp(0.0, 1.0);

    return RepaintBoundary(
      child: Stack(
        children: [
          // Background hint
          if (_dragExtent != 0)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: (isRight
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.tertiaryContainer)
                      .withValues(alpha: progress * 0.8),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                alignment:
                    isRight ? Alignment.centerLeft : Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Opacity(
                  opacity: progress,
                  child: AnimatedScale(
                    scale: _actionTriggered ? 1.3 : progress,
                    duration: Duration(
                      milliseconds: _actionTriggered ? 200 : 0,
                    ),
                    curve: Curves.elasticOut,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRight ? LucideIcons.heart : LucideIcons.bookmark,
                          color: isRight
                              ? theme.colorScheme.primary
                              : theme.colorScheme.tertiary,
                          size: 28,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          isRight
                              ? 'community.like'.tr()
                              : 'community.bookmark'.tr(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isRight
                                ? theme.colorScheme.primary
                                : theme.colorScheme.tertiary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Card with drag offset
          GestureDetector(
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: AnimatedContainer(
              duration: _dragExtent == 0
                  ? const Duration(milliseconds: 250)
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(_dragExtent, 0, 0),
              child: CommunityPostCard(post: widget.post),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating banner that appears when new posts arrive while user is scrolled.
class _NewPostsBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NewPostsBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.arrowUp,
                  size: 16,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'community.new_posts_banner'.tr(args: ['$count']),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One-time hint explaining swipe gestures on post cards.
class _SwipeOnboardingHint extends StatelessWidget {
  final VoidCallback onDismiss;

  const _SwipeOnboardingHint({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.hand,
                  size: 20,
                  color: theme.colorScheme.onInverseSurface,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'community.swipe_hint_title'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onInverseSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  onTap: onDismiss,
                  child: Icon(
                    LucideIcons.x,
                    size: 18,
                    color: theme.colorScheme.onInverseSurface.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _SwipeHintItem(
                    icon: LucideIcons.arrowRight,
                    label: 'community.swipe_right_like'.tr(),
                    color: theme.colorScheme.primary,
                    bgColor: theme.colorScheme.onInverseSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SwipeHintItem(
                    icon: LucideIcons.arrowLeft,
                    label: 'community.swipe_left_bookmark'.tr(),
                    color: theme.colorScheme.tertiary,
                    bgColor: theme.colorScheme.onInverseSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeHintItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _SwipeHintItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: bgColor.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
