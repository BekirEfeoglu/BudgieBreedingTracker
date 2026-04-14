import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../providers/community_providers.dart';

/// Skeleton placeholder shown while the community feed loads.
class CommunityFeedSkeleton extends StatelessWidget {
  const CommunityFeedSkeleton({super.key});

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

class GuidesLibrarySkeleton extends StatelessWidget {
  const GuidesLibrarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('guides_library_skeleton'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        const SkeletonLoader(height: 148, borderRadius: AppSpacing.radiusXl),
        const SizedBox(height: AppSpacing.lg),
        const Row(
          children: [
            Expanded(child: SkeletonLoader(height: 22)),
            SizedBox(width: AppSpacing.md),
            SkeletonLoader(
              width: 86,
              height: 36,
              borderRadius: AppSpacing.radiusFull,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const SkeletonLoader(height: 280, borderRadius: AppSpacing.radiusXl),
        const SizedBox(height: AppSpacing.lg),
        ...List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: SkeletonLoader(
              height: 210,
              borderRadius: AppSpacing.radiusXl,
            ),
          ),
        ),
      ],
    );
  }
}

/// Skeleton placeholder shown while comments are loading.
class CommunityCommentSkeleton extends StatelessWidget {
  const CommunityCommentSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    final shimmer = Theme.of(context).colorScheme.surfaceContainerHighest;
    return RepaintBoundary(
      child: Column(
        children: List.generate(
          count,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: shimmer,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: shimmer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: shimmer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 160,
                        height: 12,
                        decoration: BoxDecoration(
                          color: shimmer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
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

/// Empty state for filtered feed tabs (no matching posts).
class FilteredFeedEmptyState extends StatelessWidget {
  final CommunityFeedTab tab;
  final VoidCallback? onReset;

  const FilteredFeedEmptyState({
    super.key,
    required this.tab,
    required this.onReset,
  });

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
