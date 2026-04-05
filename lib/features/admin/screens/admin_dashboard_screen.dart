import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_dashboard_widgets.dart';

/// Admin dashboard with stats cards and system health indicator.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    // Activate system health degradation alerts (push to admins)
    ref.watch(systemHealthAlertProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
          ref.invalidate(systemHealthProvider);
        },
        child: statsAsync.when(
          loading: () => const LoadingState(),
          error: (error, _) => ErrorState(
            message: 'common.data_load_error'.tr(),
            onRetry: () => ref.invalidate(adminStatsProvider),
          ),
          data: (stats) => DashboardContent(stats: stats),
        ),
      ),
    );
  }
}
