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

  // Topic chips are derived from the tags actually present on the loaded
  // guides, so a selected topic always has at least one match.
  final topics = _deriveGuideTopics(visiblePosts);
  final selectedTopic = ref.watch(guideTopicFilterProvider);
  final filtered = (selectedTopic == null || !topics.contains(selectedTopic))
      ? visiblePosts
      : visiblePosts
            .where(
              (p) =>
                  p.tags.contains(selectedTopic) ||
                  p.mutationTags.contains(selectedTopic),
            )
            .toList();

  // "Featured" is the most-engaging guide in the current filter (not just the
  // newest), so the top card highlights the guide breeders found most useful.
  final featuredGuide = filtered.isEmpty
      ? null
      : filtered.reduce(
          (a, b) => _guideEngagement(b) > _guideEngagement(a) ? b : a,
        );
  final libraryGuides = featuredGuide == null
      ? const <CommunityPost>[]
      : filtered.where((p) => p.id != featuredGuide.id).toList();

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
            child: _GuidesLibraryHeader(count: filtered.length),
          ),
        ),
        if (topics.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.lg),
              child: _GuideTopicChips(
                topics: topics,
                selected: selectedTopic,
              ),
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

/// Trending score for a guide — likes weighted over comments (same shape the
/// explore trending sort uses).
int _guideEngagement(CommunityPost post) =>
    (post.likeCount * 2) + post.commentCount;

/// The most common tags across [guides], most-frequent first (max 10). Used to
/// build the topic filter chips. Free tags and mutation tags are pooled.
List<String> _deriveGuideTopics(List<CommunityPost> guides) {
  final counts = <String, int>{};
  for (final guide in guides) {
    for (final tag in [...guide.tags, ...guide.mutationTags]) {
      final normalized = tag.trim();
      if (normalized.isEmpty) continue;
      counts[normalized] = (counts[normalized] ?? 0) + 1;
    }
  }
  final sorted = counts.keys.toList()
    ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  return sorted.take(10).toList();
}

/// Horizontal, scrollable topic filter chips for the guides library. A leading
/// "Tümü" chip clears the filter; tapping the active topic clears it too.
class _GuideTopicChips extends ConsumerWidget {
  const _GuideTopicChips({required this.topics, required this.selected});

  final List<String> topics;
  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(guideTopicFilterProvider.notifier);

    Widget chip({
      required String label,
      required bool active,
      required VoidCallback onTap,
    }) {
      return Semantics(
        button: true,
        selected: active,
        label: label,
        child: Material(
          color: active
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: active
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: topics.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return chip(
              label: 'community.guide_topics_all'.tr(),
              active: selected == null,
              onTap: notifier.clear,
            );
          }
          final topic = topics[index - 1];
          return chip(
            label: '#$topic',
            active: selected == topic,
            onTap: () => notifier.toggle(topic),
          );
        },
      ),
    );
  }
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
              Row(
                children: [
                  const Icon(
                    LucideIcons.star,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      'community.guides_curated_title'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
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
