import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import 'admin_auth_utils.dart';
import 'admin_models.dart';

/// Database table info provider.
/// Uses server-side RPC to bypass RLS and get accurate row counts.
final adminDatabaseInfoProvider = FutureProvider<List<TableInfo>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  try {
    final result = await client.rpc('admin_get_table_counts');
    final rows = result as List;
    return rows.map((row) {
      return TableInfo(
        name: row['table_name'] as String,
        rowCount: (row['row_count'] as num).toInt(),
      );
    }).toList();
  } catch (e, st) {
    AppLogger.error(
      'adminDatabaseInfoProvider RPC failed, using fallback',
      e,
      st,
    );
    // Fallback: try individual count queries for all known tables
    final tables = [
      SupabaseConstants.birdsTable,
      SupabaseConstants.eggsTable,
      SupabaseConstants.chicksTable,
      SupabaseConstants.incubationsTable,
      SupabaseConstants.clutchesTable,
      SupabaseConstants.breedingPairsTable,
      SupabaseConstants.nestsTable,
      SupabaseConstants.healthRecordsTable,
      SupabaseConstants.growthMeasurementsTable,
      SupabaseConstants.profilesTable,
      SupabaseConstants.eventsTable,
      SupabaseConstants.notificationsTable,
      SupabaseConstants.notificationSettingsTable,
      SupabaseConstants.photosTable,
      SupabaseConstants.userSubscriptionsTable,
      SupabaseConstants.adminLogsTable,
      SupabaseConstants.adminUsersTable,
      SupabaseConstants.securityEventsTable,
      SupabaseConstants.systemSettingsTable,
      SupabaseConstants.systemMetricsTable,
      SupabaseConstants.systemStatusTable,
      SupabaseConstants.systemAlertsTable,
      SupabaseConstants.userSessionsTable,
      SupabaseConstants.userPreferencesTable,
      SupabaseConstants.subscriptionPlansTable,
      SupabaseConstants.backupJobsTable,
      SupabaseConstants.eventRemindersTable,
      SupabaseConstants.notificationSchedulesTable,
      SupabaseConstants.feedbackTable,
    ];

    final infos = <TableInfo>[];
    for (final table in tables) {
      try {
        final count = await client.from(table).count();
        infos.add(TableInfo(name: table, rowCount: count));
      } catch (e2, st2) {
        AppLogger.error('adminDatabaseInfoProvider: $table', e2, st2);
        infos.add(TableInfo(name: table, rowCount: -1));
      }
    }
    return infos;
  }
});

/// Capacity threshold above which a Sentry warning is sent (90%).
const _capacityCriticalThreshold = 0.9;

/// Server capacity provider — queries PostgreSQL system catalogs via RPC.
/// Falls back to basic table counts if the RPC function is unavailable.
final serverCapacityProvider = FutureProvider<ServerCapacity>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  try {
    final result = await client.rpc('get_server_capacity');
    final data = result as Map<String, dynamic>;
    final capacity = ServerCapacity.fromJson(data);

    // Sentry alert when capacity exceeds critical threshold
    final dbRatio = capacity.databaseSizeBytes / (500 * 1024 * 1024);
    final connRatio = capacity.connectionUsageRatio;
    final worstRatio = math.max(dbRatio, connRatio);

    if (worstRatio >= _capacityCriticalThreshold) {
      Sentry.captureMessage(
        'Server capacity critical: DB ${(dbRatio * 100).toStringAsFixed(1)}%, '
        'Connections ${(connRatio * 100).toStringAsFixed(1)}%',
        level: SentryLevel.warning,
      );
    }

    return capacity;
  } catch (e, st) {
    AppLogger.error('serverCapacityProvider RPC failed, using fallback', e, st);

    // Fallback: estimate capacity from table counts
    final coreTables = [
      SupabaseConstants.birdsTable,
      SupabaseConstants.eggsTable,
      SupabaseConstants.chicksTable,
      SupabaseConstants.breedingPairsTable,
      SupabaseConstants.profilesTable,
      SupabaseConstants.eventsTable,
      SupabaseConstants.photosTable,
    ];

    var totalRows = 0;
    final tableCapacities = <TableCapacity>[];
    for (final table in coreTables) {
      try {
        final count = await client.from(table).count();
        totalRows += count;
        tableCapacities.add(
          TableCapacity(
            name: table,
            sizeBytes: 0,
            rowCount: count,
            deadTupleCount: 0,
            deadTupleRatio: 0,
          ),
        );
      } catch (_) {
        tableCapacities.add(
          TableCapacity(
            name: table,
            sizeBytes: 0,
            rowCount: -1,
            deadTupleCount: 0,
            deadTupleRatio: 0,
          ),
        );
      }
    }

    return ServerCapacity(
      databaseSizeBytes: 0,
      activeConnections: 0,
      totalConnections: 0,
      maxConnections: 60,
      cacheHitRatio: 0,
      totalRows: totalRows,
      indexHitRatio: 0,
      tables: tableCapacities,
    );
  }
});
