import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({super.key, required this.title, this.icon});

  final String title;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(size: 18, color: color),
              child: icon!,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
