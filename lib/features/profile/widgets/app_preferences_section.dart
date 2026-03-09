import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../router/route_names.dart';
import '../../settings/providers/settings_providers.dart';
import 'profile_menu_tile.dart';
import 'sync_status_tile.dart';

/// App preferences section with theme, sync, notifications, backup,
/// premium, and language.
class AppPreferencesSection extends ConsumerWidget {
  const AppPreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(appLocaleProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // Theme mode toggle
          const _ThemeModeTile(),
          const Divider(
              height: 1, indent: AppSpacing.lg + 24 + AppSpacing.md),

          // Sync status
          const SyncStatusTile(),
          const Divider(
              height: 1, indent: AppSpacing.lg + 24 + AppSpacing.md),

          // Notifications
          ProfileMenuTile(
            icon: const AppIcon(AppIcons.notification, size: 22),
            label: 'profile.notifications'.tr(),
            onTap: () => context.push(AppRoutes.notificationSettings),
          ),
          const Divider(
              height: 1, indent: AppSpacing.lg + 24 + AppSpacing.md),

          // Backup & Export
          ProfileMenuTile(
            icon: const AppIcon(AppIcons.backup, size: 22),
            label: 'profile.backup_export'.tr(),
            onTap: () => context.push(AppRoutes.backup),
          ),
          const Divider(
              height: 1, indent: AppSpacing.lg + 24 + AppSpacing.md),

          // Premium
          ProfileMenuTile(
            icon: const AppIcon(AppIcons.premium, size: 22),
            label: 'profile.premium_membership'.tr(),
            onTap: () => context.push(AppRoutes.premium),
          ),
          const Divider(
              height: 1, indent: AppSpacing.lg + 24 + AppSpacing.md),

          // Language
          _LanguageTile(currentLocale: currentLocale),
        ],
      ),
    );
  }
}

// -- Theme Mode Toggle --

class _ThemeModeTile extends ConsumerWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTheme(
                data: IconThemeData(
                    size: 22, color: theme.colorScheme.onSurface),
                child: const AppIcon(AppIcons.theme),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('profile.theme_mode'.tr(),
                  style: theme.textTheme.bodyLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('profile.theme_light'.tr()),
                  icon: const Icon(LucideIcons.sun, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('profile.theme_system'.tr()),
                  icon: const Icon(LucideIcons.monitor, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('profile.theme_dark'.tr()),
                  icon: const Icon(LucideIcons.moon, size: 16),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) {
                HapticFeedback.lightImpact();
                ref.read(themeModeProvider.notifier).setThemeMode(s.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -- Language Tile --

class _LanguageTile extends ConsumerWidget {
  const _LanguageTile({required this.currentLocale});

  final AppLocale currentLocale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _showLanguagePicker(context, ref),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        child: Row(
          children: [
            IconTheme(
              data: IconThemeData(
                  size: 22, color: theme.colorScheme.onSurface),
              child: const AppIcon(AppIcons.language),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'profile.language'.tr(),
                style: theme.textTheme.bodyLarge,
              ),
            ),
            Text(
              currentLocale.nativeLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) => _LanguagePickerSheet(
        currentLocale: currentLocale,
        onSelect: (locale) {
          HapticFeedback.lightImpact();
          Navigator.of(ctx).pop();
          ref
              .read(appLocaleProvider.notifier)
              .setLocale(locale, context);
        },
      ),
    );
  }
}

class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet({
    required this.currentLocale,
    required this.onSelect,
  });

  final AppLocale currentLocale;
  final ValueChanged<AppLocale> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'profile.language'.tr(),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final locale in AppLocale.values)
              ListTile(
                leading: Icon(
                  currentLocale == locale
                      ? LucideIcons.checkCircle2
                      : LucideIcons.circle,
                  color: currentLocale == locale
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(locale.nativeLabel),
                subtitle: Text(locale.labelKey.tr()),
                onTap: () => onSelect(locale),
              ),
          ],
        ),
      ),
    );
  }
}
