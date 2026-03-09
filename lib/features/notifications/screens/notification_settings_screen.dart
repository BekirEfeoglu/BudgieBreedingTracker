import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_settings_providers.dart';

part 'notification_settings_dnd.dart';

/// Screen for managing notification preferences.
///
/// Provides toggles for egg turning, incubation, chick care,
/// and health check notification categories, plus Do Not Disturb
/// hour configuration. All changes are persisted immediately.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationToggleSettingsProvider);
    final notifier = ref.read(notificationToggleSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('notifications.title'.tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
        ),
        children: [
          const _NotificationHeader(),
          const Divider(),
          _NotificationToggle(
            icon: Icon(
              LucideIcons.volume2,
              color: settings.soundEnabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: 'notifications.sound'.tr(),
            subtitle: 'notifications.sound_desc'.tr(),
            value: settings.soundEnabled,
            onChanged: notifier.setSound,
          ),
          _NotificationToggle(
            icon: Icon(
              LucideIcons.vibrate,
              color: settings.vibrationEnabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: 'notifications.vibration'.tr(),
            subtitle: 'notifications.vibration_desc'.tr(),
            value: settings.vibrationEnabled,
            onChanged: notifier.setVibration,
          ),
          const Divider(height: AppSpacing.xxxl),
          _NotificationToggle(
            icon: const AppIcon(AppIcons.notification),
            title: 'notifications.master_toggle'.tr(),
            subtitle: 'notifications.master_toggle_desc'.tr(),
            value: settings.allEnabled,
            onChanged: notifier.setAll,
          ),
          const SizedBox(height: AppSpacing.sm),
          _NotificationToggle(
            icon: const AppIcon(AppIcons.sync),
            title: 'notifications.egg_turning'.tr(),
            subtitle: 'notifications.egg_turning_desc'.tr(),
            value: settings.eggTurning,
            onChanged: notifier.setEggTurning,
          ),
          _NotificationToggle(
            icon: const AppIcon(AppIcons.incubation),
            title: 'notifications.incubation'.tr(),
            subtitle: 'notifications.incubation_desc'.tr(),
            value: settings.incubation,
            onChanged: notifier.setIncubation,
          ),
          _NotificationToggle(
            icon: const AppIcon(AppIcons.chick),
            title: 'notifications.chick_care'.tr(),
            subtitle: 'notifications.chick_care_desc'.tr(),
            value: settings.chickCare,
            onChanged: notifier.setChickCare,
          ),
          _NotificationToggle(
            icon: const AppIcon(AppIcons.health),
            title: 'notifications.health_check'.tr(),
            subtitle: 'notifications.health_check_desc'.tr(),
            value: settings.healthCheck,
            onChanged: notifier.setHealthCheck,
          ),
          const Divider(height: AppSpacing.xxxl),
          _CleanupSection(
            daysOld: settings.cleanupDaysOld,
            onChanged: notifier.setCleanupDaysOld,
          ),
          const Divider(height: AppSpacing.xxxl),
          const _DndSection(),
        ],
      ),
    );
  }
}

class _NotificationHeader extends StatelessWidget {
  const _NotificationHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          AppIcon(
            AppIcons.notification,
            size: AppSpacing.xxl,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'notifications.settings_description'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable toggle row for a notification category.
class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SwitchListTile(
      secondary: IconTheme(
        data: IconThemeData(
          color: value
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        child: icon,
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      value: value,
      onChanged: (newValue) => onChanged(newValue),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
    );
  }
}

/// Cleanup duration configuration section.
class _CleanupSection extends StatelessWidget {
  const _CleanupSection({
    required this.daysOld,
    required this.onChanged,
  });

  final int daysOld;
  final Future<void> Function(int) onChanged;

  static const _options = [7, 14, 30, 60, 90];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.trash2,
                size: AppSpacing.xxl,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'notifications.cleanup_title'.tr(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'notifications.cleanup_description'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SegmentedButton<int>(
            segments: _options
                .map(
                  (d) => ButtonSegment<int>(
                    value: d,
                    label: Text(
                      'notifications.cleanup_days'.tr(args: ['$d']),
                    ),
                  ),
                )
                .toList(),
            selected: {daysOld},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) onChanged(selection.first);
            },
          ),
        ),
      ],
    );
  }
}

// _DndSection and _DndTimeTile are in the part file:
// notification_settings_dnd.dart
