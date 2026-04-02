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

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 280 ? 2 : 4;
        final totalSpacing = AppSpacing.sm * (columns - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / columns;

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: CommunityFeedTab.values.map((tab) {
              final isActive = activeTab == tab;
              return SizedBox(
                width: itemWidth,
                child: Semantics(
                  button: true,
                  selected: isActive,
                  label: _tabLabel(tab),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    onTap: () {
                      ref.read(communityActiveTabProvider.notifier).state = tab;
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      constraints: const BoxConstraints(
                        minHeight: AppSpacing.touchTargetMd + AppSpacing.md,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.82,
                                  ),
                                ],
                              )
                            : null,
                        color: isActive
                            ? null
                            : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(
                          color: isActive
                              ? theme.colorScheme.primary.withValues(
                                  alpha: 0.15,
                                )
                              : theme.colorScheme.outlineVariant.withValues(
                                  alpha: 0.2,
                                ),
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.18,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _tabIcon(tab, isActive, theme),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _tabLabel(tab),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: isActive
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _tabIcon(CommunityFeedTab tab, bool isActive, ThemeData theme) {
    final color = isActive
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;

    return switch (tab) {
      CommunityFeedTab.explore => Icon(
        LucideIcons.flame,
        size: 16,
        color: color,
      ),
      CommunityFeedTab.following => Icon(
        LucideIcons.users,
        size: 16,
        color: color,
      ),
      CommunityFeedTab.guides => Icon(
        LucideIcons.bookOpen,
        size: 16,
        color: color,
      ),
      CommunityFeedTab.questions => Icon(
        LucideIcons.store,
        size: 16,
        color: color,
      ),
    };
  }

  /// Override questions tab label to show short marketplace name.
  String _tabLabel(CommunityFeedTab tab) => switch (tab) {
    CommunityFeedTab.questions => 'community.tab_marketplace'.tr(),
    _ => tab.label,
  };
}
