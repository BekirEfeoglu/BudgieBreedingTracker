part of 'profile_header.dart';

class _ProfileStatsRow extends StatelessWidget {
  const _ProfileStatsRow({required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _AnimatedStatItem(
            count: stats.totalBirds,
            label: 'profile.total_birds_stat'.tr(),
            color: theme.colorScheme.primary,
          ),
        ),
        Expanded(
          child: _AnimatedStatItem(
            count: stats.totalPairs,
            label: 'profile.total_pairs_stat'.tr(),
            color: AppColors.success,
          ),
        ),
        Expanded(
          child: _AnimatedStatItem(
            count: stats.totalEggs,
            label: 'profile.total_eggs_stat'.tr(),
            color: AppColors.info,
          ),
        ),
        Expanded(
          child: _AnimatedStatItem(
            count: stats.totalChicks,
            label: 'profile.total_chicks_stat'.tr(),
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _AnimatedStatItem extends StatelessWidget {
  const _AnimatedStatItem({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$label: $count',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: count),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (_, value, __) => Text(
              value.toString(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
