import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Reusable section header with title and "View All" button.
///
/// Used across dashboard sections (active breedings, recent chicks,
/// incubation summary) for consistent styling.
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const SectionHeader({super.key, required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: Text('common.view_all'.tr()),
          ),
      ],
    );
  }
}
