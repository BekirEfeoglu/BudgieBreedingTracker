// ignore_for_file: unused_element_parameter
import 'dart:async';
import 'dart:convert';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/features/admin/constants/admin_constants.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_database_manager.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Fake Supabase builders ──────────────────────────────

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

class _FakeAdminFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  _FakeAdminFilterBuilder(this.maybeSingleBuilder);

  final _FakeMaybeSingleBuilder maybeSingleBuilder;
  final eqCalls = <MapEntry<String, Object>>[];

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    eqCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    return maybeSingleBuilder;
  }
}

class _FakeProfilesQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeProfilesQueryBuilder(this.filterBuilder);

  final _FakeAdminFilterBuilder filterBuilder;
  final selectedColumns = <String>[];

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    selectedColumns.add(columns);
    return filterBuilder;
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

/// Fake range builder that returns chunks of data for paginated selects.
class _FakeRangeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  _FakeRangeFilterBuilder(this.allRows);

  final List<Map<String, dynamic>> allRows;

  @override
  PostgrestTransformBuilder<PostgrestList> range(
    int from,
    int to, {
    String? referencedTable,
  }) {
    return _FakeRangeResultBuilder(allRows, from, to);
  }
}

class _FakeRangeResultBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestList> {
  _FakeRangeResultBuilder(this.allRows, this.from, this.to);

  final List<Map<String, dynamic>> allRows;
  final int from;
  final int to;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestList value) onValue, {
    Function? onError,
  }) {
    final end = (to + 1).clamp(0, allRows.length);
    final start = from.clamp(0, allRows.length);
    final chunk = allRows.sublist(start, end);
    return Future<PostgrestList>.value(chunk).then(onValue, onError: onError);
  }
}

class _FakeChunkedQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeChunkedQueryBuilder(this.allRows);

  final List<Map<String, dynamic>> allRows;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    return _FakeRangeFilterBuilder(allRows);
  }
}

class _FakeChunkedClient extends Fake implements SupabaseClient {
  _FakeChunkedClient({
    required this.adminBuilder,
    this.rpcError,
    this.tableData = const {},
  });

  final _FakeProfilesQueryBuilder adminBuilder;
  final Object? rpcError;
  final Map<String, List<Map<String, dynamic>>> tableData;
  final requestedTables = <String>[];
  final rpcCalls = <({String fn, Map<String, dynamic>? params})>[];

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTables.add(table);
    if (table == SupabaseConstants.profilesTable) {
      return adminBuilder;
    }
    return _FakeChunkedQueryBuilder(tableData[table] ?? []);
  }

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    get = false,
  }) {
    rpcCalls.add((fn: fn, params: params));
    if (rpcError != null) {
      return _FakeRpcBuilder<T>(error: rpcError);
    }
    // Should not reach here in fallback tests — rpc always errors
    return _FakeRpcBuilder<T>(error: StateError('unexpected rpc call'));
  }
}

class _StateUpdate {
  const _StateUpdate({
    this.isLoading,
    this.error,
    this.isSuccess,
    this.successMessage,
  });

  final bool? isLoading;
  final String? error;
  final bool? isSuccess;
  final String? successMessage;
}

ProviderContainer _makeContainer({
  required String userId,
  required _FakeChunkedClient client,
}) {
  return ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      supabaseClientProvider.overrideWithValue(client),
    ],
    retry: (_, __) => null,
  );
}

AdminDatabaseManager _makeManager(
  ProviderContainer container,
  List<_StateUpdate> updates,
) {
  final provider = Provider<AdminDatabaseManager>(
    (ref) => AdminDatabaseManager(ref, ({
      bool? isLoading,
      String? error,
      bool? isSuccess,
      String? successMessage,
    }) {
      updates.add(
        _StateUpdate(
          isLoading: isLoading,
          error: error,
          isSuccess: isSuccess,
          successMessage: successMessage,
        ),
      );
    }),
  );
  return container.read(provider);
}

_FakeChunkedClient _makeClient({
  Map<String, List<Map<String, dynamic>>> tableData = const {},
}) {
  return _FakeChunkedClient(
    adminBuilder: _FakeProfilesQueryBuilder(
      _FakeAdminFilterBuilder(
        _FakeMaybeSingleBuilder(result: {'role': 'admin'}),
      ),
    ),
    rpcError: StateError('rpc unavailable'),
    tableData: tableData,
  );
}

List<Map<String, dynamic>> _generateRows(int count) {
  return List.generate(
    count,
    (i) => {'id': i, 'name': 'Row $i'},
  );
}

