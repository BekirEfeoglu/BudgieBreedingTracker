part of 'sync_detail_sheet.dart';

class _PendingSection extends StatelessWidget {
  const _PendingSection({required this.pendingAsync, required this.theme});

  final AsyncValue<List<SyncErrorDetail>> pendingAsync;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final pending = pendingAsync.value ?? [];
    if (pending.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        _SectionHeader(
          title: 'sync.pending_section'.tr(),
          theme: theme,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...pending.map(
          (detail) => _TableRow(
            icon: const AppIcon(AppIcons.sync, size: 18),
            label: _localizeTable(detail.tableName),
            trailing: Text(
              detail.errorCount.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            theme: theme,
          ),
        ),
      ],
    );
  }
}

class _FailedSection extends StatelessWidget {
  const _FailedSection({required this.errorsAsync, required this.theme});

  final AsyncValue<List<SyncErrorDetail>> errorsAsync;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final errors = errorsAsync.value ?? [];
    if (errors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        _SectionHeader(
          title: 'sync.failed_section'.tr(),
          theme: theme,
          color: AppColors.error,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...errors.map(
          (detail) => _TableRow(
            icon: const Icon(
              LucideIcons.alertCircle,
              size: 18,
              color: AppColors.error,
            ),
            label: _localizeTable(detail.tableName),
            trailing: Text(
              'sync.error_count_summary'.tr(
                args: [detail.errorCount.toString()],
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
            subtitle: detail.lastError,
            theme: theme,
          ),
        ),
      ],
    );
  }
}

class _ConflictSection extends StatelessWidget {
  const _ConflictSection({required this.conflicts, required this.theme});

  final List<SyncConflict> conflicts;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (conflicts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        _SectionHeader(
          title: 'sync.conflict_section'.tr(),
          theme: theme,
          color: AppColors.warning,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...conflicts.map(
          (conflict) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.gitMerge,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conflict.description,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_localizeTable(conflict.table)}'
                        ' — ${formatTimeSince(conflict.detectedAt)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _ConflictTypeBadge(theme: theme),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConflictTypeBadge extends StatelessWidget {
  const _ConflictTypeBadge({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        'sync.conflict_server_wins'.tr(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppColors.warningText,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: Center(
        child: Column(
          children: [
            const Icon(
              LucideIcons.checkCircle,
              size: 48,
              color: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'sync.no_errors'.tr(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.theme,
    this.color,
  });

  final String title;
  final ThemeData theme;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: color ?? theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.icon,
    required this.label,
    required this.theme,
    this.trailing,
    this.subtitle,
  });

  final Widget icon;
  final String label;
  final Widget? trailing;
  final String? subtitle;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          icon,
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
