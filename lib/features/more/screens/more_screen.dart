import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import '../../../router/route_names.dart';
import 'package:budgie_breeding_tracker/features/notifications/widgets/notification_bell_button.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_menu_button.dart';
import '../../admin/providers/admin_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../settings/providers/settings_providers.dart';

/// Hub screen accessible via the "More" bottom-nav tab.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = ref.watch(currentUserIdProvider);
    final isGuest = userId == 'anonymous';

    return Scaffold(
      appBar: AppBar(
        title: Text('nav.more'.tr()),
        actions: isGuest
            ? [
                TextButton(
                  onPressed: () => context.push(AppRoutes.login),
                  child: Text('auth.login'.tr()),
                ),
              ]
            : const [NotificationBellButton(), ProfileMenuButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          // Core features promoted from bottom nav
          _MoreTile(
            icon: const AppIcon(AppIcons.chick),
            title: 'nav.chicks'.tr(),
            onTap: () => context.go(AppRoutes.chicks),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Health records
          _MoreTile(
            icon: const AppIcon(AppIcons.health),
            title: 'health_records.title'.tr(),
            onTap: () => context.push(AppRoutes.healthRecords),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Premium features
          _MoreTile(
            icon: const AppIcon(AppIcons.statistics),
            title: 'more.statistics'.tr(),
            trailing: _PremiumBadge(theme: theme),
            onTap: () => context.push(AppRoutes.statistics),
          ),
          _MoreTile(
            icon: const AppIcon(AppIcons.genealogy),
            title: 'more.genealogy'.tr(),
            trailing: _PremiumBadge(theme: theme),
            onTap: () => context.push(AppRoutes.genealogy),
          ),
          _MoreTile(
            icon: const AppIcon(AppIcons.dna),
            title: 'more.genetics'.tr(),
            trailing: _PremiumBadge(theme: theme),
            onTap: () => context.push(AppRoutes.genetics),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Premium
          _MoreTile(
            icon: const AppIcon(AppIcons.premium),
            title: 'more.premium'.tr(),
            onTap: () => context.push(AppRoutes.premium),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Help & Support
          _MoreTile(
            icon: const AppIcon(AppIcons.guide),
            title: 'more.user_guide'.tr(),
            onTap: () => context.push(AppRoutes.userGuide),
          ),
          _MoreTile(
            icon: const Icon(LucideIcons.messageSquare),
            title: 'more.feedback'.tr(),
            onTap: () => context.push(AppRoutes.feedback),
          ),
          _MoreTile(
            icon: const Icon(LucideIcons.fileText),
            title: 'settings.privacy_policy'.tr(),
            trailing: const Icon(LucideIcons.externalLink, size: 18),
            onTap: () => _openExternal(
              'https://budgiebreedingtracker.online/privacy-policy.html',
            ),
          ),
          _MoreTile(
            icon: const Icon(LucideIcons.scale),
            title: 'settings.terms'.tr(),
            trailing: const Icon(LucideIcons.externalLink, size: 18),
            onTap: () => _openExternal(
              'https://budgiebreedingtracker.online/terms-of-service.html',
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Settings
          _MoreTile(
            icon: const AppIcon(AppIcons.settings),
            title: 'settings.title'.tr(),
            onTap: () => context.push(AppRoutes.settings),
          ),
          // Admin panel (only visible to admin users)
          if (ref.watch(isAdminProvider).value == true) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            _MoreTile(
              icon: const AppIcon(AppIcons.security),
              title: 'more.admin_panel'.tr(),
              onTap: () => context.push(AppRoutes.adminDashboard),
            ),
          ],
          const Divider(height: 1, indent: 16, endIndent: 16),
          _MoreTile(
            icon: const AppIcon(AppIcons.info),
            title: 'more.about'.tr(),
            onTap: () => _showAboutDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, WidgetRef ref) {
    final year = DateTime.now().year.toString();
    final appInfo = ref.read(appInfoProvider);
    final version = appInfo.when(
      data: (info) => 'v${info.version}',
      loading: () => 'v1.0.0',
      error: (_, __) => 'v1.0.0',
    );
    showAboutDialog(
      context: context,
      applicationName: 'more.about_app_name'.tr(),
      applicationVersion: version,
      applicationLegalese: 'more.about_legalese'.tr(args: [year]),
      applicationIcon: const AppIcon(AppIcons.bird, size: 48),
    );
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final Widget icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: IconTheme(
        data: IconThemeData(color: theme.colorScheme.primary, size: 24),
        child: icon,
      ),
      title: Text(title),
      trailing: trailing ?? const Icon(LucideIcons.chevronRight, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Text(
            'premium.pro_badge'.tr(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.premiumGoldDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        const Icon(LucideIcons.chevronRight, size: 18),
      ],
    );
  }
}
