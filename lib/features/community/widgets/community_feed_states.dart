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
