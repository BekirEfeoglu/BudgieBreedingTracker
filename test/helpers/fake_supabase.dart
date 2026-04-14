import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
export 'package:supabase_flutter/supabase_flutter.dart' show PostgrestList;

/// Fake [PostgrestFilterBuilder] for testing remote sources without a real
/// Supabase backend. Captures method calls for assertions and resolves with
/// a preconfigured [result] or [error].
// ignore: must_be_immutable
class FakeFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  FakeFilterBuilder({this.result, this.error});

  T? result;
  Object? error;
  final eqCalls = <MapEntry<String, Object>>[];
  final gtCalls = <MapEntry<String, Object>>[];
  final gteCalls = <MapEntry<String, Object>>[];
  final inFilterCalls = <MapEntry<String, List<dynamic>>>[];
  final orderCalls = <String>[];
  final ltCalls = <MapEntry<String, Object>>[];
  final lteCalls = <MapEntry<String, Object>>[];
  final orCalls = <String>[];
  int? limitValue;

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) {
    eqCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestFilterBuilder<T> gt(String column, Object value) {
    gtCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestFilterBuilder<T> gte(String column, Object value) {
    gteCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestFilterBuilder<T> inFilter(String column, List<dynamic> values) {
    inFilterCalls.add(MapEntry(column, values));
    return this;
  }

  @override
  PostgrestFilterBuilder<T> lt(String column, Object value) {
    ltCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestFilterBuilder<T> lte(String column, Object value) {
    lteCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestTransformBuilder<T> limit(int count, {String? referencedTable}) {
    limitValue = count;
    return this;
  }

  @override
  PostgrestTransformBuilder<T> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    orderCalls.add(column);
    return this;
  }

  @override
  PostgrestFilterBuilder<T> or(String filters, {String? referencedTable}) {
    orCalls.add(filters);
    return this;
  }

  /// Single-record result for [maybeSingle] queries.
  ///
  /// When set, [maybeSingle] returns this value. When null, returns null.
  Map<String, dynamic>? singleResult;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    // Return a FakeFilterBuilder<Map<String, dynamic>?> that resolves with
    // singleResult. We reuse the error field for error propagation.
    final builder = FakeFilterBuilder<Map<String, dynamic>?>(
      result: singleResult,
      error: error,
    );
    return builder;
  }

  @override
  Future<S> then<S>(
    FutureOr<S> Function(T value) onValue, {
    Function? onError,
  }) {
    if (error != null) {
      return Future<T>.error(error!).then(onValue, onError: onError);
    }
    return Future<T>.value(result as T).then(onValue, onError: onError);
  }
}

/// Fake [SupabaseQueryBuilder] that delegates CRUD to [FakeFilterBuilder]
/// instances and captures the upsert payload.
// ignore: must_be_immutable
class FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  FakeQueryBuilder({
    required this.selectBuilder,
    required this.upsertBuilder,
    required this.deleteBuilder,
    FakeFilterBuilder<dynamic>? insertBuilder,
    FakeFilterBuilder<dynamic>? updateBuilder,
  }) : insertBuilder = insertBuilder ?? FakeFilterBuilder<dynamic>(),
       updateBuilder = updateBuilder ?? FakeFilterBuilder<dynamic>();

  final FakeFilterBuilder<PostgrestList> selectBuilder;
  final FakeFilterBuilder<dynamic> upsertBuilder;
  final FakeFilterBuilder<dynamic> insertBuilder;
  final FakeFilterBuilder<dynamic> updateBuilder;
  final FakeFilterBuilder<dynamic> deleteBuilder;
  Object? upsertPayload;
  Object? insertPayload;
  Object? updatePayload;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) =>
      selectBuilder;

  @override
  PostgrestFilterBuilder<dynamic> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
  }) {
    upsertPayload = values;
    return upsertBuilder;
  }

  @override
  PostgrestFilterBuilder<dynamic> insert(
    Object values, {
    bool defaultToNull = true,
  }) {
    insertPayload = values;
    return insertBuilder;
  }

  @override
  PostgrestFilterBuilder<dynamic> update(
    Object values, {
    bool defaultToNull = true,
  }) {
    updatePayload = values;
    return updateBuilder;
  }

  @override
  PostgrestFilterBuilder<dynamic> delete() => deleteBuilder;
}

/// Fake [SupabaseClient] that records which table was requested and delegates
/// to a [FakeQueryBuilder].
class FakeSupabaseClient extends Fake implements SupabaseClient {
  FakeSupabaseClient(this.queryBuilder);

  final FakeQueryBuilder queryBuilder;
  String? requestedTable;

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTable = table;
    return queryBuilder;
  }
}

/// Multi-table fake [SupabaseClient] that routes [from] calls to different
/// query builders based on table name.
class RoutingFakeClient extends Fake implements SupabaseClient {
  final _builders = <String, FakeQueryBuilder>{};
  final requestedTables = <String>[];

  /// Registers a table and returns its builders for result configuration.
  ({
    FakeFilterBuilder<PostgrestList> selectBuilder,
    FakeFilterBuilder<dynamic> insertBuilder,
    FakeFilterBuilder<dynamic> updateBuilder,
    FakeFilterBuilder<dynamic> deleteBuilder,
    FakeQueryBuilder queryBuilder,
  })
  addTable(String table) {
    final selectBuilder = FakeFilterBuilder<PostgrestList>();
    final upsertBuilder = FakeFilterBuilder<dynamic>();
    final insertBuilder = FakeFilterBuilder<dynamic>();
    final updateBuilder = FakeFilterBuilder<dynamic>();
    final deleteBuilder = FakeFilterBuilder<dynamic>();
    final queryBuilder = FakeQueryBuilder(
      selectBuilder: selectBuilder,
      upsertBuilder: upsertBuilder,
      insertBuilder: insertBuilder,
      updateBuilder: updateBuilder,
      deleteBuilder: deleteBuilder,
    );
    _builders[table] = queryBuilder;
    return (
      selectBuilder: selectBuilder,
      insertBuilder: insertBuilder,
      updateBuilder: updateBuilder,
      deleteBuilder: deleteBuilder,
      queryBuilder: queryBuilder,
    );
  }

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTables.add(table);
    final builder = _builders[table];
    if (builder == null) {
      throw StateError('No fake builder registered for table "$table"');
    }
    return builder;
  }
}

/// Convenience factory that creates a complete fake Supabase stack.
///
/// Returns a record with named fields for easy destructuring in tests:
/// ```dart
/// final (:selectBuilder, :queryBuilder, :client) = createFakeSupabaseStack();
/// ```
({
  FakeFilterBuilder<PostgrestList> selectBuilder,
  FakeFilterBuilder<dynamic> upsertBuilder,
  FakeFilterBuilder<dynamic> deleteBuilder,
  FakeQueryBuilder queryBuilder,
  FakeSupabaseClient client,
})
createFakeSupabaseStack() {
  final selectBuilder = FakeFilterBuilder<PostgrestList>();
  final upsertBuilder = FakeFilterBuilder<dynamic>();
  final deleteBuilder = FakeFilterBuilder<dynamic>();
  final queryBuilder = FakeQueryBuilder(
    selectBuilder: selectBuilder,
    upsertBuilder: upsertBuilder,
    deleteBuilder: deleteBuilder,
  );
  final client = FakeSupabaseClient(queryBuilder);
  return (
    selectBuilder: selectBuilder,
    upsertBuilder: upsertBuilder,
    deleteBuilder: deleteBuilder,
    queryBuilder: queryBuilder,
    client: client,
  );
}
