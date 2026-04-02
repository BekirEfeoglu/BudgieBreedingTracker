import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../providers/community_providers.dart';

/// Pill-shaped chip tab bar for community feed filtering.
class CommunityPillTabs extends ConsumerWidget {
  const CommunityPillTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(communityActiveTabProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: CommunityFeedTab.values.map((tab) {
          final isActive = activeTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () {
                ref.read(communityActiveTabProvider.notifier).state = tab;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _tabIcon(tab, isActive, theme),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _tabLabel(tab),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isActive
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _tabIcon(CommunityFeedTab tab, bool isActive, ThemeData theme) {
    final color = isActive
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return switch (tab) {
      CommunityFeedTab.explore => Icon(LucideIcons.flame, size: 14, color: color),
      CommunityFeedTab.following => Icon(LucideIcons.users, size: 14, color: color),
      CommunityFeedTab.guides => Icon(LucideIcons.bookOpen, size: 14, color: color),
      CommunityFeedTab.questions => Icon(LucideIcons.store, size: 14, color: color),
    };
  }

  /// Override questions tab label to show as "Pazar Yeri"
  String _tabLabel(CommunityFeedTab tab) => switch (tab) {
    CommunityFeedTab.questions => 'marketplace.title'.tr(),
    _ => tab.label,
  };
}
