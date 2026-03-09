import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_icon.dart';
import '../providers/settings_providers.dart';
import 'settings_section_header.dart';
import 'settings_selection_tile.dart';

class LanguageSection extends ConsumerWidget {
  const LanguageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(appLocaleProvider);
    final currentDateFormat = ref.watch(dateFormatProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(
          title: 'settings.language_region'.tr(),
          icon: const AppIcon(AppIcons.language),
        ),
        SettingsSelectionTile<AppLocale>(
          title: 'settings.language'.tr(),
          icon: const AppIcon(AppIcons.language),
          currentValue: currentLocale,
          options: AppLocale.values.map((locale) {
            return SettingsOption(
              value: locale,
              label: locale.nativeLabel,
              subtitle: locale.labelKey.tr(),
            );
          }).toList(),
          onChanged: (locale) {
            ref
                .read(appLocaleProvider.notifier)
                .setLocale(locale, context);
          },
        ),
        SettingsSelectionTile<AppDateFormat>(
          title: 'settings.date_format'.tr(),
          icon: const AppIcon(AppIcons.calendar),
          currentValue: currentDateFormat,
          options: AppDateFormat.values.map((format) {
            return SettingsOption(
              value: format,
              label: format.label,
            );
          }).toList(),
          onChanged: (format) {
            ref.read(dateFormatProvider.notifier).setFormat(format);
          },
        ),
      ],
    );
  }
}
