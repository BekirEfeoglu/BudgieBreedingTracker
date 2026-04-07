import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/features/admin/constants/admin_constants.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_capacity_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

// --- Fakes for provider-level tests ---

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
  _FakeFilterBuilder(this.maybeSingleBuilder);

  final _FakeMaybeSingleBuilder maybeSingleBuilder;

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() => maybeSingleBuilder;
}

class _FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeQueryBuilder(this.filterBuilder);

  final _FakeFilterBuilder filterBuilder;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) =>
      filterBuilder;
}

class _FakeCapacityClient extends Fake implements SupabaseClient {
  _FakeCapacityClient({
    required this.adminQueryBuilder,
    this.rpcError,
    this.rpcResult,
  });

  final _FakeQueryBuilder adminQueryBuilder;
  final Object? rpcError;
  final dynamic rpcResult;

  @override
  SupabaseQueryBuilder from(String table) {
    if (table == SupabaseConstants.adminUsersTable) return adminQueryBuilder;
    throw StateError('Unexpected table: $table');
  }

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    get = false,
  }) {
    return _FakeRpcBuilder<T>(result: rpcResult as T?, error: rpcError);
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

/// Tests for admin capacity models and computed properties.
///
/// The [adminDatabaseInfoProvider] and [serverCapacityProvider] are
/// FutureProviders that require Supabase RPC calls and admin auth.
/// These tests focus on the model logic and computed properties.
void main() {
  group('ServerCapacity', () {
    test('connectionUsageRatio calculates correctly', () {
      const capacity = ServerCapacity(
        totalConnections: 30,
        maxConnections: 60,
      );
      expect(capacity.connectionUsageRatio, closeTo(0.5, 0.001));
    });

    test('connectionUsageRatio is 0 when maxConnections is 0', () {
      const capacity = ServerCapacity(
        totalConnections: 10,
        maxConnections: 0,
      );
      expect(capacity.connectionUsageRatio, 0);
    });

    test('connectionUsageRatio at full capacity', () {
      const capacity = ServerCapacity(
        totalConnections: 60,
        maxConnections: 60,
      );
      expect(capacity.connectionUsageRatio, closeTo(1.0, 0.001));
    });

    test('connectionUsageRatio over capacity', () {
      const capacity = ServerCapacity(
        totalConnections: 70,
        maxConnections: 60,
      );
      expect(capacity.connectionUsageRatio, greaterThan(1.0));
    });

    test('default values are sensible', () {
      const capacity = ServerCapacity();
      expect(capacity.databaseSizeBytes, 0);
      expect(capacity.activeConnections, 0);
      expect(capacity.totalConnections, 0);
      expect(capacity.maxConnections, 60);
      expect(capacity.cacheHitRatio, 0);
      expect(capacity.totalRows, 0);
      expect(capacity.indexHitRatio, 0);
      expect(capacity.tables, isEmpty);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'database_size_bytes': 1024000,
        'active_connections': 5,
        'total_connections': 15,
        'max_connections': 100,
        'cache_hit_ratio': 0.99,
        'total_rows': 5000,
        'index_hit_ratio': 0.95,
        'tables': <Map<String, dynamic>>[],
      };
      final capacity = ServerCapacity.fromJson(json);

      expect(capacity.databaseSizeBytes, 1024000);
      expect(capacity.activeConnections, 5);
      expect(capacity.totalConnections, 15);
      expect(capacity.maxConnections, 100);
      expect(capacity.cacheHitRatio, closeTo(0.99, 0.001));
      expect(capacity.totalRows, 5000);
    });
  });

  group('TableCapacity', () {
    test('default values', () {
      const table = TableCapacity();
      expect(table.name, '');
      expect(table.sizeBytes, 0);
      expect(table.rowCount, 0);
      expect(table.deadTupleCount, 0);
      expect(table.deadTupleRatio, 0);
      expect(table.lastVacuum, isNull);
      expect(table.lastAnalyze, isNull);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'name': 'birds',
        'size_bytes': 2048,
        'row_count': 150,
        'dead_tuple_count': 5,
        'dead_tuple_ratio': 0.03,
        'last_vacuum': '2025-06-01',
        'last_analyze': '2025-06-01',
      };
      final table = TableCapacity.fromJson(json);

      expect(table.name, 'birds');
      expect(table.sizeBytes, 2048);
      expect(table.rowCount, 150);
      expect(table.deadTupleCount, 5);
    });
  });

  group('TableInfo', () {
    test('default values', () {
      const info = TableInfo();
      expect(info.name, '');
      expect(info.rowCount, 0);
    });

    test('fromJson with table_name key mapping', () {
      final json = {'table_name': 'birds', 'row_count': 42};
      final info = TableInfo.fromJson(json);

      expect(info.name, 'birds');
      expect(info.rowCount, 42);
    });
  });

  group('ServerCapacity critical threshold detection', () {
    test('below 90% threshold is non-critical', () {
      final dbLimit = AdminConstants.dbSizeLimitForPlan('pro');
      const capacity = ServerCapacity(
        databaseSizeBytes: 4 * 1024 * 1024 * 1024, // 4 GB of 8 GB
        totalConnections: 50,
        maxConnections: 60,
      );
      final dbRatio = capacity.databaseSizeBytes / dbLimit;
      final connRatio = capacity.connectionUsageRatio;
      final worstRatio = math.max(dbRatio, connRatio);

      expect(worstRatio, lessThan(AdminConstants.capacityWarningPercent));
    });

    test('above 90% DB threshold is critical', () {
      final dbLimit = AdminConstants.dbSizeLimitForPlan('pro');
      final criticalDbSize = (dbLimit * 0.95).toInt(); // 95% of 8 GB
      final capacity = ServerCapacity(
        databaseSizeBytes: criticalDbSize,
        totalConnections: 10,
        maxConnections: 60,
      );
      final dbRatio = capacity.databaseSizeBytes / dbLimit;

      expect(dbRatio, greaterThanOrEqualTo(AdminConstants.capacityWarningPercent));
    });

    test('above 90% connection threshold is critical', () {
      final dbLimit = AdminConstants.dbSizeLimitForPlan('pro');
      const capacity = ServerCapacity(
        databaseSizeBytes: 100 * 1024 * 1024, // 100 MB — low DB
        totalConnections: 56,
        maxConnections: 60, // 93% connections
      );
      final dbRatio = capacity.databaseSizeBytes / dbLimit;
      final connRatio = capacity.connectionUsageRatio;
      final worstRatio = math.max(dbRatio, connRatio);

      expect(dbRatio, lessThan(AdminConstants.capacityWarningPercent));
      expect(connRatio, greaterThanOrEqualTo(AdminConstants.capacityWarningPercent));
      expect(worstRatio, greaterThanOrEqualTo(AdminConstants.capacityWarningPercent));
    });

    test('worst-of-two logic picks the higher ratio', () {
      final dbLimit = AdminConstants.dbSizeLimitForPlan('pro');
      const capacity = ServerCapacity(
        databaseSizeBytes: 2 * 1024 * 1024 * 1024, // 25% DB
        totalConnections: 55,
        maxConnections: 60, // ~92% connections
      );
      final dbRatio = capacity.databaseSizeBytes / dbLimit;
      final connRatio = capacity.connectionUsageRatio;
      final worstRatio = math.max(dbRatio, connRatio);

      expect(worstRatio, connRatio);
      expect(worstRatio, greaterThanOrEqualTo(AdminConstants.capacityWarningPercent));
    });
  });

  group('AdminConstants.dbSizeLimitForPlan', () {
    test('returns 500 MB for free plan', () {
      expect(
        AdminConstants.dbSizeLimitForPlan('free'),
        500 * 1024 * 1024,
      );
    });

    test('returns 8 GB for pro plan', () {
      expect(
        AdminConstants.dbSizeLimitForPlan('pro'),
        8 * 1024 * 1024 * 1024,
      );
    });

    test('returns 8 GB for team plan', () {
      expect(
        AdminConstants.dbSizeLimitForPlan('team'),
        8 * 1024 * 1024 * 1024,
      );
    });

    test('returns 16 GB for enterprise plan', () {
      expect(
        AdminConstants.dbSizeLimitForPlan('enterprise'),
        16 * 1024 * 1024 * 1024,
      );
    });

    test('returns default for unknown plan', () {
      expect(
        AdminConstants.dbSizeLimitForPlan('unknown_plan'),
        AdminConstants.dbSizeLimitDefault,
      );
    });

    test('is case-insensitive', () {
      expect(
        AdminConstants.dbSizeLimitForPlan('Pro'),
        AdminConstants.dbSizeLimitForPlan('pro'),
      );
    });
  });

  group('serverCapacityProvider error states', () {
    test('throws when user is anonymous (requireAdmin fails)', () async {
      final adminFilter = _FakeFilterBuilder(
        _FakeMaybeSingleBuilder(result: {'id': 'a1'}),
      );
      final client = _FakeCapacityClient(
        adminQueryBuilder: _FakeQueryBuilder(adminFilter),
        rpcResult: <String, dynamic>{},
      );

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('anonymous'),
          supabaseClientProvider.overrideWithValue(client),
        ],
        retry: (_, __) => null,
      );
      final sub = container.listen(serverCapacityProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      await expectLater(
        container.read(serverCapacityProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when admin row is missing (requireAdmin fails)', () async {
      final adminFilter = _FakeFilterBuilder(
        _FakeMaybeSingleBuilder(result: null),
      );
      final client = _FakeCapacityClient(
        adminQueryBuilder: _FakeQueryBuilder(adminFilter),
        rpcResult: <String, dynamic>{},
      );

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          supabaseClientProvider.overrideWithValue(client),
        ],
        retry: (_, __) => null,
      );
      final sub = container.listen(serverCapacityProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      await expectLater(
        container.read(serverCapacityProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('adminDatabaseInfoProvider error states', () {
    test('throws when user is anonymous (requireAdmin fails)', () async {
      final adminFilter = _FakeFilterBuilder(
        _FakeMaybeSingleBuilder(result: {'id': 'a1'}),
      );
      final client = _FakeCapacityClient(
        adminQueryBuilder: _FakeQueryBuilder(adminFilter),
      );

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('anonymous'),
          supabaseClientProvider.overrideWithValue(client),
        ],
        retry: (_, __) => null,
      );
      final sub = container.listen(adminDatabaseInfoProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      await expectLater(
        container.read(adminDatabaseInfoProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
