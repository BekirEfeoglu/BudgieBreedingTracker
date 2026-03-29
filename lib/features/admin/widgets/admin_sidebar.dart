import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../router/route_names.dart';

/// Admin sidebar navigation with menu items and route highlighting.
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  static final _menuItems = [
    const _AdminMenuItem(
      icon: AppIcon(AppIcons.dashboard),
      labelKey: 'admin.dashboard',
      route: AppRoutes.adminDashboard,
    ),
    const _AdminMenuItem(
      icon: AppIcon(AppIcons.users),
      labelKey: 'admin.users',
      route: AppRoutes.adminUsers,
    ),
    const _AdminMenuItem(
      icon: AppIcon(AppIcons.monitoring),
      labelKey: 'admin.monitoring',
      route: AppRoutes.adminMonitoring,
    ),
    const _AdminMenuItem(
      icon: AppIcon(AppIcons.database),
      labelKey: 'admin.database',
      route: AppRoutes.adminDatabase,
    ),
    const _AdminMenuItem(
      icon: AppIcon(AppIcons.audit),
      labelKey: 'admin.audit',
      route: AppRoutes.adminAudit,
    ),
    const _AdminMenuItem(
      icon: AppIcon(AppIcons.security),
      labelKey: 'admin.security',
      route: AppRoutes.adminSecurity,
    ),
    const _AdminMenuItem(
      icon: AppIcon(AppIcons.settings),
      labelKey: 'admin.settings',
      route: AppRoutes.adminSettings,
    ),
    const _AdminMenuItem(
      icon: AppIcon(AppIcons.comment),
      labelKey: 'admin.feedback_admin',
      route: AppRoutes.adminFeedback,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final theme = Theme.of(context);

    return Container(
      width: 260,
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          _buildHeader(context),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = currentRoute == item.route;
                return _buildMenuItem(context, item, isSelected);
              },
            ),
          ),
          const Divider(height: 1),
          _buildBackToApp(context),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          AppIcon(
            AppIcons.security,
            color: theme.colorScheme.primary,
            size: 28,
            semanticsLabel: 'admin.panel_title'.tr(),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'admin.panel_title'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    _AdminMenuItem item,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        // Transparent when not selected to let the surface show through
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surface.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: () {
            final scaffold = Scaffold.maybeOf(context);
            if (scaffold != null && scaffold.isDrawerOpen) {
              scaffold.closeDrawer();
            }
            context.go(item.route);
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                IconTheme(
                  data: IconThemeData(size: 20, color: color),
                  child: item.icon,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    item.labelKey.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackToApp(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Material(
        // Transparent to let the surface show through
        color: theme.colorScheme.surface.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Tooltip(
          message: 'admin.back_to_app'.tr(),
          child: InkWell(
          onTap: () {
            final scaffold = Scaffold.maybeOf(context);
            if (scaffold != null && scaffold.isDrawerOpen) {
              scaffold.closeDrawer();
            }
            context.go(AppRoutes.home);
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Semantics(
                  label: 'admin.back_to_app'.tr(),
                  child: Icon(
                    LucideIcons.arrowLeft,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'admin.back_to_app'.tr(),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _AdminMenuItem {
  const _AdminMenuItem({
    required this.icon,
    required this.labelKey,
    required this.route,
  });

  final Widget icon;
  final String labelKey;
  final String route;
}
