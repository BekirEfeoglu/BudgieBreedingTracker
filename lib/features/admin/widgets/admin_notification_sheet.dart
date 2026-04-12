import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../providers/admin_actions_provider.dart';

/// Shows a bottom sheet for sending an admin notification.
/// Returns true if notification was sent successfully.
Future<bool?> showAdminNotificationSheet(
  BuildContext context, {
  required WidgetRef ref,
  String? targetUserId,
  List<String>? targetUserIds,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _NotificationSheetContent(
      targetUserId: targetUserId,
      targetUserIds: targetUserIds,
    ),
  );
}

class _NotificationSheetContent extends ConsumerStatefulWidget {
  final String? targetUserId;
  final List<String>? targetUserIds;

  const _NotificationSheetContent({
    this.targetUserId,
    this.targetUserIds,
  });

  @override
  ConsumerState<_NotificationSheetContent> createState() =>
      _NotificationSheetContentState();
}

class _NotificationSheetContentState extends ConsumerState<_NotificationSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  bool get _isBulk =>
      widget.targetUserIds != null && widget.targetUserIds!.isNotEmpty;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(adminActionsProvider.notifier);
      final title = _titleController.text.trim();
      final body = _messageController.text.trim();

      if (_isBulk) {
        await notifier.sendBulkNotification(
            widget.targetUserIds!, title, body);
      } else if (widget.targetUserId != null) {
        await notifier.sendNotification(widget.targetUserId!, title, body);
      }

      if (!mounted) return;

      final state = ref.read(adminActionsProvider);
      if (state.isSuccess) {
        Navigator.of(context).pop(true);
      } else if (state.error != null) {
        if (mounted) setState(() => _isLoading = false);
        Navigator.of(context).pop(false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('admin.action_error'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final count = _isBulk ? widget.targetUserIds!.length : 1;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _isBulk
                      ? 'admin.bulk_send_notification'.tr()
                      : 'admin.send_notification'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isBulk) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$count ${'admin.users'.tr()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _titleController,
                  maxLength: 100,
                  decoration: InputDecoration(
                    labelText: 'admin.notification_title_label'.tr(),
                    hintText: 'admin.notification_title_hint'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'admin.notification_title_required'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _messageController,
                  maxLength: 500,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'admin.notification_message_label'.tr(),
                    hintText: 'admin.notification_message_hint'.tr(),
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'admin.notification_message_required'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _send,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('admin.send'.tr()),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
