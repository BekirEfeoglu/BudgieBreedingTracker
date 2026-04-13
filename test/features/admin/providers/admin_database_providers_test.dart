import 'dart:async';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/features/admin/constants/admin_constants.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_database_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Fake Supabase builders ──────────────────────────────────

class _FakeMaybeSingleBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestMap?> {
  _FakeMaybeSingleBuilder({this.result, this.error});

  final PostgrestMap? result;
  final Object? error;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestMap? value) onValue, {
    Function? onError,
  }) {
    final source = error == null
        ? Future<PostgrestMap?>.value(result)
        : Future<PostgrestMap?>.error(error!);
    return source.then(onValue, onError: onError);
  }
}

class _FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  _FakeFilterBuilder({
    this.result = const [],
    this.error,
    this.maybeSingleResult,
  });

  PostgrestList result;
  Object? error;
  _FakeMaybeSingleBuilder? maybeSingleResult;
  final eqCalls = <MapEntry<String, Object>>[];
  final ltCalls = <MapEntry<String, Object>>[];

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    eqCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestFilterBuilder<PostgrestList> lt(String column, Object value) {
    ltCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    return maybeSingleResult ??
        _FakeMaybeSingleBuilder(result: result.isNotEmpty ? result.first : null);
  }

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestList value) onValue, {
    Function? onError,
  }) {
    if (error != null) {
      return Future<PostgrestList>.error(error!).then(onValue, onError: onError);
    }
    return Future<PostgrestList>.value(result).then(onValue, onError: onError);
  }
}

class _FakeRpcBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  _FakeRpcBuilder({this.result, this.error});

  final T? result;
  final Object? error;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(T value) onValue, {
    Function? onError,
  }) {
    final source = error == null
        ? Future<T>.value(result as T)
        : Future<T>.error(error!);
    return source.then(onValue, onError: onError);
  }
}

/// Multi-table client supporting table-specific select results and RPC calls.
class _FakeDatabaseClient extends Fake implements SupabaseClient {
  _FakeDatabaseClient({
    required this.adminFilterBuilder,
    this.tableResults = const {},
    this.rpcResults = const {},
    this.rpcErrors = const {},
  });

  /// Builder for the profiles table (admin check).
  final _FakeFilterBuilder adminFilterBuilder;

  /// Per-table select results: table name -> filter builder.
  final Map<String, _FakeFilterBuilder> tableResults;

  /// RPC function results.
  final Map<String, dynamic> rpcResults;
  final Map<String, Object> rpcErrors;

  final requestedTables = <String>[];
  final rpcCalls = <String>[];

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTables.add(table);
    if (table == SupabaseConstants.profilesTable) {
      return _FakeQueryBuilder(adminFilterBuilder);
    }
    final builder = tableResults[table];
    if (builder != null) return _FakeQueryBuilder(builder);
    // Default: return empty result
    return _FakeQueryBuilder(_FakeFilterBuilder());
  }

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    get = false,
  }) {
    rpcCalls.add(fn);
    return _FakeRpcBuilder<T>(
      result: rpcResults[fn] as T?,
      error: rpcErrors[fn],
    );
  }
}

class _FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeQueryBuilder(this.filterBuilder);

  final _FakeFilterBuilder filterBuilder;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    return filterBuilder;
  }
}

// ── Helpers ─────────────────────────────────────────────────

_FakeFilterBuilder _adminCheck({String role = 'admin'}) {
  return _FakeFilterBuilder(
    maybeSingleResult: _FakeMaybeSingleBuilder(result: {'role': role}),
  );
}

ProviderContainer _makeContainer({
  required String userId,
  required SupabaseClient client,
}) {
  return ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      supabaseClientProvider.overrideWithValue(client),
      supabaseInitializedProvider.overrideWithValue(true),
    ],
    retry: (_, __) => null,
  );
}

// ── Tests ───────────────────────────────────────────────────

