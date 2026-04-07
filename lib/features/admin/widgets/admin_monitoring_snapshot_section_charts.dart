part of 'admin_monitoring_snapshot_section.dart';

class _SlowQueriesCard extends StatelessWidget {
  final List<SlowQueryEntry> queries;

  const _SlowQueriesCard({required this.queries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Show top 5 only
    final display = queries.take(5).toList();

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.timer, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'admin.slow_queries'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${queries.length} ${'admin.queries_found'.tr()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...display.map((q) => _SlowQueryRow(query: q)),
          ],
        ),
      ),
    );
  }
}

class _SlowQueryRow extends StatelessWidget {
  final SlowQueryEntry query;

  const _SlowQueryRow({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCritical = query.meanTimeMs > 1000;

    return InkWell(
      onTap: () => _showQueryDetailSheet(context, query),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCritical
                        ? theme.colorScheme.error
                        : theme.colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${query.meanTimeMs.toStringAsFixed(0)}ms avg',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCritical ? theme.colorScheme.error : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${query.calls}x',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${query.totalTimeMs.toStringAsFixed(0)}ms total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xl, top: 2),
              child: Text(
                query.query.length > 80
                    ? '${query.query.substring(0, 80)}...'
                    : query.query,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQueryDetailSheet(BuildContext context, SlowQueryEntry query) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: AppSpacing.screenPadding,
          child: ListView(
            controller: scrollController,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'admin.query_detail'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: SelectableText(
                  query.query,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: query.query));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('common.copied'.tr()),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.copy, size: 16),
                  label: Text('common.copy'.tr()),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _QueryStatTile(
                      label: 'admin.query_mean_time'.tr(),
                      value:
                          '${query.meanTimeMs.toStringAsFixed(1)} ms',
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _QueryStatTile(
                      label: 'admin.query_total_time'.tr(),
                      value:
                          '${query.totalTimeMs.toStringAsFixed(1)} ms',
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _QueryStatTile(
                      label: 'admin.query_call_count'.tr(),
                      value: '${query.calls}',
                      theme: theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('common.close'.tr()),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueryStatTile extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _QueryStatTile({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