void main() {
  group('_formatBytes utility (via exportTable success message)', () {
    // easy_localization is not mounted, so .tr() returns the key.
    // _formatBytes is called and its result is passed as an arg to .tr(),
    // but the l10n key is returned as-is. We verify the format indirectly
    // by checking the JSON output length corresponds to expected ranges.

    test('small data produces valid JSON under 1 KB', () async {
      final client = _makeClient(
        tableData: {
          SupabaseConstants.birdsTable: [
            {'a': 1},
          ],
        },
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .exportTable(SupabaseConstants.birdsTable);

      expect(result, isNotNull);
      expect(result!.length, lessThan(1024)); // under 1 KB
      expect(updates.last.isSuccess, isTrue);
      expect(
        updates.last.successMessage,
        contains('admin.export_table_success'),
      );
    });

    test('medium data produces valid JSON over 1 KB', () async {
      final rows = _generateRows(50);
      final client = _makeClient(
        tableData: {SupabaseConstants.birdsTable: rows},
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .exportTable(SupabaseConstants.birdsTable);

      expect(result, isNotNull);
      expect(result!.length, greaterThan(1024)); // over 1 KB
      expect(updates.last.isSuccess, isTrue);
    });

    test('large data produces valid JSON over 1 MB', () async {
      final bigRow = {'data': 'x' * 10000};
      final rows = List.generate(120, (_) => Map<String, dynamic>.from(bigRow));
      final client = _makeClient(
        tableData: {SupabaseConstants.birdsTable: rows},
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .exportTable(SupabaseConstants.birdsTable);

      expect(result, isNotNull);
      expect(result!.length, greaterThan(1024 * 1024)); // over 1 MB
      expect(updates.last.isSuccess, isTrue);
    });
  });

  group('Chunked export via exportTable fallback', () {
    test('single chunk when rows < chunkSize', () async {
      final rows = _generateRows(10);
      final client = _makeClient(
        tableData: {SupabaseConstants.birdsTable: rows},
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .exportTable(SupabaseConstants.birdsTable);

      expect(result, isNotNull);
      final decoded = jsonDecode(result!) as List;
      expect(decoded.length, 10);
      expect(decoded.first, {'id': 0, 'name': 'Row 0'});
      expect(decoded.last, {'id': 9, 'name': 'Row 9'});
      expect(updates.last.isSuccess, isTrue);
    });

    test('multiple chunks when rows > chunkSize', () async {
      // chunkSize is 500, so 750 rows should cause 2 chunks
      final rows = _generateRows(750);
      final client = _makeClient(
        tableData: {SupabaseConstants.birdsTable: rows},
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .exportTable(SupabaseConstants.birdsTable);

      expect(result, isNotNull);
      final decoded = jsonDecode(result!) as List;
      expect(decoded.length, 750);
    });

    test('exact boundary: rows == chunkSize', () async {
      final rows = _generateRows(AdminConstants.exportChunkSize);
      final client = _makeClient(
        tableData: {SupabaseConstants.birdsTable: rows},
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .exportTable(SupabaseConstants.birdsTable);

      expect(result, isNotNull);
      final decoded = jsonDecode(result!) as List;
      expect(decoded.length, AdminConstants.exportChunkSize);
    });

    test('empty table returns empty JSON array', () async {
      final client = _makeClient(
        tableData: {SupabaseConstants.birdsTable: []},
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .exportTable(SupabaseConstants.birdsTable);

      expect(result, isNotNull);
      final decoded = jsonDecode(result!) as List;
      expect(decoded, isEmpty);
      expect(updates.last.isSuccess, isTrue);
    });

    test('rpc is attempted first, then falls back to chunked', () async {
      final rows = _generateRows(5);
      final client = _makeClient(
        tableData: {SupabaseConstants.birdsTable: rows},
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      await _makeManager(container, updates)
          .exportTable(SupabaseConstants.birdsTable);

      // RPC was attempted
      expect(client.rpcCalls, hasLength(1));
      expect(client.rpcCalls.single.fn, 'admin_export_table');
      // Fallback queried the table directly
      expect(
        client.requestedTables,
        contains(SupabaseConstants.birdsTable),
      );
    });

    test('state transitions: loading then success', () async {
      final client = _makeClient(
        tableData: {SupabaseConstants.birdsTable: _generateRows(3)},
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      await _makeManager(container, updates)
          .exportTable(SupabaseConstants.birdsTable);

      expect(updates.first.isLoading, isTrue);
      expect(updates.first.error, isNull);
      expect(updates.first.isSuccess, isFalse);
      expect(updates.last.isLoading, isFalse);
      expect(updates.last.isSuccess, isTrue);
      expect(updates.last.successMessage, isNotNull);
    });

    test('result is pretty-printed JSON', () async {
      final client = _makeClient(
        tableData: {
          SupabaseConstants.birdsTable: [
            {'id': 1, 'name': 'Kiwi'},
          ],
        },
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .exportTable(SupabaseConstants.birdsTable);

      expect(result, contains('\n'));
      expect(result, contains('  '));
      expect(result, contains('"name": "Kiwi"'));
    });
  });

  group('exportTable rejection', () {
    test('rejects non-whitelisted table', () async {
      final client = _makeClient();
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .exportTable('secret_table');

      expect(result, isNull);
      expect(updates.single.isLoading, isFalse);
      expect(updates.single.error, contains('admin.invalid_table_name'));
      expect(client.rpcCalls, isEmpty);
    });
  });
}
