import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/safe_cast.dart';
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
    // `snapshot_type` is required and must identify the row kind.
    // Empty/missing is a schema violation, not a silent default.
    final type = safeString(json, 'snapshot_type');
    if (type == null) {
      AppLogger.warning(
        '[MonitoringSnapshot] malformed payload: missing/invalid snapshot_type '
        '(raw=${json['snapshot_type']})',
      );
      throw const ValidationException(
        'errors.unknown_error',
        code: 'monitoring_snapshot_invalid_type',
      );
    }
    return MonitoringSnapshot(
      snapshotType: type,
      data: safeMap(json, 'data') ?? const {},
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
            DateTime.now().subtract(const Duration(hours: 24)).toUtc().toIso8601String())
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

    // Parse slow queries. Each entry is defensively cast — malformed list
    // items are skipped with a warning rather than crashing the provider.
    final slowQueries = <SlowQueryEntry>[];
    if (slowQueryRow.isNotEmpty) {
      final data = safeMap(slowQueryRow, 'data') ?? const {};
      final queries = safeList(data, 'queries');
      for (final q in queries) {
        final map = asStringMap(q);
        if (map == null) {
          AppLogger.warning(
            '[monitoringSnapshotsProvider] skipping slow_queries entry '
            'with invalid shape (type=${q.runtimeType})',
          );
          continue;
        }
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
      final data = safeMap(connRow, 'data') ?? const {};
      final states = safeList(data, 'states');
      totalConn = (data['total'] as num?)?.toInt() ?? 0;
      maxConn = (data['max_connections'] as num?)?.toInt() ?? 0;
      capturedAt = DateTime.tryParse(connRow['created_at']?.toString() ?? '');
      for (final s in states) {
        final map = asStringMap(s);
        if (map == null) {
          AppLogger.warning(
            '[monitoringSnapshotsProvider] skipping connections state '
            'entry with invalid shape (type=${s.runtimeType})',
          );
          continue;
        }
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
