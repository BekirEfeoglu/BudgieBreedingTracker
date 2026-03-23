part of 'admin_user_detail_content.dart';

/// Stats row showing bird count and log entries.
class UserDetailStatsRow extends StatelessWidget {
  final AdminUserDetail detail;
  const UserDetailStatsRow({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            icon: const AppIcon(AppIcons.bird),
            color: AppColors.budgieGreen,
            value: '${detail.birdsCount}',
            label: 'admin.birds'.tr(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatItem(
            icon: const AppIcon(AppIcons.audit),
            color: AppColors.info,
            value: '${detail.activityLogs.length}',
            label: 'admin.log_entries'.tr(),
          ),
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
