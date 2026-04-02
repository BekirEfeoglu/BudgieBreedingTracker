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

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useGrid = constraints.maxWidth < 280;

          if (useGrid) {
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: CommunityFeedTab.values.map((tab) {
                final itemWidth =
                    (constraints.maxWidth - AppSpacing.sm) / 2;
                return SizedBox(
                  width: itemWidth,
                  child: _PillTab(
                    tab: tab,
                    isActive: activeTab == tab,
                    onTap: () => ref
                        .read(communityActiveTabProvider.notifier)
                        .state = tab,
                    theme: theme,
                  ),
                );
              }).toList(),
            );
          }

          // 4-column: use Row + Expanded to avoid subpixel wrap issues
          return Row(
            children: [
              for (int i = 0; i < CommunityFeedTab.values.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PillTab(
                    tab: CommunityFeedTab.values[i],
                    isActive: activeTab == CommunityFeedTab.values[i],
                    onTap: () => ref
                        .read(communityActiveTabProvider.notifier)
                        .state = CommunityFeedTab.values[i],
                    theme: theme,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  final CommunityFeedTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final ThemeData theme;

  const _PillTab({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: tab.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
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
                      theme.colorScheme.primary.withValues(alpha: 0.82),
                    ],
                  )
                : null,
            color: isActive
                ? null
                : theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.18),
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
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isActive
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _tabIcon(
    CommunityFeedTab tab,
    bool isActive,
    ThemeData theme,
  ) {
    final color = isActive
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;

    return switch (tab) {
      CommunityFeedTab.explore => Icon(LucideIcons.flame, size: 16, color: color),
      CommunityFeedTab.following => Icon(LucideIcons.users, size: 16, color: color),
      CommunityFeedTab.guides => Icon(LucideIcons.bookOpen, size: 16, color: color),
      CommunityFeedTab.questions => Icon(LucideIcons.store, size: 16, color: color),
    };
  }
}
