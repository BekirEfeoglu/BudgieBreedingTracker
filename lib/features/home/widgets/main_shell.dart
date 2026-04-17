import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';

import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';

/// Breakpoint for switching between bottom nav and side rail.
const double _kTabletBreakpoint = 600;
const double _kDesktopBreakpoint = 900;

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _navItems = [
    _NavItem(iconAsset: AppIcons.home, label: 'nav.home', path: '/'),
    _NavItem(iconAsset: AppIcons.bird, label: 'nav.birds', path: '/birds'),
    _NavItem(
      iconAsset: AppIcons.breeding,
      label: 'nav.breeding',
      path: '/breeding',
    ),
    _NavItem(
      iconAsset: AppIcons.calendar,
      label: 'nav.calendar',
      path: '/calendar',
    ),
    _NavItem(iconAsset: AppIcons.more, label: 'nav.more', path: '/more'),
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

    // Show a temporary SnackBar when the device reconnects after being offline.
    ref.listen<SyncDisplayStatus>(syncStatusProvider, (previous, next) {
      if (previous == SyncDisplayStatus.offline &&
          next != SyncDisplayStatus.offline) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('sync.reconnected'.tr()),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    final selectedIndex = _calculateIndex(
      GoRouterState.of(context).matchedLocation,
    );
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
              onDestinationSelected: (index) {
                AppHaptics.lightImpact();
                context.go(_navItems[index].path);
              },
              destinations: _navItems.map((item) {
                return NavigationRailDestination(
                  icon: AppIcon(item.iconAsset),
                  selectedIcon: AppIcon(
                    item.iconAsset,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(item.label.tr()),
                );
              }).toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          AppHaptics.lightImpact();
          context.go(_navItems[index].path);
        },
        destinations: _navItems.map((item) {
          return NavigationDestination(
            icon: AppIcon(item.iconAsset),
            selectedIcon: AppIcon(
              item.iconAsset,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: item.label.tr(),
          );
        }).toList(),
      ),
    );
  }

  int _calculateIndex(String location) {
    if (location == '/') return 0;
    if (location.startsWith('/birds')) return 1;
    if (location.startsWith('/breeding')) return 2;
    if (location.startsWith('/calendar')) return 3;
    // Chicks are accessed via More → highlight More tab
    return 4;
  }
}

class _NavItem {
  final String iconAsset;
  final String label;
  final String path;
  const _NavItem({
    required this.iconAsset,
    required this.label,
    required this.path,
  });
}

