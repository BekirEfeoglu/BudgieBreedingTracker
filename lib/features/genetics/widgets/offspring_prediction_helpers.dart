part of 'offspring_prediction.dart';

/// Shows probability as circular indicator for normal values,
/// or as a compact text badge for very low probabilities (<1%).
class _ProbabilityIndicator extends StatelessWidget {
  final double probability;
  final String percentage;
  final ThemeData theme;

  const _ProbabilityIndicator({
    required this.probability,
    required this.percentage,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (probability < _kLowProbabilityThreshold && probability > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Text(
          '%$percentage',
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return SizedBox(
      width: _kProgressSize,
      height: _kProgressSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: probability,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: theme.colorScheme.primary,
            strokeWidth: 5,
          ),
          Text(
            '%$percentage',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsed carrier mutations as individual mini chips for visual distinction.
///
/// Each mutation gets its own chip, making it easier to spot differences
/// between cards. Shows first [_kMaxVisibleMutations] chips + overflow badge.
class _CarrierMutationsSummary extends StatelessWidget {
  final List<String> mutations;
  final ThemeData theme;

  const _CarrierMutationsSummary({
    required this.mutations,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final visible = mutations.take(_kMaxVisibleMutations).toList();
    final remaining = mutations.length - _kMaxVisibleMutations;
    final warningColor = AppColors.warningTextAdaptive(context);

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      children: [
        for (final mutation in visible)
          _MutationChip(label: mutation, color: warningColor, theme: theme),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              'genetics.and_n_more'.tr(args: [remaining.toString()]),
              style: theme.textTheme.bodySmall?.copyWith(
                color: warningColor,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
      ],
    );
  }
}

/// Individual carrier mutation chip with subtle background.
class _MutationChip extends StatelessWidget {
  final String label;
  final Color color;
  final ThemeData theme;

  const _MutationChip({
    required this.label,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 1,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontStyle: FontStyle.italic,
          fontSize: 9,
        ),
      ),
    );
  }
}
