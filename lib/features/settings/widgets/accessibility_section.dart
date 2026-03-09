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

class AccessibilitySection extends ConsumerWidget {
  const AccessibilitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontScale = ref.watch(fontScaleProvider);
    final reduceAnimations = ref.watch(reduceAnimationsProvider);
    final hapticFeedback = ref.watch(hapticFeedbackProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(
          title: 'settings.accessibility'.tr(),
          icon: const Icon(LucideIcons.accessibility),
        ),
        SettingsSelectionTile<AppFontScale>(
          title: 'settings.font_size'.tr(),
          icon: const Icon(LucideIcons.type),
          currentValue: fontScale,
          options: AppFontScale.values.map((scale) {
            return SettingsOption(
              value: scale,
              label: scale.labelKey.tr(),
              subtitle: 'settings.font_preview'.tr(),
            );
          }).toList(),
          onChanged: (scale) {
            ref.read(fontScaleProvider.notifier).setScale(scale);
          },
        ),
        SettingsToggleTile(
          title: 'settings.reduce_animations'.tr(),
          subtitle: 'settings.reduce_animations_desc'.tr(),
          icon: const Icon(LucideIcons.zap),
          value: reduceAnimations,
          onChanged: (_) {
            ref.read(reduceAnimationsProvider.notifier).toggle();
          },
        ),
        SettingsToggleTile(
          title: 'settings.haptic_feedback'.tr(),
          subtitle: 'settings.haptic_feedback_desc'.tr(),
          icon: const AppIcon(AppIcons.haptic),
          value: hapticFeedback,
          onChanged: (_) {
            ref.read(hapticFeedbackProvider.notifier).toggle();
          },
        ),
      ],
    );
  }
}
