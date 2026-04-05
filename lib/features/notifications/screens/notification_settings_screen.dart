import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_permission_handler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_settings_providers.dart';

part 'notification_settings_dnd.dart';

class _BatteryWarningDismissedNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Load persisted dismissed state asynchronously on first build.
    _loadPersistedState();
    return false;
  }

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed =
        prefs.getBool(AppPreferences.keyBatteryWarningDismissed) ?? false;
    if (dismissed && !state) {
      state = true;
    }
  }
}

final _batteryWarningDismissedProvider =
    NotifierProvider<_BatteryWarningDismissedNotifier, bool>(
      _BatteryWarningDismissedNotifier.new,
    );

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
    final batteryWarningDismissed = ref.watch(_batteryWarningDismissedProvider);

    return Scaffold(
      appBar: AppBar(
        title: AppScreenTitle(
          title: 'notifications.title'.tr(),
          iconAsset: AppIcons.notification,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          const _NotificationPermissionBanner(),
          _BatteryOptimizationBanner(
            isDismissed: batteryWarningDismissed,
            onDismiss: () async {
              ref.read(_batteryWarningDismissedProvider.notifier).state = true;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(
                AppPreferences.keyBatteryWarningDismissed,
                true,
              );
            },
          ),
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
          _NotificationToggle(
            icon: const AppIcon(AppIcons.ring),
            title: 'notifications.banding'.tr(),
            subtitle: 'notifications.banding_desc'.tr(),
            value: settings.banding,
            onChanged: notifier.setBanding,
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
  const _CleanupSection({required this.daysOld, required this.onChanged});

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
                    label: Text('notifications.cleanup_days'.tr(args: ['$d'])),
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

/// Warning banner for Android battery optimization.
///
/// Shown at the top of notification settings to advise disabling
/// battery optimization for reliable notification delivery.
class _BatteryOptimizationBanner extends ConsumerStatefulWidget {
  const _BatteryOptimizationBanner({
    required this.isDismissed,
    this.onDismiss,
  });

  final bool isDismissed;
  final VoidCallback? onDismiss;

  @override
  ConsumerState<_BatteryOptimizationBanner> createState() =>
      _BatteryOptimizationBannerState();
}

class _BatteryOptimizationBannerState
    extends ConsumerState<_BatteryOptimizationBanner> {
  String _oemSteps = '';

  @override
  void initState() {
    super.initState();
    _loadOemSteps();
  }

  Future<void> _loadOemSteps() async {
    final manufacturer =
        await NotificationPermissionHandler.getDeviceManufacturer();
    if (!mounted) return;
    final steps = _oemBatterySteps(manufacturer);
    if (steps.isNotEmpty) {
      setState(() => _oemSteps = steps);
    }
  }

  String _oemBatterySteps(String manufacturer) {
    return switch (manufacturer) {
      'samsung' => 'notifications.battery_steps_samsung'.tr(),
      'xiaomi' || 'redmi' || 'poco' => 'notifications.battery_steps_xiaomi'
          .tr(),
      'huawei' || 'honor' => 'notifications.battery_steps_huawei'.tr(),
      'oppo' || 'realme' || 'oneplus' => 'notifications.battery_steps_oppo'
          .tr(),
      'vivo' || 'iqoo' => 'notifications.battery_steps_vivo'.tr(),
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDismissed || !Platform.isAndroid) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.batteryWarning,
                color: theme.colorScheme.onErrorContainer,
                size: AppSpacing.xxl,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'notifications.battery_optimization_warning'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'notifications.battery_optimization_steps'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
            ),
          ),
          if (_oemSteps.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _oemSteps,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onDismiss,
                child: Text(
                  'notifications.battery_optimization_dismiss'.tr(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.tonalIcon(
                onPressed: () {
                  ref
                      .read(notificationServiceProvider)
                      .requestBatteryOptimizationExemptionIfNeeded();
                },
                icon: const Icon(LucideIcons.settings, size: 16),
                label: Text('notifications.battery_open_settings'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Warning banner shown when notification permission is denied.
///
/// Guides the user to open system notification settings to grant permission.
/// Only visible on Android when [notificationPermissionGrantedProvider] is false.
/// Automatically re-checks permission status when the user returns from
/// system settings (via [WidgetsBindingObserver.didChangeAppLifecycleState]).
class _NotificationPermissionBanner extends ConsumerStatefulWidget {
  const _NotificationPermissionBanner();

  @override
  ConsumerState<_NotificationPermissionBanner> createState() =>
      _NotificationPermissionBannerState();
}

class _NotificationPermissionBannerState
    extends ConsumerState<_NotificationPermissionBanner>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      _recheckPermission();
    }
  }

  Future<void> _recheckPermission() async {
    final notifService = ref.read(notificationServiceProvider);
    if (!notifService.isInitialized) return;

    final enabled = await notifService.areNotificationsEnabled();
    if (!mounted) return;

    final wasDisabled =
        ref.read(notificationPermissionGrantedProvider) == false;
    ref.read(notificationPermissionGrantedProvider.notifier).state = enabled;

    // Permission was just granted from settings — reschedule notifications.
    if (enabled && wasDisabled) {
      final userId = ref.read(currentUserIdProvider);
      if (userId != 'anonymous') {
        try {
          await ref.read(notificationReschedulerProvider).rescheduleAll(userId);
        } catch (e) {
          AppLogger.warning(
            '[NotificationSettings] Reschedule after permission grant '
            'failed: $e',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) return const SizedBox.shrink();

    final granted = ref.watch(notificationPermissionGrantedProvider);
    if (granted) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.bellOff,
                color: theme.colorScheme.onErrorContainer,
                size: AppSpacing.xxl,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'notifications.permission_denied_banner'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'notifications.permission_denied_banner_desc'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: () {
                NotificationPermissionHandler.openNotificationSettings();
              },
              icon: const Icon(LucideIcons.settings, size: 16),
              label: Text('notifications.open_settings'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}

// _DndSection and _DndTimeTile are in the part file:
// notification_settings_dnd.dart
