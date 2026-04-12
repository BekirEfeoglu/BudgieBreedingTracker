import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import 'admin_auth_utils.dart';

/// A single monitoring snapshot from pg_cron automated collection.
class MonitoringSnapshot {
  final String snapshotType;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const MonitoringSnapshot({
    required this.snapshotType,
    required this.data,
    required this.createdAt,
  });

  factory MonitoringSnapshot.fromJson(Map<String, dynamic> json) {
    return MonitoringSnapshot(
      snapshotType: json['snapshot_type'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// A single slow query entry from monitoring data.
class SlowQueryEntry {
  final int calls;
  final double totalTimeMs;
  final double meanTimeMs;
  final String query;

  const SlowQueryEntry({
    required this.calls,
    required this.totalTimeMs,
    required this.meanTimeMs,
    required this.query,
  });
}

/// Connection state entry from monitoring data.
class ConnectionStateEntry {
  final String state;
  final int count;

  const ConnectionStateEntry({required this.state, required this.count});
}

/// Parsed monitoring trend data for the dashboard.
class MonitoringTrend {
  final List<SlowQueryEntry> slowQueries;
  final List<ConnectionStateEntry> connectionStates;
  final int totalConnections;
  final int maxConnections;
  final DateTime? capturedAt;

  const MonitoringTrend({
    this.slowQueries = const [],
    this.connectionStates = const [],
    this.totalConnections = 0,
    this.maxConnections = 0,
    this.capturedAt,
  });
}

/// Fetches the latest monitoring snapshots (last 24h) for the admin dashboard.
final monitoringSnapshotsProvider =
    FutureProvider<MonitoringTrend>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  try {
    final result = await client
        .from(SupabaseConstants.dbMonitoringSnapshotsTable)
        .select('snapshot_type, data, created_at')
        .gte('created_at',
            DateTime.now().subtract(const Duration(hours: 24)).toIso8601String())
        .order('created_at', ascending: false)
        .limit(10);

    final rows = List<Map<String, dynamic>>.from(result);
    if (rows.isEmpty) return const MonitoringTrend();

    // Find latest slow_queries snapshot
    final slowQueryRow = rows.firstWhere(
      (r) => r['snapshot_type'] == 'slow_queries',
      orElse: () => <String, dynamic>{},
    );

    // Find latest connections snapshot
    final connRow = rows.firstWhere(
      (r) => r['snapshot_type'] == 'connections',
      orElse: () => <String, dynamic>{},
    );

    // Parse slow queries
    final slowQueries = <SlowQueryEntry>[];
    if (slowQueryRow.isNotEmpty) {
      final data = slowQueryRow['data'] as Map<String, dynamic>? ?? {};
      final queries = data['queries'] as List? ?? [];
      for (final q in queries) {
        final map = q as Map<String, dynamic>;
        slowQueries.add(SlowQueryEntry(
          calls: (map['calls'] as num?)?.toInt() ?? 0,
          totalTimeMs: (map['total_time_ms'] as num?)?.toDouble() ?? 0,
          meanTimeMs: (map['mean_time_ms'] as num?)?.toDouble() ?? 0,
          query: map['query']?.toString() ?? '',
        ));
      }
    }

    // Parse connections
    final connectionStates = <ConnectionStateEntry>[];
    var totalConn = 0;
    var maxConn = 0;
    DateTime? capturedAt;
    if (connRow.isNotEmpty) {
      final data = connRow['data'] as Map<String, dynamic>? ?? {};
      final states = data['states'] as List? ?? [];
      totalConn = (data['total'] as num?)?.toInt() ?? 0;
      maxConn = (data['max_connections'] as num?)?.toInt() ?? 0;
      capturedAt = DateTime.tryParse(connRow['created_at']?.toString() ?? '');
      for (final s in states) {
        final map = s as Map<String, dynamic>;
        connectionStates.add(ConnectionStateEntry(
          state: map['state']?.toString() ?? 'unknown',
          count: (map['count'] as num?)?.toInt() ?? 0,
        ));
      }
    }

    return MonitoringTrend(
      slowQueries: slowQueries,
      connectionStates: connectionStates,
      totalConnections: totalConn,
      maxConnections: maxConn,
      capturedAt: capturedAt,
    );
  } catch (e, st) {
    AppLogger.error('monitoringSnapshotsProvider', e, st);
    rethrow;
  }
});

/// Verifies pg_cron monitoring jobs are scheduled and running.
/// Call via ref.read(cronJobStatusProvider.future) on demand.
final cronJobStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);
  try {
    final result = await client.rpc('verify_monitoring_cron_jobs');
    return result as Map<String, dynamic>;
  } catch (e, st) {
    AppLogger.error('cronJobStatusProvider', e, st);
    return {'status': 'error', 'message': e.toString()};
  }
});
