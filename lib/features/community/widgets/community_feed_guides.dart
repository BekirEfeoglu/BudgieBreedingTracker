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
