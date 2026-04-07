part of 'admin_settings_content.dart';

class _CronStatusSection extends ConsumerStatefulWidget {
  const _CronStatusSection();
  @override
  ConsumerState<_CronStatusSection> createState() => _CronStatusSectionState();
}

class _CronStatusSectionState extends ConsumerState<_CronStatusSection> {
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _error;

  Future<void> _checkStatus() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ref.refresh(cronJobStatusProvider.future);
      if (!mounted) return;
      setState(() { _result = data; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color _statusColor(String s) => switch (s) {
    'ok' => AppColors.budgieGreen, 'partial' => AppColors.warning, _ => AppColors.error,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(LucideIcons.clock, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Text('admin.cron_status_title'.tr(), style: theme.textTheme.titleSmall),
          ]),
          const SizedBox(height: AppSpacing.md),
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else if (_error != null)
            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error))
          else if (_result != null)
            _buildResult(theme)
          else
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: _checkStatus,
              icon: const Icon(LucideIcons.play, size: 16),
              label: Text('admin.cron_check_button'.tr()),
            )),
        ]),
      ),
    );
  }

  Widget _buildResult(ThemeData theme) {
    final status = _result!['status']?.toString() ?? 'unknown';
    final jobs = _result!['scheduled_jobs']?.toString() ?? '-';
    final snaps = _result!['total_snapshots']?.toString() ?? '-';
    final latestAt = _result!['latest_snapshot_at']?.toString();
    final color = _statusColor(status);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: AppSpacing.sm),
        Text(status.toUpperCase(), style: theme.textTheme.labelMedium?.copyWith(
            color: color, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: AppSpacing.sm),
      Text('${'admin.cron_scheduled_jobs'.tr()}: $jobs', style: theme.textTheme.bodySmall),
      Text('${'admin.cron_total_snapshots'.tr()}: $snaps', style: theme.textTheme.bodySmall),
      if (latestAt != null)
        Text('${'admin.cron_latest_snapshot'.tr()}: $latestAt', style: theme.textTheme.bodySmall),
      const SizedBox(height: AppSpacing.md),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: _checkStatus,
        icon: const Icon(LucideIcons.refreshCw, size: 16),
        label: Text('admin.cron_recheck_button'.tr()),
      )),
    ]);
  }
}
