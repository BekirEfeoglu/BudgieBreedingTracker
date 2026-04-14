import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../providers/marketplace_providers.dart';
import 'marketplace_filter_sheet.dart';

IconData _filterIcon(MarketplaceFilter filter) => switch (filter) {
      MarketplaceFilter.all => LucideIcons.list,
      MarketplaceFilter.sale => LucideIcons.tag,
      MarketplaceFilter.adoption => LucideIcons.heart,
      MarketplaceFilter.trade => LucideIcons.arrowLeftRight,
      MarketplaceFilter.wanted => LucideIcons.search,
    };

class MarketplaceFilterBar extends ConsumerWidget {
  const MarketplaceFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(marketplaceFilterProvider);
    final activeCount = ref.watch(activeFilterCountProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          ...MarketplaceFilter.values.map((filter) {
            final isSelected = currentFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                avatar: isSelected ? Icon(_filterIcon(filter), size: 16) : null,
                label: Text(filter.label),
                selected: isSelected,
                onSelected: (_) {
                  ref.read(marketplaceFilterProvider.notifier).state = filter;
                },
                selectedColor: theme.colorScheme.primaryContainer,
                checkmarkColor: theme.colorScheme.primary,
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Badge(
              isLabelVisible: activeCount > 0,
              label: Text('$activeCount'),
              child: IconButton(
                icon: const Icon(LucideIcons.slidersHorizontal),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const MarketplaceFilterSheet(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
