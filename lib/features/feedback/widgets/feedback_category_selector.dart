import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/feedback/providers/feedback_providers.dart';

// ---------------------------------------------------------------------------
// Category selector
// ---------------------------------------------------------------------------

/// Visual category selector with colored cards.
class FeedbackCategorySelector extends StatelessWidget {
  final FeedbackCategory selected;
  final ValueChanged<FeedbackCategory> onChanged;

  const FeedbackCategorySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: FeedbackCategory.values.map((cat) {
        final isSelected = cat == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: cat != FeedbackCategory.general ? AppSpacing.sm : 0,
            ),
            child: _CategoryCard(
              category: cat,
              isSelected: isSelected,
              onTap: () => onChanged(cat),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final FeedbackCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catColor = category.color;

    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? catColor.withValues(alpha: 0.12)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(
          color: isSelected ? catColor : Colors.transparent,
          width: isSelected ? 1.5 : 0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.icon,
                size: 24,
                color: isSelected
                    ? catColor
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                category.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? catColor
                      : theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs / 2),
              Text(
                category.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
