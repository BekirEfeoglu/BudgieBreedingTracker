part of 'admin_users_screen.dart';

// ─── Bulk Action Bar ─────────────────────────────────────────────────────────

class _BulkActionBar extends ConsumerStatefulWidget {
  final Set<String> selectedIds;
  final VoidCallback onClearSelection;

  const _BulkActionBar({
    required this.selectedIds,
    required this.onClearSelection,
  });

  @override
  ConsumerState<_BulkActionBar> createState() => _BulkActionBarState();
}

class _BulkActionBarState extends ConsumerState<_BulkActionBar> {
  bool _isLoading = false;

  Future<void> _run(
    Future<({int succeeded, int skipped})> Function() action,
    String actionLabel,
  ) async {
    setState(() => _isLoading = true);
    try {
      final result = await action();
      if (!mounted) return;
      final skippedMsg = result.skipped > 0
          ? ' (${result.skipped} ${'admin.protected_users_skipped'.tr(args: [''])})'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$actionLabel: ${result.succeeded}$skippedMsg')),
      );
      widget.onClearSelection();
    } catch (e, st) {
      AppLogger.error('_BulkActionBar', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('admin.action_error'.tr())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onActivate() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.confirm_activate'.tr(),
      message: 'admin.confirm_activate_desc'.tr(),
    );
    if (confirmed != true) return;
    await _run(
      () => ref
          .read(adminActionsProvider.notifier)
          .bulkToggleActive(widget.selectedIds, activate: true),
      'admin.bulk_activate'.tr(),
    );
  }

  Future<void> _onDeactivate() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.confirm_deactivate'.tr(),
      message: 'admin.confirm_deactivate_desc'.tr(),
      isDestructive: true,
    );
    if (confirmed != true) return;
    await _run(
      () => ref
          .read(adminActionsProvider.notifier)
          .bulkToggleActive(widget.selectedIds, activate: false),
      'admin.bulk_deactivate'.tr(),
    );
  }

  Future<void> _onGrantPremium() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.confirm_grant_premium'.tr(),
      message: 'admin.confirm_grant_premium_desc'.tr(),
    );
    if (confirmed != true) return;
    await _run(
      () => ref
          .read(adminActionsProvider.notifier)
          .bulkGrantPremium(widget.selectedIds),
      'admin.bulk_grant_premium'.tr(),
    );
  }

  Future<void> _onRevokePremium() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.confirm_revoke_premium'.tr(),
      message: 'admin.confirm_revoke_premium_desc'.tr(),
      isDestructive: true,
    );
    if (confirmed != true) return;
    await _run(
      () => ref
          .read(adminActionsProvider.notifier)
          .bulkRevokePremium(widget.selectedIds),
      'admin.bulk_revoke_premium'.tr(),
    );
  }

  Future<void> _onSendNotification() async {
    final result = await showAdminNotificationSheet(
      context,
      ref: ref,
      targetUserIds: widget.selectedIds.toList(),
    );
    if (result == true && mounted) {
      final state = ref.read(adminActionsProvider);
      final message = state.successMessage ?? 'admin.notification_sent'.tr();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      widget.onClearSelection();
    }
  }

  Future<void> _onExport() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.bulk_export'.tr(),
      message: 'common.continue_confirm'.tr(),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(adminActionsProvider.notifier)
          .bulkExport(widget.selectedIds);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${'admin.bulk_export'.tr()}: ${widget.selectedIds.length}',
          ),
        ),
      );
      widget.onClearSelection();
    } catch (e, st) {
      AppLogger.error('_BulkActionBar.export', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('admin.action_error'.tr())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onDelete() async {
    final confirmed = await _showDeletePreview();
    if (confirmed != true) return;
    await _run(
      () => ref
          .read(adminActionsProvider.notifier)
          .bulkDeleteUserData(widget.selectedIds),
      'admin.bulk_delete'.tr(),
    );
  }

  Future<bool?> _showDeletePreview() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final previewAsync = ref.watch(
              bulkDeletePreviewProvider(widget.selectedIds),
            );
            return AlertDialog(
              title: Text('admin.bulk_delete_preview'.tr()),
              content: previewAsync.when(
                loading: () =>
                    const SizedBox(width: 240, child: LoadingState()),
                error: (_, __) => Text('common.data_load_error'.tr()),
                data: (preview) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin.bulk_delete_confirm'.tr(
                        args: ['${preview.userCount}'],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PreviewRow(
                      label: 'admin.birds'.tr(),
                      value: preview.birdsCount,
                    ),
                    _PreviewRow(
                      label: 'admin.pairs_count'.tr(),
                      value: preview.pairsCount,
                    ),
                    _PreviewRow(
                      label: 'admin.eggs_count'.tr(),
                      value: preview.eggsCount,
                    ),
                    _PreviewRow(
                      label: 'admin.chicks_count'.tr(),
                      value: preview.chicksCount,
                    ),
                    _PreviewRow(
                      label: 'admin.health_records_count'.tr(),
                      value: preview.healthRecordsCount,
                    ),
                    _PreviewRow(
                      label: 'admin.events_count'.tr(),
                      value: preview.eventsCount,
                    ),
                    _PreviewRow(
                      label: 'birds.photos'.tr(),
                      value: preview.photosCount,
                    ),
                    const Divider(),
                    _PreviewRow(
                      label: 'admin.total_records'.tr(),
                      value: preview.totalRecords,
                      isStrong: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text('common.cancel'.tr()),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: Text('admin.bulk_delete'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFounderAsync = ref.watch(isFounderProvider);
    final isFounder = isFounderAsync.value ?? false;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: CircularProgressIndicator(),
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(LucideIcons.userCheck, size: 16),
                      label: Text('admin.bulk_activate'.tr()),
                      onPressed: _onActivate,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ActionChip(
                      avatar: const Icon(LucideIcons.userX, size: 16),
                      label: Text('admin.bulk_deactivate'.tr()),
                      onPressed: _onDeactivate,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ActionChip(
                      avatar: const Icon(LucideIcons.star, size: 16),
                      label: Text('admin.bulk_grant_premium'.tr()),
                      onPressed: _onGrantPremium,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ActionChip(
                      avatar: const Icon(LucideIcons.starOff, size: 16),
                      label: Text('admin.bulk_revoke_premium'.tr()),
                      onPressed: _onRevokePremium,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ActionChip(
                      avatar: const Icon(LucideIcons.bell, size: 16),
                      label: Text('admin.bulk_send_notification'.tr()),
                      onPressed: _onSendNotification,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ActionChip(
                      avatar: const Icon(LucideIcons.download, size: 16),
                      label: Text('admin.bulk_export'.tr()),
                      onPressed: _onExport,
                    ),
                    if (isFounder) ...[
                      const SizedBox(width: AppSpacing.sm),
                      ActionChip(
                        avatar: Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color: theme.colorScheme.error,
                        ),
                        label: Text(
                          'admin.bulk_delete'.tr(),
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        onPressed: _onDelete,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    this.isStrong = false,
  });

  final String label;
  final int value;
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    final style = isStrong
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('$value', style: style),
        ],
      ),
    );
  }
}
