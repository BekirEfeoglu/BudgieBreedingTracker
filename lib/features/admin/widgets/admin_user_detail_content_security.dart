part of 'admin_user_detail_content.dart';

class UserDetailSecuritySection extends ConsumerWidget {
  final String userId;

  const UserDetailSecuritySection({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final eventsAsync = ref.watch(adminUserSecurityEventsProvider(userId));

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.shieldCheck, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'admin.security_and_audit'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _handleForceLogout(context, ref),
                icon: const Icon(LucideIcons.logOut, size: 18),
                label: Text('admin.force_logout'.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'admin.security_events'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            eventsAsync.when(
              loading: () => const LoadingState(),
              error: (e, _) => Text('common.data_load_error'.tr()),
              data: (events) {
                if (events.isEmpty) {
                  return Text(
                    'admin.no_security_events'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                }
                return Column(
                  children: events.take(5).map((event) => _buildEventItem(context, event)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem(BuildContext context, SecurityEvent event) {
    final theme = Theme.of(context);
    final color = switch (event.severity) {
      SecuritySeverityLevel.high => AppColors.error,
      SecuritySeverityLevel.medium => AppColors.warning,
      SecuritySeverityLevel.low || SecuritySeverityLevel.unknown => AppColors.neutral400,
    };
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin.security_event_${event.eventType.name}'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (event.details != null && event.details!.isNotEmpty)
                  Text(
                    event.details!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                Text(
                  DateFormat('dd MMM yyyy HH:mm').format(event.createdAt.toLocal()),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleForceLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.confirm_force_logout'.tr(),
      message: 'admin.confirm_force_logout_desc'.tr(),
      isDestructive: true,
    );
    if (confirmed != true) return;
    
    // Await execution
    await ref.read(adminActionsProvider.notifier).forceLogout(userId);
  }
}
