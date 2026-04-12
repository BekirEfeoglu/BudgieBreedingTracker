import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../notifications/providers/action_feedback_providers.dart';
import '../providers/admin_actions_provider.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_audit_widgets.dart';

/// Audit log viewer screen showing admin actions.
class AdminAuditScreen extends ConsumerStatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  ConsumerState<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends ConsumerState<AdminAuditScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(adminAuditLogsProvider);
    final filter = ref.watch(auditLogFilterProvider);

    ref.listen<AdminActionState>(adminActionsProvider, (_, state) {
      if (state.isSuccess) {
        ref.read(adminActionsProvider.notifier).reset();
        ref.invalidate(adminAuditLogsProvider);
        ActionFeedbackService.show('admin.logs_cleared'.tr());
      }
      if (state.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('admin.action_error'.tr())));
      }
    });

    return Scaffold(
      body: Column(
        children: [
          AuditFilterBar(
            controller: _searchController,
            filter: filter,
            onSearchChanged: (q) =>
                ref.read(auditLogFilterProvider.notifier).state = filter
                    .copyWith(searchQuery: q),
            onStartDatePicked: (date) =>
                ref.read(auditLogFilterProvider.notifier).state = filter
                    .copyWith(startDate: date),
            onEndDatePicked: (date) =>
                ref.read(auditLogFilterProvider.notifier).state = filter
                    .copyWith(endDate: date),
            onClear: () {
              _searchController.clear();
              ref.read(auditLogFilterProvider.notifier).state =
                  const AuditLogFilter();
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminAuditLogsProvider),
              child: logsAsync.when(
                loading: () => const LoadingState(),
                error: (error, _) => ErrorState(
                  message: 'common.data_load_error'.tr(),
                  onRetry: () => ref.invalidate(adminAuditLogsProvider),
                ),
                data: (logs) => AuditContent(
                  logs: logs,
                  hasMore: logs.length >= ref.watch(adminAuditLimitProvider),
                  onLoadMore: () {
                    ref.read(adminAuditLimitProvider.notifier).state +=
                        AdminConstants.auditLogsPageSize;
                  },
                  onClearLogs: _onClearLogs,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onClearLogs() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.clear_logs'.tr(),
      message: 'admin.confirm_clear_logs'.tr(),
      isDestructive: true,
    );
    if (confirmed == true) {
      ref.read(adminActionsProvider.notifier).clearAuditLogs();
    }
  }
}
