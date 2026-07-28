import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/animations/shimmer_shine_animation.dart';

import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';

/// Breakpoint for switching between bottom nav and side rail.
const double _kTabletBreakpoint = 600;
const double _kDesktopBreakpoint = 900;

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  static const _navItems = [
    _NavItem(iconAsset: AppIcons.home, label: 'nav.home'),
    _NavItem(iconAsset: AppIcons.bird, label: 'nav.birds'),
    _NavItem(iconAsset: AppIcons.breeding, label: 'nav.breeding'),
    _NavItem(iconAsset: AppIcons.calendar, label: 'nav.calendar'),
    _NavItem(iconAsset: AppIcons.more, label: 'nav.more'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    // Sync profile from Supabase to local DB on first load
    ref.watch(profileSyncProvider(userId));

    // Keep periodic (15 min) and network-aware sync providers alive.
    // These set up Timer and ref.listen callbacks that must persist
    // for the entire authenticated session to enable offline→online sync.
    ref.watch(periodicSyncProvider);
    ref.watch(networkAwareSyncProvider);

    final selectedIndex = navigationShell.currentIndex;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= _kTabletBreakpoint;
    final isDesktop = width >= _kDesktopBreakpoint;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              labelType: isDesktop
                  ? NavigationRailLabelType.all
                  : NavigationRailLabelType.selected,
              onDestinationSelected: _goToBranch,
              destinations: _navItems.map((item) {
                return NavigationRailDestination(
                  icon: AppIcon(item.iconAsset),
                  selectedIcon: ShimmerShineAnimation(
                    isActive: true,
                    duration: const Duration(milliseconds: 2000),
                    shineColor: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.5),
                    child: AppIcon(
                      item.iconAsset,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  label: Text(item.label.tr()),
                );
              }).toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _goToBranch,
        destinations: _navItems.map((item) {
          return NavigationDestination(
            icon: AppIcon(item.iconAsset),
            selectedIcon: ShimmerShineAnimation(
              isActive: true,
              duration: const Duration(milliseconds: 2000),
              shineColor: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.5),
              child: AppIcon(
                item.iconAsset,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            label: item.label.tr(),
          );
        }).toList(),
      ),
    );
  }

  void _goToBranch(int index) {
    AppHaptics.lightImpact();
    navigationShell.goBranch(
      index,
      // A second tap on the active destination follows the native tab-bar
      // convention and returns that branch to its root. Switching to another
      // branch preserves its Navigator and local widget/scroll state.
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _NavItem {
  final String iconAsset;
  final String label;
  const _NavItem({required this.iconAsset, required this.label});
}
