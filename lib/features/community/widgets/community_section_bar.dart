import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_haptics.dart';
import '../providers/community_providers.dart';

/// Section header with title, sort filters, and result count.
class CommunitySectionBar extends StatelessWidget {
  final CommunityFeedTab tab;
  final int visibleCount;
  final CommunityExploreSort exploreSort;
  final ValueChanged<CommunityExploreSort> onExploreSortChanged;

  const CommunitySectionBar({
    super.key,
    required this.tab,
    required this.visibleCount,
    required this.exploreSort,
    required this.onExploreSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleKey = switch (tab) {
      CommunityFeedTab.explore => 'community.tab_explore',
      CommunityFeedTab.following => 'community.tab_following',
      CommunityFeedTab.guides => 'community.tab_guides',
      CommunityFeedTab.questions => 'community.tab_questions',
    };

    if (tab == CommunityFeedTab.guides) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.12),
              theme.colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'community.hero_guides_title'.tr(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'community.hero_guides_hint'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    'community.filter_results'.tr(args: ['$visibleCount']),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  LucideIcons.bookOpen,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _subtitleKey.tr(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  titleKey.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  'community.filter_results'.tr(args: ['$visibleCount']),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _subtitleKey.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (tab == CommunityFeedTab.explore) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _FilterChip(
                  label: 'community.sort_newest'.tr(),
                  icon: LucideIcons.clock3,
                  isSelected: exploreSort == CommunityExploreSort.newest,
                  onTap: () {
                    AppHaptics.selectionClick();
                    onExploreSortChanged(CommunityExploreSort.newest);
                  },
                ),
                _FilterChip(
                  label: 'community.sort_trending'.tr(),
                  icon: LucideIcons.flame,
                  isSelected: exploreSort == CommunityExploreSort.trending,
                  onTap: () {
                    AppHaptics.selectionClick();
                    onExploreSortChanged(CommunityExploreSort.trending);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String get _subtitleKey => switch (tab) {
    CommunityFeedTab.explore => 'community.section_explore_hint',
    CommunityFeedTab.following => 'community.section_following_hint',
    CommunityFeedTab.guides => 'community.section_guides_hint',
    CommunityFeedTab.questions => 'community.section_market_hint',
  };
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.2)
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
      ),
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
    );
  }
}
