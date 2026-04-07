part of 'admin_security_content.dart';

/// Single security event item card with dismiss action.
class SecurityEventItem extends ConsumerWidget {
  final SecurityEvent event;
  const SecurityEventItem({super.key, required this.event});

  ({IconData icon, Color color, String label}) _severity(BuildContext context) {
    return switch (event.eventType.inferredSeverity) {
      SecuritySeverityLevel.high => (
        icon: LucideIcons.alertOctagon,
        color: AppColors.error,
        label: 'admin.severity_high'.tr(),
      ),
      SecuritySeverityLevel.medium => (
        icon: LucideIcons.alertTriangle,
        color: AppColors.warning,
        label: 'admin.severity_medium'.tr(),
      ),
      _ => (
        icon: LucideIcons.info,
        color: AppColors.info,
        label: 'admin.severity_low'.tr(),
      ),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sev = _severity(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Semantics(
                label: sev.label,
                child: Icon(sev.icon, size: 18, color: sev.color),
              ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    event.eventType.toJson(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: sev.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    sev.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: sev.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  icon: Semantics(
                    label: 'admin.dismiss_event'.tr(),
                    child: const Icon(LucideIcons.checkCircle, size: 18),
                  ),
                  tooltip: 'admin.dismiss_event'.tr(),
                  onPressed: () {
                    ref
                        .read(adminActionsProvider.notifier)
                        .dismissSecurityEvent(event.id);
                  },
                  constraints: const BoxConstraints(
                    minWidth: AppSpacing.touchTargetMin,
                    minHeight: AppSpacing.touchTargetMin,
                  ),
                ),
              ],
            ),
            if (event.details != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                event.details!,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            SecurityMetadataRow(event: event),
          ],
        ),
      ),
    );
  }
}

/// Metadata row showing IP address and timestamp.
class SecurityMetadataRow extends StatelessWidget {
  final SecurityEvent event;
  const SecurityMetadataRow({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: outline);
    return Row(
      children: [
        if (event.ipAddress != null) ...[
          Semantics(
            label: 'IP',
            child: Icon(LucideIcons.globe, size: 12, color: outline),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _maskIp(event.ipAddress!),
            style: style?.copyWith(fontFamily: 'monospace'),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Semantics(
          label: 'admin.time'.tr(),
          child: Icon(LucideIcons.clock, size: 12, color: outline),
        ),
        const SizedBox(width: 4),
        Text(_formatTimestamp(event.createdAt, context), style: style),
      ],
    );
  }

  String _formatTimestamp(DateTime dt, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('dd MMM yyyy HH:mm', locale).format(dt);
  }

  String _maskIp(String ip) {
    final parts = ip.split('.');
    if (parts.length == 4) {
      return '***.***.${parts[2]}.${parts[3]}';
    }
    return ip;
  }
}
