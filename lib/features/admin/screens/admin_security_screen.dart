import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/core/providers/action_feedback_providers.dart';
import '../providers/admin_actions_provider.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_security_timeline_chart.dart';
import '../widgets/admin_security_widgets.dart';

/// Security events viewer screen.
class AdminSecurityScreen extends ConsumerStatefulWidget {
  const AdminSecurityScreen({super.key});

  @override
  ConsumerState<AdminSecurityScreen> createState() =>
      _AdminSecurityScreenState();
}

class _AdminSecurityScreenState extends ConsumerState<AdminSecurityScreen> {
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
  void _applyFilter(SecurityEventFilter next) {
    ref.read(securityEventFilterProvider.notifier).state = next;
    ref.read(adminSecurityLimitProvider.notifier).state =
        AdminConstants.securityEventsPageSize;
  }

  /// Debounces search input so each keystroke does not fire a Postgres
  /// `.or(ilike)` round-trip. Mirrors the pattern in admin_users_screen.
  void _onSearchChanged(String raw, SecurityEventFilter current) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(AdminConstants.searchDebounceDuration, () {
      if (!mounted) return;
      _applyFilter(current.copyWith(searchQuery: raw));
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(adminSecurityEventsProvider);
    final filter = ref.watch(securityEventFilterProvider);

    ref.listen<AdminActionState>(adminActionsProvider, (_, state) {
      if (!mounted) return;
      if (state.isSuccess) {
        ref.read(adminActionsProvider.notifier).reset();
        ref.invalidate(adminSecurityEventsProvider);
        ActionFeedbackService.show('admin.event_dismissed'.tr());
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
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: AdminSecurityTimelineChart(),
          ),
          SecurityFilterBar(
            controller: _searchController,
            filter: filter,
            onSearchChanged: (q) => _onSearchChanged(q, filter),
            onSeverityChanged: (s) => _applyFilter(
              s == null
                  ? filter.copyWith(clearSeverity: true)
                  : filter.copyWith(severity: s),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(adminSecurityEventsProvider),
              child: eventsAsync.when(
                loading: () => const LoadingState(),
                error: (error, _) => ErrorState(
                  message: 'common.data_load_error'.tr(),
                  onRetry: () => ref.invalidate(adminSecurityEventsProvider),
                ),
                data: (events) => SecurityContent(events: events),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
