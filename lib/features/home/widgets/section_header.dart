import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

/// Reusable section header with title and "View All" button.
///
/// Used across dashboard sections (active breedings, recent chicks,
/// incubation summary) for consistent styling.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? icon;
  final VoidCallback? onViewAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              if (icon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  child: icon!,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (onViewAll != null)
          TextButton(onPressed: onViewAll, child: Text('common.view_all'.tr())),
      ],
    );
  }
}