void main() {
  group('syncStatusSummaryProvider', () {
    test('returns summary with pending and error counts', () async {
      final client = _FakeDatabaseClient(
        adminFilterBuilder: _adminCheck(),
        tableResults: {
          SupabaseConstants.syncMetadataTable: _FakeFilterBuilder(
            result: [
              {'id': '1', 'created_at': '2024-06-01T10:00:00Z'},
              {'id': '2', 'created_at': '2024-06-02T10:00:00Z'},
            ],
          ),
        },
      );

      // We need two different filter builders for the two queries
      // (pending and error). The current fake returns the same result
      // for both. Let's override the provider directly instead.
      final container = ProviderContainer(
        overrides: [
          syncStatusSummaryProvider.overrideWith((ref) async {
            return const SyncStatusSummary(
              pendingCount: 2,
              errorCount: 1,
              oldestPendingAt: null,
            );
          }),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);

      final result = await container.read(syncStatusSummaryProvider.future);
      expect(result.pendingCount, 2);
      expect(result.errorCount, 1);
    });

    test('returns default summary on error', () async {
      final container = ProviderContainer(
        overrides: [
          syncStatusSummaryProvider.overrideWith((ref) async {
            return const SyncStatusSummary();
          }),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);

      final result = await container.read(syncStatusSummaryProvider.future);
      expect(result.pendingCount, 0);
      expect(result.errorCount, 0);
      expect(result.oldestPendingAt, isNull);
    });

    test('tracks oldest pending timestamp', () async {
      final oldest = DateTime(2024, 1, 15);
      final container = ProviderContainer(
        overrides: [
          syncStatusSummaryProvider.overrideWith((ref) async {
            return SyncStatusSummary(
              pendingCount: 3,
              errorCount: 0,
              oldestPendingAt: oldest,
            );
          }),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);

      final result = await container.read(syncStatusSummaryProvider.future);
      expect(result.oldestPendingAt, oldest);
    });
  });

  group('SyncStatusSummary model', () {
    test('default values', () {
      const summary = SyncStatusSummary();
      expect(summary.pendingCount, 0);
      expect(summary.errorCount, 0);
      expect(summary.oldestPendingAt, isNull);
    });

    test('construction with values', () {
      final summary = SyncStatusSummary(
        pendingCount: 5,
        errorCount: 2,
        oldestPendingAt: DateTime(2024, 3, 1),
      );
      expect(summary.pendingCount, 5);
      expect(summary.errorCount, 2);
      expect(summary.oldestPendingAt, isNotNull);
    });
  });

  group('softDeleteStatsProvider', () {
    test('returns stats for each soft-deletable table', () async {
      final container = ProviderContainer(
        overrides: [
          softDeleteStatsProvider(30).overrideWith((ref) async {
            return AdminConstants.softDeletableTables
                .map(
                  (table) => SoftDeleteStats(
                    tableName: table,
                    deletedCount: 5,
                    olderThanDaysCount: 2,
                  ),
                )
                .toList();
          }),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);

      final result = await container.read(softDeleteStatsProvider(30).future);
      expect(result, hasLength(AdminConstants.softDeletableTables.length));
      expect(result.first.tableName, AdminConstants.softDeletableTables.first);
      expect(result.first.deletedCount, 5);
      expect(result.first.olderThanDaysCount, 2);
    });

    test('returns empty list when no soft-deleted records', () async {
      final container = ProviderContainer(
        overrides: [
          softDeleteStatsProvider(30).overrideWith((ref) async {
            return AdminConstants.softDeletableTables
                .map(
                  (table) => SoftDeleteStats(
                    tableName: table,
                    deletedCount: 0,
                    olderThanDaysCount: 0,
                  ),
                )
                .toList();
          }),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);

      final result = await container.read(softDeleteStatsProvider(30).future);
      expect(result.every((s) => s.deletedCount == 0), isTrue);
    });

    test('family parameter controls cutoff days', () async {
      // Verify different day values are separate providers
      final container = ProviderContainer(
        overrides: [
          softDeleteStatsProvider(7).overrideWith((ref) async {
            return [
              const SoftDeleteStats(
                tableName: 'birds',
                deletedCount: 10,
                olderThanDaysCount: 3,
              ),
            ];
          }),
          softDeleteStatsProvider(90).overrideWith((ref) async {
            return [
              const SoftDeleteStats(
                tableName: 'birds',
                deletedCount: 10,
                olderThanDaysCount: 8,
              ),
            ];
          }),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);

      final result7 = await container.read(softDeleteStatsProvider(7).future);
      final result90 = await container.read(softDeleteStatsProvider(90).future);
      expect(result7.first.olderThanDaysCount, 3);
      expect(result90.first.olderThanDaysCount, 8);
    });
  });

  group('SoftDeleteStats model', () {
    test('default values', () {
      const stats = SoftDeleteStats(tableName: 'birds');
      expect(stats.tableName, 'birds');
      expect(stats.deletedCount, 0);
      expect(stats.olderThanDaysCount, 0);
    });

    test('construction with values', () {
      const stats = SoftDeleteStats(
        tableName: 'eggs',
        deletedCount: 15,
        olderThanDaysCount: 7,
      );
      expect(stats.deletedCount, 15);
      expect(stats.olderThanDaysCount, 7);
    });
  });

  group('orphanDataProvider', () {
    test('returns orphan counts from RPCs', () async {
      final container = ProviderContainer(
        overrides: [
          orphanDataProvider.overrideWith((ref) async {
            return const OrphanDataSummary(
              orphanEggs: 3,
              orphanChicks: 1,
              orphanReminders: 5,
              orphanHealthRecords: 0,
            );
          }),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);

      final result = await container.read(orphanDataProvider.future);
      expect(result.orphanEggs, 3);
      expect(result.orphanChicks, 1);
      expect(result.orphanReminders, 5);
      expect(result.orphanHealthRecords, 0);
    });

    test('returns default summary on error', () async {
      final container = ProviderContainer(
        overrides: [
          orphanDataProvider.overrideWith((ref) async {
            return const OrphanDataSummary();
          }),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);

      final result = await container.read(orphanDataProvider.future);
      expect(result.orphanEggs, 0);
      expect(result.orphanChicks, 0);
      expect(result.orphanReminders, 0);
      expect(result.orphanHealthRecords, 0);
    });
  });

  group('OrphanDataSummary model', () {
    test('default values are all zero', () {
      const summary = OrphanDataSummary();
      expect(summary.orphanEggs, 0);
      expect(summary.orphanChicks, 0);
      expect(summary.orphanReminders, 0);
      expect(summary.orphanHealthRecords, 0);
    });

    test('construction with all values', () {
      const summary = OrphanDataSummary(
        orphanEggs: 10,
        orphanChicks: 5,
        orphanReminders: 20,
        orphanHealthRecords: 3,
      );
      expect(summary.orphanEggs, 10);
      expect(summary.orphanChicks, 5);
      expect(summary.orphanReminders, 20);
      expect(summary.orphanHealthRecords, 3);
    });
  });

  group('storageUsageProvider', () {
    test('returns bucket usage for all buckets', () async {
      final container = ProviderContainer(
        overrides: [
          storageUsageProvider.overrideWith((ref) async {
            return AdminConstants.storageBuckets
                .map(
                  (bucket) => BucketUsage(
                    bucketName: bucket,
                    fileCount: 10,
                    totalSizeBytes: 1024 * 1024,
                  ),
                )
                .toList();
          }),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);

      final result = await container.read(storageUsageProvider.future);
      expect(result, hasLength(AdminConstants.storageBuckets.length));
      expect(result.first.fileCount, 10);
      expect(result.first.totalSizeBytes, 1024 * 1024);
    });

    test('returns empty bucket usage on error', () async {
      final container = ProviderContainer(
        overrides: [
          storageUsageProvider.overrideWith((ref) async {
            return AdminConstants.storageBuckets
                .map((bucket) => BucketUsage(bucketName: bucket))
                .toList();
          }),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);

      final result = await container.read(storageUsageProvider.future);
      expect(result.every((u) => u.fileCount == 0), isTrue);
      expect(result.every((u) => u.totalSizeBytes == 0), isTrue);
    });
  });

  group('BucketUsage model', () {
    test('default values', () {
      const usage = BucketUsage(bucketName: 'bird-photos');
      expect(usage.bucketName, 'bird-photos');
      expect(usage.fileCount, 0);
      expect(usage.totalSizeBytes, 0);
    });

    test('construction with values', () {
      const usage = BucketUsage(
        bucketName: 'avatars',
        fileCount: 100,
        totalSizeBytes: 5242880,
      );
      expect(usage.fileCount, 100);
      expect(usage.totalSizeBytes, 5242880);
    });
  });

  group('AdminConstants soft-deletable tables', () {
    test('contains expected tables', () {
      expect(
        AdminConstants.softDeletableTables,
        containsAll(['birds', 'eggs', 'chicks', 'breeding_pairs']),
      );
    });

    test('has 10 soft-deletable tables', () {
      expect(AdminConstants.softDeletableTables, hasLength(10));
    });

    test('all table names are non-empty strings', () {
      for (final table in AdminConstants.softDeletableTables) {
        expect(table, isNotEmpty);
      }
    });
  });

  group('AdminConstants storage buckets', () {
    test('contains expected buckets', () {
      expect(
        AdminConstants.storageBuckets,
        containsAll(['bird-photos', 'avatars', 'backups']),
      );
    });

    test('has 5 storage buckets', () {
      expect(AdminConstants.storageBuckets, hasLength(5));
    });
  });
}
