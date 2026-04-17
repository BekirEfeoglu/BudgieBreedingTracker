// ignore_for_file: unused_element_parameter
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
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
  });

  final _FakeMaybeSingleBuilder maybeSingleBuilder;
  final List<Map<String, dynamic>> listResult;
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
    if (table == SupabaseConstants.profilesTable) {
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
            maybeSingleBuilder: _FakeMaybeSingleBuilder(result: {'role': 'admin'}),
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
      });

      await expectLater(
        container.read(monitoringSnapshotsProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('returns empty trend when no snapshot rows exist', () async {
      final adminFilter = _FakeFilterBuilder(
        maybeSingleBuilder: _FakeMaybeSingleBuilder(result: {'role': 'admin'}),
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
            result: {'role': 'admin'},
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
        });

        final trend = await container.read(monitoringSnapshotsProvider.future);

        expect(client.requestedTables, [
          SupabaseConstants.profilesTable,
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
  });

  group('monitoringSnapshotsProvider malformed payloads', () {
    test('skips slow_queries entries that are not maps', () async {
      final adminFilter = _FakeFilterBuilder(
        maybeSingleBuilder: _FakeMaybeSingleBuilder(
          result: {'role': 'admin'},
        ),
      );
      final snapshotFilter = _FakeFilterBuilder(
        maybeSingleBuilder: _FakeMaybeSingleBuilder(),
        listResult: [
          {
            'snapshot_type': 'slow_queries',
            'created_at': '2026-03-31T09:00:00Z',
            'data': {
              'queries': [
                'not-a-map',
                42,
                {
                  'calls': 3,
                  'total_time_ms': 300,
                  'mean_time_ms': 100,
                  'query': 'SELECT 1',
                },
              ],
            },
          },
        ],
      );
      final client = _FakeAdminMonitoringClient(
        adminBuilder: _FakeQueryBuilder(adminFilter),
        snapshotBuilder: _FakeQueryBuilder(snapshotFilter),
      );

      final container = _makeContainer(userId: 'user-1', client: client);
      addTearDown(container.dispose);
      final sub = container.listen(monitoringSnapshotsProvider, (_, __) {});
      addTearDown(sub.close);

      final trend = await container.read(monitoringSnapshotsProvider.future);

      expect(trend.slowQueries, hasLength(1));
      expect(trend.slowQueries.first.query, 'SELECT 1');
    });

    test('tolerates non-map connection state entries', () async {
      final adminFilter = _FakeFilterBuilder(
        maybeSingleBuilder: _FakeMaybeSingleBuilder(
          result: {'role': 'admin'},
        ),
      );
      final snapshotFilter = _FakeFilterBuilder(
        maybeSingleBuilder: _FakeMaybeSingleBuilder(),
        listResult: [
          {
            'snapshot_type': 'connections',
            'created_at': '2026-03-31T10:00:00Z',
            'data': {
              'total': 2,
              'max_connections': 100,
              'states': [
                'garbage',
                {'state': 'active', 'count': 2},
              ],
            },
          },
        ],
      );
      final client = _FakeAdminMonitoringClient(
        adminBuilder: _FakeQueryBuilder(adminFilter),
        snapshotBuilder: _FakeQueryBuilder(snapshotFilter),
      );

      final container = _makeContainer(userId: 'user-1', client: client);
      addTearDown(container.dispose);
      final sub = container.listen(monitoringSnapshotsProvider, (_, __) {});
      addTearDown(sub.close);

      final trend = await container.read(monitoringSnapshotsProvider.future);

      expect(trend.connectionStates, hasLength(1));
      expect(trend.connectionStates.first.state, 'active');
      expect(trend.connectionStates.first.count, 2);
    });

    test('treats non-map data field as empty without crashing', () async {
      final adminFilter = _FakeFilterBuilder(
        maybeSingleBuilder: _FakeMaybeSingleBuilder(
          result: {'role': 'admin'},
        ),
      );
      final snapshotFilter = _FakeFilterBuilder(
        maybeSingleBuilder: _FakeMaybeSingleBuilder(),
        listResult: [
          {
            'snapshot_type': 'slow_queries',
            'created_at': '2026-03-31T09:00:00Z',
            'data': 'unexpected-string-instead-of-map',
          },
        ],
      );
      final client = _FakeAdminMonitoringClient(
        adminBuilder: _FakeQueryBuilder(adminFilter),
        snapshotBuilder: _FakeQueryBuilder(snapshotFilter),
      );

      final container = _makeContainer(userId: 'user-1', client: client);
      addTearDown(container.dispose);
      final sub = container.listen(monitoringSnapshotsProvider, (_, __) {});
      addTearDown(sub.close);

      final trend = await container.read(monitoringSnapshotsProvider.future);

      expect(trend.slowQueries, isEmpty);
    });
  });

  group('MonitoringSnapshot.fromJson', () {
    test('parses well-formed payload', () {
      final snapshot = MonitoringSnapshot.fromJson({
        'snapshot_type': 'connections',
        'data': {'total': 1},
        'created_at': '2026-03-31T10:00:00Z',
      });

      expect(snapshot.snapshotType, 'connections');
      expect(snapshot.data, {'total': 1});
    });

    test('throws ValidationException when snapshot_type missing', () {
      expect(
        () => MonitoringSnapshot.fromJson({
          'data': {'total': 1},
          'created_at': '2026-03-31T10:00:00Z',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws ValidationException when snapshot_type is empty', () {
      expect(
        () => MonitoringSnapshot.fromJson({
          'snapshot_type': '',
          'data': {'total': 1},
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws ValidationException when snapshot_type is not a String', () {
      expect(
        () => MonitoringSnapshot.fromJson({
          'snapshot_type': 42,
          'data': {'total': 1},
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('falls back to empty map for non-map data field', () {
      final snapshot = MonitoringSnapshot.fromJson({
        'snapshot_type': 'connections',
        'data': 'not-a-map',
        'created_at': '2026-03-31T10:00:00Z',
      });

      expect(snapshot.data, isEmpty);
    });
  });

  group('cronJobStatusProvider', () {
    test('returns rpc payload for authenticated admin', () async {
      final client = _FakeAdminMonitoringClient(
        adminBuilder: _FakeQueryBuilder(
          _FakeFilterBuilder(
            maybeSingleBuilder: _FakeMaybeSingleBuilder(result: {'role': 'admin'}),
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
      });

      final result = await container.read(cronJobStatusProvider.future);

      expect(result, {'status': 'ok', 'jobs': 2});
      expect(client.rpcCalls, ['verify_monitoring_cron_jobs']);
    });

    test('returns error payload when rpc throws', () async {
      final client = _FakeAdminMonitoringClient(
        adminBuilder: _FakeQueryBuilder(
          _FakeFilterBuilder(
            maybeSingleBuilder: _FakeMaybeSingleBuilder(result: {'role': 'admin'}),
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
      });

      final result = await container.read(cronJobStatusProvider.future);

      expect(result['status'], 'error');
      expect(result['message'], contains('rpc failed'));
      expect(client.rpcCalls, ['verify_monitoring_cron_jobs']);
    });
  });
}
