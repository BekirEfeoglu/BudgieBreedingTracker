part of 'admin_users_screen.dart';

class _UsersSummaryBar extends StatelessWidget {
  final int totalUsers;
  final int visibleUsers;
  final int activeUsers;
  final int inactiveUsers;

  const _UsersSummaryBar({
    required this.totalUsers,
    required this.visibleUsers,
    required this.activeUsers,
    required this.inactiveUsers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersLabel = visibleUsers == totalUsers
        ? '${'admin.total_users'.tr()}: $totalUsers'
        : '${'admin.users'.tr()}: $visibleUsers / $totalUsers';
    final activityLabel =
        '${'common.active'.tr()}: $activeUsers   ${'admin.inactive'.tr()}: $inactiveUsers';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          Text(
            usersLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            activityLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersList extends StatelessWidget {
  final List<AdminUser> users;
  final bool hasMore;
  final bool hasFilter;
  final Future<void> Function() onRefresh;
  final VoidCallback? onClearFilter;
  final VoidCallback? onLoadMore;

  const _UsersList({
    required this.users,
    required this.hasFilter,
    required this.onRefresh,
    this.hasMore = false,
    this.onClearFilter,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xxxl,
          ),
          children: [
            EmptyState(
              icon: const Icon(LucideIcons.userX),
              title: hasFilter
                  ? 'common.no_results'.tr()
                  : 'admin.no_users_found'.tr(),
              subtitle: hasFilter ? 'common.no_results_hint'.tr() : null,
              actionLabel: hasFilter ? 'admin.clear_filter'.tr() : null,
              onAction: hasFilter ? onClearFilter : null,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        itemCount: users.length + (hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == users.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(LucideIcons.chevronDown, size: 16),
                  label: Text('admin.load_more'.tr()),
                ),
              ),
            );
          }
          return _UserCard(user: users[index]);
        },
      ),
    );
  }
}
