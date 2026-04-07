import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../router/route_names.dart';
import '../constants/admin_constants.dart';

/// Responsive grid of 4 quick action chips for the admin dashboard.
class DashboardQuickActionsSection extends StatelessWidget {
  const DashboardQuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admin.quick_actions'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > AdminConstants.gridColumnBreakpoint ? 4 : 2;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: constraints.maxWidth > AdminConstants.gridColumnBreakpoint ? 3.5 : 2.8,
              children: [
                _QuickActionChip(
                  icon: AppIcon(AppIcons.users, semanticsLabel: 'admin.go_to_users'.tr()),
                  label: 'admin.go_to_users'.tr(),
                  onTap: () => context.go(AppRoutes.adminUsers),
                ),
                _QuickActionChip(
                  icon: AppIcon(AppIcons.monitoring, semanticsLabel: 'admin.go_to_monitoring'.tr()),
                  label: 'admin.go_to_monitoring'.tr(),
                  onTap: () => context.go(AppRoutes.adminMonitoring),
                ),
                _QuickActionChip(
                  icon: AppIcon(AppIcons.database, semanticsLabel: 'admin.go_to_database'.tr()),
                  label: 'admin.go_to_database'.tr(),
                  onTap: () => context.go(AppRoutes.adminDatabase),
                ),
                _QuickActionChip(
                  icon: AppIcon(AppIcons.settings, semanticsLabel: 'admin.go_to_settings'.tr()),
                  label: 'admin.go_to_settings'.tr(),
                  onTap: () => context.go(AppRoutes.adminSettings),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconTheme(
                data: IconThemeData(
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                child: icon,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
