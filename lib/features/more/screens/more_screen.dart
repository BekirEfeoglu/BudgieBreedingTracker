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
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
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
        title: AppScreenTitle(title: 'nav.more'.tr(), iconAsset: AppIcons.more),
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
          // Features section
          _SectionHeader(title: 'more.section_features'.tr()),
          _MoreTile(
            icon: const AppIcon(AppIcons.chick),
            title: 'nav.chicks'.tr(),
            onTap: () => context.go(AppRoutes.chicks),
          ),
          _MoreTile(
            icon: const AppIcon(AppIcons.health),
            title: 'health_records.title'.tr(),
            onTap: () => context.push(AppRoutes.healthRecords),
          ),
          _MoreTile(
            icon: const AppIcon(AppIcons.community),
            title: 'more.community'.tr(),
            onTap: () => context.push(AppRoutes.community),
          ),
          // Premium features section
          _SectionHeader(title: 'more.section_premium'.tr()),
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
          // Subscription section
          _SectionHeader(title: 'more.section_subscription'.tr()),
          _MoreTile(
            icon: const AppIcon(AppIcons.premium),
            title: 'more.premium'.tr(),
            onTap: () => context.push(AppRoutes.premium),
          ),
          // Support section
          _SectionHeader(title: 'more.section_support'.tr()),
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
            onTap: () => context.push(AppRoutes.privacyPolicy),
          ),
          _MoreTile(
            icon: const Icon(LucideIcons.scale),
            title: 'settings.terms'.tr(),
            onTap: () => context.push(AppRoutes.termsOfService),
          ),
          // Settings section
          _SectionHeader(title: 'more.section_settings'.tr()),
          _MoreTile(
            icon: const AppIcon(AppIcons.settings),
            title: 'settings.title'.tr(),
            onTap: () => context.push(AppRoutes.settings),
          ),
          // Admin panel (only visible to admin users)
          if (ref.watch(isAdminProvider).value == true)
            _MoreTile(
              icon: const AppIcon(AppIcons.security),
              title: 'more.admin_panel'.tr(),
              onTap: () => context.push(AppRoutes.adminDashboard),
            ),
          // About (standalone, no section header)
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 88,
                  height: 88,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'more.about_app_name'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  version,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(LucideIcons.user, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'more.about_developer'.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                onTap: () => launchUrl(Uri.parse('mailto:support@budgiebreedingtracker.online')),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                  child: Row(
                    children: [
                      Icon(LucideIcons.mail, size: 16, color: colorScheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'support@budgiebreedingtracker.online',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                onTap: () => launchUrl(Uri.parse('https://budgiebreedingtracker.online/')),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                  child: Row(
                    children: [
                      Icon(LucideIcons.globe, size: 16, color: colorScheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'budgiebreedingtracker.online',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(LucideIcons.copyright, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'more.about_legalese'.tr(args: [year]),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        showLicensePage(
                          context: context,
                          applicationName: 'more.about_app_name'.tr(),
                          applicationVersion: version,
                          applicationIcon: Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: AppIcon(AppIcons.bird, size: 48, color: colorScheme.primary),
                          ),
                        );
                      },
                      child: Text('more.about_licenses'.tr()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text('common.close'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
        vertical: AppSpacing.sm,
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
            vertical: AppSpacing.xxs,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
