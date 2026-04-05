import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../providers/admin_actions_provider.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_notification_sheet.dart';
import '../widgets/admin_user_detail_widgets.dart';

/// Detail screen for a specific user in admin panel.
class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(adminUserDetailProvider(widget.userId));

    ref.listen<AdminActionState>(adminActionsProvider, (_, state) {
      if (state.isSuccess) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );
        }
        ref.read(adminActionsProvider.notifier).reset();
        ref.invalidate(adminUserDetailProvider(widget.userId));
      }
      if (state.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('admin.user_detail'.tr()),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleAction(value),
            itemBuilder: (context) {
              final detail = ref
                  .read(adminUserDetailProvider(widget.userId))
                  .value;
              final isActive = detail?.isActive ?? true;
              return [
                PopupMenuItem(
                  value: 'toggle_active',
                  child: Text(
                    isActive
                        ? 'admin.deactivate_user'.tr()
                        : 'admin.activate_user'.tr(),
                  ),
                ),
                PopupMenuItem(
                  value: 'send_notification',
                  child: Text('admin.send_notification'.tr()),
                ),
              ];
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(adminUserDetailProvider(widget.userId)),
        child: detailAsync.when(
          loading: () => const LoadingState(),
          error: (error, _) => ErrorState(
            message: 'common.data_load_error'.tr(),
            onRetry: () =>
                ref.invalidate(adminUserDetailProvider(widget.userId)),
          ),
          data: (detail) => UserDetailContent(
            detail: detail,
            onGrantPremium: () => _handleGrantPremium(),
            onRevokePremium: () => _handleRevokePremium(),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(String action) async {
    if (action == 'toggle_active') {
      final detailAsync = ref.read(adminUserDetailProvider(widget.userId));
      final currentlyActive = detailAsync.value?.isActive ?? true;

      final confirmed = await showConfirmDialog(
        context,
        title: currentlyActive
            ? 'admin.confirm_deactivate'.tr()
            : 'admin.confirm_activate'.tr(),
        message: currentlyActive
            ? 'admin.confirm_deactivate_desc'.tr()
            : 'admin.confirm_activate_desc'.tr(),
        isDestructive: currentlyActive,
      );
      if (confirmed == true) {
        ref
            .read(adminActionsProvider.notifier)
            .toggleUserActive(widget.userId, !currentlyActive);
      }
    }
    if (action == 'send_notification') {
      if (!mounted) return;
      final sent = await showAdminNotificationSheet(
        context,
        ref: ref,
        targetUserId: widget.userId,
      );
      if (sent == true && mounted) {
        final state = ref.read(adminActionsProvider);
        final message =
            state.successMessage ?? 'admin.notification_sent'.tr();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  Future<void> _handleGrantPremium() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.confirm_grant_premium'.tr(),
      message: 'admin.confirm_grant_premium_desc'.tr(),
    );
    if (confirmed == true) {
      ref.read(adminActionsProvider.notifier).grantPremium(widget.userId);
    }
  }

  Future<void> _handleRevokePremium() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.confirm_revoke_premium'.tr(),
      message: 'admin.confirm_revoke_premium_desc'.tr(),
      isDestructive: true,
    );
    if (confirmed == true) {
      ref.read(adminActionsProvider.notifier).revokePremium(widget.userId);
    }
  }
}
