import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import '../providers/marketplace_providers.dart';
import 'marketplace_filter_sheet.dart';
import 'package:budgie_breeding_tracker/core/widgets/bottom_sheet/app_bottom_sheet.dart';

Widget _filterIcon(MarketplaceFilter filter, {double? size, Color? color}) =>
    switch (filter) {
      MarketplaceFilter.all => Icon(LucideIcons.list, size: size, color: color),
      MarketplaceFilter.sale => Icon(LucideIcons.tag, size: size, color: color),
      MarketplaceFilter.adoption => AppIcon(
        AppIcons.heart,
        size: size,
        color: color,
      ),
      MarketplaceFilter.trade => Icon(
        LucideIcons.arrowLeftRight,
        size: size,
        color: color,
      ),
      MarketplaceFilter.wanted => Icon(
        LucideIcons.search,
        size: size,
        color: color,
      ),
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
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: FilterChip(
                avatar: isSelected ? _filterIcon(filter, size: 16) : null,
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
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
            child: Badge(
              isLabelVisible: activeCount > 0,
              label: Text('$activeCount'),
              child: AppIconButton(
                icon: const Icon(LucideIcons.slidersHorizontal),
                semanticLabel: 'marketplace.filter_results'.tr(),
                onPressed: () => showAppBottomSheet(
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
