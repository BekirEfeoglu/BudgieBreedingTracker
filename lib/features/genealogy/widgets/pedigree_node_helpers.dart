part of 'pedigree_node.dart';

extension _PedigreeNodeHelpers on PedigreeNode {
  Widget buildEmptyNode(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: PedigreeNode._normalWidth,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral800 : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.neutral600 : AppColors.neutral300,
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.userPlus,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            placeholder,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildMutationChip(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _nodePaddingH,
        vertical: _nodePaddingV,
      ),
      decoration: BoxDecoration(
        color: _genderBorderColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        birdColorLabel(bird!.colorMutation!),
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 9,
          color: _genderBorderColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
