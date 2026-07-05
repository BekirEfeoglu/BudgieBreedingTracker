import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/app_icon.dart';
import '../providers/community_providers.dart';

/// Segmented pill tab bar for community feed filtering.
///
/// Horizontal control: each tab shows its icon and label inline. The active
/// tab is filled with the brand gradient; inactive tabs stay transparent so
/// the shared track (owned by the parent rail) reads as one segmented bar.
class CommunityPillTabs extends ConsumerWidget {
  const CommunityPillTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(communityActiveTabProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useGrid = constraints.maxWidth < 280;

          void select(CommunityFeedTab tab) {
            AppHaptics.selectionClick();
            ref.read(communityActiveTabProvider.notifier).state = tab;
          }

          if (useGrid) {
            return Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: CommunityFeedTab.values.map((tab) {
                final itemWidth = (constraints.maxWidth - AppSpacing.xs) / 2;
                return SizedBox(
                  width: itemWidth,
                  child: _PillTab(
                    tab: tab,
                    isActive: activeTab == tab,
                    onTap: () => select(tab),
                    theme: theme,
                  ),
                );
              }).toList(),
            );
          }

          // 4-column: Row + Expanded to avoid subpixel wrap issues.
          return Row(
            children: [
              for (int i = 0; i < CommunityFeedTab.values.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _PillTab(
                    tab: CommunityFeedTab.values[i],
                    isActive: activeTab == CommunityFeedTab.values[i],
                    onTap: () => select(CommunityFeedTab.values[i]),
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
    final activeColor = theme.colorScheme.onPrimary;
    final inactiveColor = theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isActive,
      label: tab.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(
            minHeight: AppSpacing.touchTargetMd,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryLight],
                  )
                : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.32),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tabIcon(tab, isActive, theme),
              const SizedBox(width: AppSpacing.xs + 2),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tab.label,
                    maxLines: 1,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isActive ? activeColor : inactiveColor,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _tabIcon(CommunityFeedTab tab, bool isActive, ThemeData theme) {
    final color = isActive
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;

    return switch (tab) {
      CommunityFeedTab.explore => Icon(
        LucideIcons.compass,
        size: 16,
        color: color,
      ),
      CommunityFeedTab.following => Icon(
        LucideIcons.users,
        size: 16,
        color: color,
      ),
      CommunityFeedTab.guides => AppIcon(
        AppIcons.guide,
        size: 16,
        color: color,
      ),
      CommunityFeedTab.marketplace => Icon(
        LucideIcons.tag,
        size: 16,
        color: color,
      ),
    };
  }
}
