import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleKey.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (tab == CommunityFeedTab.explore)
          Row(
            children: [
              _FilterChip(
                label: 'community.sort_newest'.tr(),
                icon: LucideIcons.clock3,
                isSelected: exploreSort == CommunityExploreSort.newest,
                onTap: () => onExploreSortChanged(CommunityExploreSort.newest),
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                label: 'community.sort_trending'.tr(),
                icon: LucideIcons.flame,
                isSelected: exploreSort == CommunityExploreSort.trending,
                onTap: () =>
                    onExploreSortChanged(CommunityExploreSort.trending),
              ),
            ],
          ),
        if (tab == CommunityFeedTab.explore)
          const SizedBox(height: AppSpacing.md),
        Text(
          'community.filter_results'.tr(args: ['$visibleCount']),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
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
