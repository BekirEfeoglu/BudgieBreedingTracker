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
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_settings_providers.dart';

part 'notification_settings_banners.dart';
part 'notification_settings_dnd.dart';
part 'notification_settings_widgets.dart';

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
