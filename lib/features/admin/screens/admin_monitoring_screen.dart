import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_monitoring_widgets.dart';

/// Auto-refresh interval for monitoring data.
const _autoRefreshInterval = Duration(seconds: 30);

/// System monitoring dashboard — shows real Supabase server capacity metrics.
class AdminMonitoringScreen extends ConsumerStatefulWidget {
  const AdminMonitoringScreen({super.key});

  @override
  ConsumerState<AdminMonitoringScreen> createState() =>
      _AdminMonitoringScreenState();
}

class _AdminMonitoringScreenState extends ConsumerState<AdminMonitoringScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      ref.invalidate(serverCapacityProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capacityAsync = ref.watch(serverCapacityProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(serverCapacityProvider),
        child: capacityAsync.when(
          loading: () => const LoadingState(),
          error: (error, _) => ErrorState(
            message: 'common.data_load_error'.tr(),
            onRetry: () => ref.invalidate(serverCapacityProvider),
          ),
          data: (capacity) => MonitoringContent(capacity: capacity),
        ),
      ),
    );
  }
}
