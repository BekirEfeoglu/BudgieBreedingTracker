import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          error: (_, __) => DashboardContent(
            stats: const AdminStats(),
            statsLoadFailed: true,
            onRetryStats: () => ref.invalidate(adminStatsProvider),
          ),
          data: (stats) => DashboardContent(stats: stats),
        ),
      ),
    );
  }
}
