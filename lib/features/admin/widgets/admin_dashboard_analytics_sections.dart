part of 'admin_dashboard_content.dart';

/// System health banner showing real Edge Function health status.
/// Expandable to show individual service checks and latency details.
class DashboardSystemHealthBanner extends ConsumerStatefulWidget {
  final AdminStats stats;

  const DashboardSystemHealthBanner({super.key, required this.stats});

  @override
  ConsumerState<DashboardSystemHealthBanner> createState() =>
      _DashboardSystemHealthBannerState();
}

class _DashboardSystemHealthBannerState
    extends ConsumerState<DashboardSystemHealthBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final healthAsync = ref.watch(systemHealthProvider);

    final isLoading = healthAsync.isLoading;
    final status = healthAsync.whenOrNull(
      data: (data) => data['status'] as String?,
    );
    final isUnavailable = status == 'unavailable';

    final isHealthy = healthAsync.maybeWhen(
      data: (data) =>
          data['status'] != 'error' && data['status'] != 'unavailable',
      orElse: () => true,
    );
    final errorMsg = healthAsync.whenOrNull(
      data: (data) =>
          data['status'] == 'error' ? data['message'] as String? : null,
      error: (e, _) => e.toString(),
    );

    final Color color;
    final String title;
    final String subtitle;

    if (isLoading) {
      color = AppColors.info;
      title = 'admin.checking_health'.tr();
      subtitle = 'admin.all_services_running'.tr();
    } else if (isUnavailable) {
      color = theme.colorScheme.outlineVariant;
      title = 'admin.health_unavailable'.tr();
      subtitle = 'admin.health_unavailable_desc'.tr();
    } else if (isHealthy) {
      color = AppColors.success;
      title = 'admin.system_healthy'.tr();
      subtitle = errorMsg ?? 'admin.all_services_running'.tr();
    } else {
      color = AppColors.warning;
      title = 'admin.system_degraded'.tr();
      subtitle = errorMsg ?? 'admin.all_services_running'.tr();
    }

    // Extract service check details for expanded view
    final checks = healthAsync.whenOrNull(
      data: (data) => data['checks'] as Map<String, dynamic>?,
    );
    final latency = healthAsync.whenOrNull(
      data: (data) => data['latency'] as Map<String, dynamic>?,
    );

    return GestureDetector(
      onTap: checks != null
          ? () => setState(() => _expanded = !_expanded)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isLoading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                else
                  AppIcon(AppIcons.health, color: color, semanticsLabel: title),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (checks != null)
                  Icon(
                    _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
            if (_expanded && checks != null) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              _ServiceCheckRow(
                label: 'admin.service_database'.tr(),
                status: checks['database'] as String? ?? 'unknown',
                latencyMs: latency?['database_ms'] as int?,
              ),
              _ServiceCheckRow(
                label: 'admin.service_auth'.tr(),
                status: checks['auth'] as String? ?? 'unknown',
                latencyMs: latency?['auth_ms'] as int?,
              ),
              _ServiceCheckRow(
                label: 'admin.service_storage'.tr(),
                status: checks['storage'] as String? ?? 'unknown',
                latencyMs: latency?['storage_ms'] as int?,
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  children: [
                    if (latency?['total_ms'] != null)
                      Expanded(
                        child: Text(
                          '${'admin.total_latency'.tr()}: ${latency!['total_ms']}ms',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    SizedBox(
                      height: AppSpacing.touchTargetMin,
                      child: TextButton.icon(
                        onPressed: () => ref.invalidate(systemHealthProvider),
                        icon: const Icon(LucideIcons.refreshCw, size: 14),
                        label: Text('admin.refresh_health'.tr()),
                        style: TextButton.styleFrom(
                          textStyle: theme.textTheme.bodySmall,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single row showing a service's health check status and latency.
class _ServiceCheckRow extends StatelessWidget {
  final String label;
  final String status;
  final int? latencyMs;

  const _ServiceCheckRow({
    required this.label,
    required this.status,
    this.latencyMs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOk = status == 'ok';
    final statusColor = isOk ? AppColors.success : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            isOk ? LucideIcons.checkCircle : LucideIcons.alertCircle,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
          if (latencyMs != null)
            Text(
              '${latencyMs}ms',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            isOk ? 'admin.status_ok'.tr() : 'admin.status_degraded'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
