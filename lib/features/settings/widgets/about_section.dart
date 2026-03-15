import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../router/route_names.dart';
import '../providers/settings_providers.dart';
import 'settings_action_tile.dart';
import 'settings_navigation_tile.dart';
import 'settings_section_header.dart';

class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInfoAsync = ref.watch(appInfoProvider);

    final versionText = appInfoAsync.when(
      data: (info) => 'v${info.version} (${info.buildNumber})',
      loading: () => '...',
      error: (_, __) => '-',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(
          title: 'settings.about'.tr(),
          icon: const AppIcon(AppIcons.info),
        ),
        SettingsActionTile(
          title: 'settings.version'.tr(),
          subtitle: versionText,
          icon: const AppIcon(AppIcons.info),
          onTap: () {},
        ),
        SettingsNavigationTile(
          title: 'settings.whats_new'.tr(),
          subtitle: 'settings.whats_new_desc'.tr(),
          icon: const AppIcon(AppIcons.premium),
          onTap: () => _showChangelogDialog(context),
        ),
        SettingsActionTile(
          title: 'settings.rate_app'.tr(),
          subtitle: 'settings.rate_app_desc'.tr(),
          icon: const Icon(LucideIcons.star),
          onTap: () async {
            final storeUrl = Theme.of(context).platform == TargetPlatform.iOS
                ? AppConstants.appStoreUrl
                : AppConstants.playStoreUrl;
            final uri = Uri.parse(storeUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
        SettingsNavigationTile(
          title: 'settings.open_source_licenses'.tr(),
          icon: const Icon(LucideIcons.fileCode),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'more.about_app_name'.tr(),
          ),
        ),
        SettingsActionTile(
          title: 'settings.share_app'.tr(),
          subtitle: 'settings.share_app_desc'.tr(),
          icon: const AppIcon(AppIcons.share),
          onTap: () {
            SharePlus.instance.share(
              ShareParams(text: 'settings.share_message'.tr()),
            );
          },
        ),
        SettingsNavigationTile(
          title: 'settings.contact_support'.tr(),
          icon: const Icon(LucideIcons.messageCircle),
          onTap: () async {
            final uri = Uri.tryParse(AppConstants.supportUrl);
            if (uri != null) {
              try {
                final launched = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (launched) return;
              } catch (_) {
                // Fallback to in-app feedback if URL launch fails.
              }
            }
            if (context.mounted) {
              context.push(AppRoutes.feedback);
            }
          },
        ),
      ],
    );
  }

  void _showChangelogDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('settings.whats_new'.tr()),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              // Add new version entries at the top
              _ChangelogEntry(
                version: 'v1.0.0',
                date: 'settings.changelog_latest'.tr(),
                sections: [
                  _ChangelogSection(
                    title: 'settings.changelog_category_features'.tr(),
                    items: [
                      'settings.changelog_initial'.tr(),
                      'settings.changelog_dashboard'.tr(),
                      'settings.changelog_genealogy'.tr(),
                      'settings.changelog_genetics'.tr(),
                      'settings.changelog_history'.tr(),
                      'settings.changelog_missing_features'.tr(),
                      'settings.changelog_notification'.tr(),
                      'settings.changelog_integration'.tr(),
                      'settings.changelog_export'.tr(),
                    ],
                  ),
                  _ChangelogSection(
                    title: 'settings.changelog_category_improvements'.tr(),
                    items: [
                      'settings.changelog_localization'.tr(),
                      'settings.changelog_icons'.tr(),
                      'settings.changelog_settings'.tr(),
                      'settings.changelog_accessibility'.tr(),
                      'settings.changelog_performance'.tr(),
                    ],
                  ),
                ],
                theme: theme,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }
}

class _ChangelogSection {
  final String title;
  final List<String> items;
  const _ChangelogSection({required this.title, required this.items});
}

class _ChangelogEntry extends StatelessWidget {
  const _ChangelogEntry({
    required this.version,
    required this.sections,
    required this.theme,
    this.date,
  });

  final String version;
  final String? date;
  final List<_ChangelogSection> sections;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                version,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (date != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                date!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (final section in sections) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              section.title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...section.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('  \u2022  ', style: theme.textTheme.bodySmall),
                  Expanded(child: Text(item, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}
