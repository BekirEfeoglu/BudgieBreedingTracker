import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_icon.dart';
import '../providers/settings_providers.dart';
import 'settings_section_header.dart';
import 'settings_selection_tile.dart';
import 'settings_toggle_tile.dart';

class DisplaySection extends ConsumerWidget {
  const DisplaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final compactView = ref.watch(compactViewProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(
          title: 'settings.display'.tr(),
          icon: const AppIcon(AppIcons.theme),
        ),
        SettingsSelectionTile<ThemeMode>(
          title: 'settings.theme'.tr(),
          icon: Icon(_themeIcon(themeMode)),
          currentValue: themeMode,
          options: [
            SettingsOption(
              value: ThemeMode.light,
              label: 'settings.theme_light'.tr(),
              icon: const Icon(LucideIcons.sun),
            ),
            SettingsOption(
              value: ThemeMode.dark,
              label: 'settings.theme_dark'.tr(),
              icon: const Icon(LucideIcons.moon),
            ),
            SettingsOption(
              value: ThemeMode.system,
              label: 'settings.theme_system'.tr(),
              icon: const Icon(LucideIcons.monitor),
            ),
          ],
          onChanged: (mode) {
            ref.read(themeModeProvider.notifier).setThemeMode(mode);
          },
        ),
        SettingsToggleTile(
          title: 'settings.compact_view'.tr(),
          subtitle: 'settings.compact_view_desc'.tr(),
          icon: const Icon(LucideIcons.layoutList),
          value: compactView,
          onChanged: (_) {
            ref.read(compactViewProvider.notifier).toggle();
          },
        ),
      ],
    );
  }

  IconData _themeIcon(ThemeMode mode) => switch (mode) {
        ThemeMode.light => LucideIcons.sun,
        ThemeMode.dark => LucideIcons.moon,
        ThemeMode.system => LucideIcons.monitor,
      };
}
