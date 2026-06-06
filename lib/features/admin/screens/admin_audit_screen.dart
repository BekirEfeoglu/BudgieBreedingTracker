import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/core/providers/action_feedback_providers.dart';
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
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Resets pagination so a filter change starts from the first page —
  /// otherwise an earlier `+50, +50, +50` accumulation would refetch a
  /// 200-row window for the new filter on the very first request.
  void _applyFilter(AuditLogFilter next) {
    ref.read(auditLogFilterProvider.notifier).state = next;
    ref.read(adminAuditLimitProvider.notifier).state =
        AdminConstants.auditLogsPageSize;
  }

  /// Debounces search input so each keystroke does not fire a Postgres
  /// `.or(ilike)` round-trip. Mirrors the pattern in admin_users_screen.
  void _onSearchChanged(String raw, AuditLogFilter current) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(AdminConstants.searchDebounceDuration, () {
      if (!mounted) return;
      _applyFilter(current.copyWith(searchQuery: raw));
    });
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(adminAuditLogsProvider);
    final filter = ref.watch(auditLogFilterProvider);

    ref.listen<AdminActionState>(adminActionsProvider, (_, state) {
      if (!mounted) return;
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
            onSearchChanged: (q) => _onSearchChanged(q, filter),
            onStartDatePicked: (date) =>
                _applyFilter(filter.copyWith(startDate: date)),
            onEndDatePicked: (date) =>
                _applyFilter(filter.copyWith(endDate: date)),
            onClear: () {
              _searchDebounce?.cancel();
              _searchController.clear();
              _applyFilter(const AuditLogFilter());
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
                data: (logs) {
                  return AuditContent(
                    logs: logs,
                    hasMore: logs.length >= ref.watch(adminAuditLimitProvider),
                    onLoadMore: () {
                      ref.read(adminAuditLimitProvider.notifier).state +=
                          AdminConstants.auditLogsPageSize;
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
