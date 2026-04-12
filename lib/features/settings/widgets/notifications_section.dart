import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../router/route_names.dart';
import '../../notifications/providers/notification_settings_providers.dart';
import 'settings_navigation_tile.dart';
import 'settings_section_header.dart';
import 'settings_toggle_tile.dart';

class NotificationsSection extends ConsumerWidget {
  const NotificationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationToggleSettingsProvider);
    final settingsNotifier = ref.read(
      notificationToggleSettingsProvider.notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(
          title: 'settings.notifications'.tr(),
          icon: const AppIcon(AppIcons.notification),
        ),
        SettingsToggleTile(
          title: 'settings.notifications_master'.tr(),
          subtitle: 'settings.notifications_master_desc'.tr(),
          icon: const AppIcon(AppIcons.notification),
          value: settings.allEnabled,
          onChanged: (value) {
            settingsNotifier.setAll(value);
          },
        ),
        SettingsNavigationTile(
          title: 'settings.notification_categories'.tr(),
          subtitle: 'settings.notification_categories_desc'.tr(),
          icon: const AppIcon(AppIcons.filter),
          onTap: () => context.push(AppRoutes.notificationSettings),
        ),
      ],
    );
  }
}
