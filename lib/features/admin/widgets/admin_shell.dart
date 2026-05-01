import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/widgets/buttons/app_icon_button.dart';
import '../../../router/route_names.dart';
import '../constants/admin_constants.dart';
import 'admin_sidebar.dart';

/// Shell widget for admin routes.
///
/// On wide screens (>= 840dp) shows a permanent sidebar.
/// On narrow screens uses a Drawer accessible from the AppBar.
class AdminShell extends StatelessWidget {
  /// The current route child to display.
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.sizeOf(context).width >= AdminConstants.wideLayoutBreakpoint;

    if (isWide) {
      return _WideLayout(child: child);
    }
    return _NarrowLayout(child: child);
  }
}

/// Wide (desktop/tablet) layout with permanent sidebar.
class _WideLayout extends StatelessWidget {
  final Widget child;

  const _WideLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const AdminSidebar(),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Narrow (mobile) layout with Drawer sidebar.
class _NarrowLayout extends StatelessWidget {
  final Widget child;

  const _NarrowLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final title = _titleForRoute(location);

    return Scaffold(
      appBar: AppBar(
        title: Text(title.tr()),
        leading: Builder(
          builder: (ctx) => AppIconButton(
            icon: const Icon(LucideIcons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'admin.menu'.tr(),
            semanticLabel: 'admin.menu'.tr(),
          ),
        ),
        actions: [
          AppIconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.go(AppRoutes.home),
            tooltip: 'admin.back_to_app'.tr(),
            semanticLabel: 'admin.back_to_app'.tr(),
          ),
        ],
      ),
      drawer: const Drawer(child: AdminSidebar()),
      body: child,
    );
  }

  /// Maps route path to a localization key for the title.
  String _titleForRoute(String location) {
    if (location.contains('/users')) return 'admin.users';
    if (location.contains('/monitoring')) return 'admin.monitoring';
    if (location.contains('/database')) return 'admin.database';
    if (location.contains('/audit')) return 'admin.audit';
    if (location.contains('/security')) return 'admin.security';
    if (location.contains('/settings')) return 'admin.settings';
    if (location.contains('/feedback')) return 'admin.feedback_admin';
    return 'admin.dashboard';
  }
}
