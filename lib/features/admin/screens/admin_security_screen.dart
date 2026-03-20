import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../providers/admin_actions_provider.dart';
import '../providers/admin_providers.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(filteredSecurityEventsProvider);
    final filter = ref.watch(securityEventFilterProvider);

    ref.listen<AdminActionState>(adminActionsProvider, (_, state) {
      if (state.isSuccess) {
        ref.read(adminActionsProvider.notifier).reset();
        ref.invalidate(filteredSecurityEventsProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('admin.event_dismissed'.tr())));
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
          SecurityFilterBar(
            controller: _searchController,
            filter: filter,
            onSearchChanged: (q) =>
                ref.read(securityEventFilterProvider.notifier).state = filter
                    .copyWith(searchQuery: q),
            onSeverityChanged: (s) =>
                ref.read(securityEventFilterProvider.notifier).state = s == null
                ? filter.copyWith(clearSeverity: true)
                : filter.copyWith(severity: s),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(filteredSecurityEventsProvider),
              child: eventsAsync.when(
                loading: () => const LoadingState(),
                error: (error, _) => ErrorState(
                  message: 'common.data_load_error'.tr(),
                  onRetry: () => ref.invalidate(filteredSecurityEventsProvider),
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
