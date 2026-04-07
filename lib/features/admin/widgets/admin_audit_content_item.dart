part of 'admin_audit_content.dart';

/// Single audit log item card.
class AuditLogItem extends ConsumerStatefulWidget {
  final AdminLog log;

  const AuditLogItem({super.key, required this.log});

  @override
  ConsumerState<AuditLogItem> createState() => _AuditLogItemState();
}

class _AuditLogItemState extends ConsumerState<AuditLogItem> {
  String? _adminName;
  String? _targetName;

  @override
  void initState() {
    super.initState();
    _resolveNames();
  }

  Future<void> _resolveNames() async {
    final cache = ref.read(adminUserNameCacheProvider.notifier);

    if (widget.log.adminUserId != null) {
      final adminName = await cache.resolve(widget.log.adminUserId!);
      if (mounted) setState(() => _adminName = adminName);
    }

    if (widget.log.targetUserId != null) {
      final targetName = await cache.resolve(widget.log.targetUserId!);
      if (mounted) setState(() => _targetName = targetName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _iconForAction(widget.log.action),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.log.action,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    _formatTimestamp(context, widget.log.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (widget.log.details != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.log.details!,
                style: theme.textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (widget.log.adminUserId != null ||
                widget.log.targetUserId != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (widget.log.adminUserId != null)
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon(
                            AppIcons.users,
                            size: 12,
                            color: theme.colorScheme.outline,
                            semanticsLabel: 'admin.by'.tr(),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              '${'admin.by'.tr()} ${_adminName ?? _truncateId(widget.log.adminUserId!)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.log.targetUserId != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            label: 'admin.target'.tr(),
                            child: Icon(
                              LucideIcons.userCheck,
                              size: 12,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              '${'admin.target'.tr()} ${_targetName ?? _truncateId(widget.log.targetUserId!)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _iconForAction(String action) {
    final type = AdminActionType.fromJson(action);
    return switch (type) {
      AdminActionType.delete => AppIcon(
          AppIcons.delete,
          size: 18,
          semanticsLabel: 'common.delete'.tr(),
        ),
      AdminActionType.create => AppIcon(
          AppIcons.add,
          size: 18,
          semanticsLabel: 'common.add'.tr(),
        ),
      AdminActionType.update => AppIcon(
          AppIcons.edit,
          size: 18,
          semanticsLabel: 'common.edit'.tr(),
        ),
      AdminActionType.login => Semantics(
          label: 'auth.login'.tr(),
          child: const Icon(LucideIcons.logIn, size: 18),
        ),
      AdminActionType.logout => Semantics(
          label: 'auth.logout'.tr(),
          child: const Icon(LucideIcons.logOut, size: 18),
        ),
      AdminActionType.grantPremium => AppIcon(
          AppIcons.premium,
          size: 18,
          semanticsLabel: 'admin.grant_premium'.tr(),
        ),
      AdminActionType.revokePremium => Semantics(
          label: 'admin.revoke_premium'.tr(),
          child: const Icon(LucideIcons.xCircle, size: 18),
        ),
      AdminActionType.toggleActive => Semantics(
          label: action,
          child: const Icon(LucideIcons.toggleLeft, size: 18),
        ),
      AdminActionType.export => AppIcon(
          AppIcons.export,
          size: 18,
          semanticsLabel: 'export.title'.tr(),
        ),
      AdminActionType.reset => Semantics(
          label: action,
          child: const Icon(LucideIcons.rotateCcw, size: 18),
        ),
      AdminActionType.clearLogs => AppIcon(
          AppIcons.delete,
          size: 18,
          semanticsLabel: 'admin.clear_old_logs'.tr(),
        ),
      AdminActionType.dismissEvent => Semantics(
          label: 'admin.dismiss_event'.tr(),
          child: const Icon(LucideIcons.checkCircle, size: 18),
        ),
      AdminActionType.unknown => AppIcon(
          AppIcons.audit,
          size: 18,
          semanticsLabel: action,
        ),
    };
  }

  String _formatTimestamp(BuildContext context, DateTime dt) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('dd MMM yyyy HH:mm', locale).format(dt);
  }

  String _truncateId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}...';
  }
}
