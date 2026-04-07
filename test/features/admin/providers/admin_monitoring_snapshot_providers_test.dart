// ignore_for_file: unused_element_parameter
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_monitoring_snapshot_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

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
    required this.maybeSingleBuilder,
    this.listResult = const [],
    this.listError,
  });

  final _FakeMaybeSingleBuilder maybeSingleBuilder;
  final List<Map<String, dynamic>> listResult;
  final Object? listError;
  final eqCalls = <MapEntry<String, Object>>[];
  final gteCalls = <MapEntry<String, Object>>[];
  final orderCalls = <({String column, bool ascending})>[];
  final limitCalls = <int>[];

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    eqCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestFilterBuilder<PostgrestList> gte(String column, Object value) {
    gteCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestList> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    orderCalls.add((column: column, ascending: ascending));
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestList> limit(
    int count, {
    String? referencedTable,
  }) {
    limitCalls.add(count);
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    return maybeSingleBuilder;
  }

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestList value) onValue, {
    Function? onError,
  }) {
    if (listError != null) {
      return Future<PostgrestList>.error(listError!).then(onValue,
          onError: onError);
    }
    return Future<S>.value(onValue(listResult));
  }
}

class _FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeQueryBuilder(this.filterBuilder);

  final _FakeFilterBuilder filterBuilder;
  final selectedColumns = <String>[];

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    selectedColumns.add(columns);
    return filterBuilder;
  }
}

class _FakeAdminMonitoringClient extends Fake implements SupabaseClient {
  _FakeAdminMonitoringClient({
    required this.adminBuilder,
    required this.snapshotBuilder,
    this.rpcResult,
    this.rpcError,
  });

  final _FakeQueryBuilder adminBuilder;
  final _FakeQueryBuilder snapshotBuilder;
  final Map<String, dynamic>? rpcResult;
  final Object? rpcError;
  final requestedTables = <String>[];
  final rpcCalls = <String>[];

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTables.add(table);
    if (table == SupabaseConstants.adminUsersTable) {
      return adminBuilder;
    }
    if (table == SupabaseConstants.dbMonitoringSnapshotsTable) {
      return snapshotBuilder;
    }
    throw StateError('Unexpected table: $table');
  }

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    get = false,
  }) {
    rpcCalls.add(fn);
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

ProviderContainer _makeContainer({
  required String userId,
  required _FakeAdminMonitoringClient client,
}) {
  return ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      supabaseClientProvider.overrideWithValue(client),
    ],
    retry: (_, __) => null,
  );
}

