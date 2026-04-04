part of 'admin_user_detail_content.dart';

/// Stats grid showing all entity counts for a user.
class UserDetailStatsRow extends StatelessWidget {
  final AdminUserDetail detail;
  const UserDetailStatsRow({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admin.entity_summary'.tr(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: const AppIcon(AppIcons.bird),
                color: AppColors.budgieGreen,
                value: '${detail.birdsCount}',
                label: 'admin.birds'.tr(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatItem(
                icon: const AppIcon(AppIcons.breedingActive),
                color: AppColors.budgieYellow,
                value: '${detail.pairsCount}',
                label: 'admin.pairs_count'.tr(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatItem(
                icon: const AppIcon(AppIcons.egg),
                color: AppColors.info,
                value: '${detail.eggsCount}',
                label: 'admin.eggs_count'.tr(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: const AppIcon(AppIcons.chick),
                color: AppColors.accent,
                value: '${detail.chicksCount}',
                label: 'admin.chicks_count'.tr(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatItem(
                icon: const AppIcon(AppIcons.health),
                color: AppColors.error,
                value: '${detail.healthRecordsCount}',
                label: 'admin.health_records_count'.tr(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatItem(
                icon: const AppIcon(AppIcons.calendar),
                color: AppColors.primary,
                value: '${detail.eventsCount}',
                label: 'admin.events_count'.tr(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final Widget icon;
  final Color color;
  final String value;
  final String label;
  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            IconTheme(
              data: IconThemeData(color: color, size: 24),
              child: icon,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