void main() {
  group('monitoringSnapshotsProvider', () {
    test('throws for anonymous user', () async {
      final client = _FakeAdminMonitoringClient(
        adminBuilder: _FakeQueryBuilder(
          _FakeFilterBuilder(
            maybeSingleBuilder: _FakeMaybeSingleBuilder(result: {'id': 'a1'}),
          ),
        ),
        snapshotBuilder: _FakeQueryBuilder(
          _FakeFilterBuilder(maybeSingleBuilder: _FakeMaybeSingleBuilder()),
        ),
      );

      final container = _makeContainer(userId: 'anonymous', client: client);
      final sub = container.listen(monitoringSnapshotsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      await expectLater(
        container.read(monitoringSnapshotsProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('returns empty trend when no snapshot rows exist', () async {
      final adminFilter = _FakeFilterBuilder(
        maybeSingleBuilder: _FakeMaybeSingleBuilder(result: {'id': 'admin-1'}),
      );
      final snapshotFilter = _FakeFilterBuilder(
        maybeSingleBuilder: _FakeMaybeSingleBuilder(),
        listResult: const [],
      );
      final client = _FakeAdminMonitoringClient(
        adminBuilder: _FakeQueryBuilder(adminFilter),
        snapshotBuilder: _FakeQueryBuilder(snapshotFilter),
      );

      final container = _makeContainer(userId: 'user-1', client: client);
      final sub = container.listen(monitoringSnapshotsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final trend = await container.read(monitoringSnapshotsProvider.future);

      expect(trend.slowQueries, isEmpty);
      expect(trend.connectionStates, isEmpty);
      expect(trend.totalConnections, 0);
      expect(trend.maxConnections, 0);
    });

    test(
      'parses latest snapshots and applies expected query modifiers',
      () async {
        final adminFilter = _FakeFilterBuilder(
          maybeSingleBuilder: _FakeMaybeSingleBuilder(
            result: {'id': 'admin-1'},
          ),
        );
        final snapshotFilter = _FakeFilterBuilder(
          maybeSingleBuilder: _FakeMaybeSingleBuilder(),
          listResult: [
            {
              'snapshot_type': 'connections',
              'created_at': '2026-03-31T10:00:00Z',
              'data': {
                'total': 15,
                'max_connections': 100,
                'states': [
                  {'state': 'active', 'count': 5},
                  {'state': 'idle', 'count': 10},
                ],
              },
            },
            {
              'snapshot_type': 'slow_queries',
              'created_at': '2026-03-31T09:00:00Z',
              'data': {
                'queries': [
                  {
                    'calls': 12,
                    'total_time_ms': 1500,
                    'mean_time_ms': 125,
                    'query': 'SELECT * FROM birds',
                  },
                ],
              },
            },
          ],
        );
        final snapshotQuery = _FakeQueryBuilder(snapshotFilter);
        final client = _FakeAdminMonitoringClient(
          adminBuilder: _FakeQueryBuilder(adminFilter),
          snapshotBuilder: snapshotQuery,
        );

        final container = _makeContainer(userId: 'user-1', client: client);
        final sub = container.listen(monitoringSnapshotsProvider, (_, __) {});
        addTearDown(() {
          sub.close();
          container.dispose();
        });

        final trend = await container.read(monitoringSnapshotsProvider.future);

        expect(client.requestedTables, [
          SupabaseConstants.adminUsersTable,
          SupabaseConstants.dbMonitoringSnapshotsTable,
        ]);
        expect(snapshotQuery.selectedColumns, [
          'snapshot_type, data, created_at',
        ]);
        expect(snapshotFilter.gteCalls.single.key, 'created_at');
        expect(snapshotFilter.orderCalls.single.column, 'created_at');
        expect(snapshotFilter.orderCalls.single.ascending, isFalse);
        expect(snapshotFilter.limitCalls.single, 10);

        expect(trend.slowQueries, hasLength(1));
        expect(trend.slowQueries.first.calls, 12);
        expect(trend.slowQueries.first.meanTimeMs, 125);
        expect(trend.slowQueries.first.query, 'SELECT * FROM birds');

        expect(trend.connectionStates, hasLength(2));
        expect(trend.connectionStates.first.state, 'active');
        expect(trend.connectionStates.first.count, 5);
        expect(trend.totalConnections, 15);
        expect(trend.maxConnections, 100);
        expect(trend.capturedAt, DateTime.parse('2026-03-31T10:00:00Z'));
      },
    );

    test('rethrows when snapshot query fails', () async {
      final adminFilter = _FakeFilterBuilder(
        maybeSingleBuilder: _FakeMaybeSingleBuilder(result: {'id': 'admin-1'}),
      );
      final snapshotFilter = _FakeFilterBuilder(
        maybeSingleBuilder: _FakeMaybeSingleBuilder(),
        listError: StateError('snapshot query failed'),
      );
      final client = _FakeAdminMonitoringClient(
        adminBuilder: _FakeQueryBuilder(adminFilter),
        snapshotBuilder: _FakeQueryBuilder(snapshotFilter),
      );

      final container = _makeContainer(userId: 'user-1', client: client);
      final sub = container.listen(monitoringSnapshotsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      await expectLater(
        container.read(monitoringSnapshotsProvider.future),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('cronJobStatusProvider', () {
    test('returns rpc payload for authenticated admin', () async {
      final client = _FakeAdminMonitoringClient(
        adminBuilder: _FakeQueryBuilder(
          _FakeFilterBuilder(
            maybeSingleBuilder: _FakeMaybeSingleBuilder(result: {'id': 'a1'}),
          ),
        ),
        snapshotBuilder: _FakeQueryBuilder(
          _FakeFilterBuilder(maybeSingleBuilder: _FakeMaybeSingleBuilder()),
        ),
        rpcResult: {'status': 'ok', 'jobs': 2},
      );

      final container = _makeContainer(userId: 'user-1', client: client);
      final sub = container.listen(cronJobStatusProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final result = await container.read(cronJobStatusProvider.future);

      expect(result, {'status': 'ok', 'jobs': 2});
      expect(client.rpcCalls, ['verify_monitoring_cron_jobs']);
    });

    test('throws for anonymous user', () async {
      final client = _FakeAdminMonitoringClient(
        adminBuilder: _FakeQueryBuilder(
          _FakeFilterBuilder(
            maybeSingleBuilder: _FakeMaybeSingleBuilder(result: {'id': 'a1'}),
          ),
        ),
        snapshotBuilder: _FakeQueryBuilder(
          _FakeFilterBuilder(maybeSingleBuilder: _FakeMaybeSingleBuilder()),
        ),
        rpcResult: {'status': 'ok'},
      );

      final container = _makeContainer(userId: 'anonymous', client: client);
      final sub = container.listen(cronJobStatusProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      await expectLater(
        container.read(cronJobStatusProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('returns error payload when rpc throws', () async {
      final client = _FakeAdminMonitoringClient(
        adminBuilder: _FakeQueryBuilder(
          _FakeFilterBuilder(
            maybeSingleBuilder: _FakeMaybeSingleBuilder(result: {'id': 'a1'}),
          ),
        ),
        snapshotBuilder: _FakeQueryBuilder(
          _FakeFilterBuilder(maybeSingleBuilder: _FakeMaybeSingleBuilder()),
        ),
        rpcError: StateError('rpc failed'),
      );

      final container = _makeContainer(userId: 'user-1', client: client);
      final sub = container.listen(cronJobStatusProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final result = await container.read(cronJobStatusProvider.future);

      expect(result['status'], 'error');
      expect(result['message'], contains('rpc failed'));
      expect(client.rpcCalls, ['verify_monitoring_cron_jobs']);
    });
  });
}
