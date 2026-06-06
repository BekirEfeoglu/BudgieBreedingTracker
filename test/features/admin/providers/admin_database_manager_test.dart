// ignore_for_file: unused_element_parameter
import 'dart:async';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_database_manager.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class _FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeQueryBuilder(this.filterBuilder);

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

class _FakeAdminDatabaseClient extends Fake implements SupabaseClient {
  _FakeAdminDatabaseClient({
    required this.adminBuilder,
    this.adminUsersBuilder,
    this.rpcResults = const {},
    this.rpcErrors = const {},
  });

  final _FakeQueryBuilder adminBuilder;
  // Optional builder for `admin_users` so tests that exercise the
  // `requireFounder` path (resetTable / resetAllUserData) can return
  // a non-null row to indicate founder membership. Tests that only
  // touch `requireAdmin` can leave this null.
  final _FakeQueryBuilder? adminUsersBuilder;
  final Map<String, dynamic> rpcResults;
  final Map<String, Object> rpcErrors;
  final requestedTables = <String>[];
  final rpcCalls = <({String fn, Map<String, dynamic>? params})>[];

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTables.add(table);
    if (table == SupabaseConstants.profilesTable) {
      return adminBuilder;
    }
    if (table == SupabaseConstants.adminUsersTable) {
      if (adminUsersBuilder == null) {
        throw StateError(
          'Test reached admin_users table but did not provide adminUsersBuilder',
        );
      }
      return adminUsersBuilder!;
    }
    throw StateError('Unexpected table: $table');
  }

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    get = false,
  }) {
    rpcCalls.add((fn: fn, params: params));
    return _FakeRpcBuilder<T>(
      result: rpcResults[fn] as T?,
      error: rpcErrors[fn],
    );
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
  required _FakeAdminDatabaseClient client,
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

void main() {
  group('AdminDatabaseManager public API', () {
    test(
      'exportTable rejects non-whitelisted tables before Supabase calls',
      () async {
        final client = _FakeAdminDatabaseClient(
          adminBuilder: _FakeQueryBuilder(
            _FakeAdminFilterBuilder(
              _FakeMaybeSingleBuilder(
                result: {'role': 'admin', 'is_active': true},
              ),
            ),
          ),
        );
        final updates = <_StateUpdate>[];
        final container = _makeContainer(userId: 'user-1', client: client);
        addTearDown(container.dispose);

        final result = await _makeManager(
          container,
          updates,
        ).exportTable(SupabaseConstants.adminLogsTable);

        expect(result, isNull);
        expect(client.requestedTables, isEmpty);
        expect(client.rpcCalls, isEmpty);
        expect(updates, hasLength(1));
        expect(updates.single.isLoading, isFalse);
        expect(updates.single.error, contains('admin.invalid_table_name'));
      },
    );

    test(
      'resetTable rejects non-whitelisted tables before Supabase calls',
      () async {
        final client = _FakeAdminDatabaseClient(
          adminBuilder: _FakeQueryBuilder(
            _FakeAdminFilterBuilder(
              _FakeMaybeSingleBuilder(
                result: {'role': 'admin', 'is_active': true},
              ),
            ),
          ),
        );
        final updates = <_StateUpdate>[];
        final container = _makeContainer(userId: 'user-1', client: client);
        addTearDown(container.dispose);

        final result = await _makeManager(
          container,
          updates,
        ).resetTable(SupabaseConstants.systemSettingsTable);

        expect(result, isFalse);
        expect(client.requestedTables, isEmpty);
        expect(client.rpcCalls, isEmpty);
        expect(updates, hasLength(1));
        expect(updates.single.isLoading, isFalse);
        expect(updates.single.error, contains('admin.invalid_table_name'));
      },
    );

    test(
      'exportTable authorizes admin and returns pretty JSON from RPC',
      () async {
        final adminFilter = _FakeAdminFilterBuilder(
          _FakeMaybeSingleBuilder(result: {'role': 'admin', 'is_active': true}),
        );
        final client = _FakeAdminDatabaseClient(
          adminBuilder: _FakeQueryBuilder(adminFilter),
          rpcResults: {
            'admin_export_table': [
              {'id': 1, 'name': 'Kiwi'},
            ],
          },
        );
        final updates = <_StateUpdate>[];
        final container = _makeContainer(userId: 'user-42', client: client);
        addTearDown(container.dispose);

        final result = await _makeManager(
          container,
          updates,
        ).exportTable(SupabaseConstants.birdsTable);

        expect(result, isNotNull);
        expect(result, contains('"id": 1'));
        expect(result, contains('"name": "Kiwi"'));
        expect(client.requestedTables, [SupabaseConstants.profilesTable]);
        expect(client.adminBuilder.selectedColumns, ['role, is_active']);
        expect(adminFilter.eqCalls, hasLength(1));
        expect(adminFilter.eqCalls[0].key, 'id');
        expect(adminFilter.eqCalls[0].value, 'user-42');
        expect(client.rpcCalls, hasLength(1));
        expect(client.rpcCalls.single.fn, 'admin_export_table');
        expect(client.rpcCalls.single.params, {
          'p_table_name': SupabaseConstants.birdsTable,
        });
        expect(updates, hasLength(2));
        expect(updates.first.isLoading, isTrue);
        expect(updates.first.error, isNull);
        expect(updates.first.isSuccess, isFalse);
        expect(updates.last.isLoading, isFalse);
        expect(updates.last.isSuccess, isTrue);
        expect(
          updates.last.successMessage,
          contains('admin.export_table_success'),
        );
      },
    );

    test('resetTable delegates to RPC after founder check', () async {
      // resetTable now goes through requireFounder, which reads BOTH
      // profiles (for the admin gate) AND admin_users (for the
      // founder gate). Provide both fixtures.
      final adminFilter = _FakeAdminFilterBuilder(
        _FakeMaybeSingleBuilder(result: {'role': 'founder', 'is_active': true}),
      );
      final founderFilter = _FakeAdminFilterBuilder(
        _FakeMaybeSingleBuilder(result: {'id': 'admin-row-1'}),
      );
      final client = _FakeAdminDatabaseClient(
        adminBuilder: _FakeQueryBuilder(adminFilter),
        adminUsersBuilder: _FakeQueryBuilder(founderFilter),
        rpcResults: {
          'admin_reset_table': {'rows_deleted': 4},
        },
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'user-9', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(
        container,
        updates,
      ).resetTable(SupabaseConstants.feedbackTable);

      expect(result, isTrue);
      // Both profiles + admin_users must be hit, in that order.
      expect(client.requestedTables, [
        SupabaseConstants.profilesTable,
        SupabaseConstants.adminUsersTable,
      ]);
      expect(client.adminBuilder.selectedColumns, ['role, is_active']);
      expect(adminFilter.eqCalls, hasLength(1));
      expect(adminFilter.eqCalls[0].key, 'id');
      expect(adminFilter.eqCalls[0].value, 'user-9');
      expect(client.rpcCalls, hasLength(1));
      expect(client.rpcCalls.single.fn, 'admin_reset_table');
      expect(client.rpcCalls.single.params, {
        'p_table_name': SupabaseConstants.feedbackTable,
      });
      expect(updates, hasLength(2));
      expect(updates.first.isLoading, isTrue);
      expect(updates.last.isLoading, isFalse);
      expect(updates.last.isSuccess, isTrue);
      expect(
        updates.last.successMessage,
        contains('admin.reset_table_success'),
      );
    });

    test('resetTable fails closed when RPC errors', () async {
      final adminFilter = _FakeAdminFilterBuilder(
        _FakeMaybeSingleBuilder(result: {'role': 'founder', 'is_active': true}),
      );
      final founderFilter = _FakeAdminFilterBuilder(
        _FakeMaybeSingleBuilder(result: {'id': 'admin-row-1'}),
      );
      final client = _FakeAdminDatabaseClient(
        adminBuilder: _FakeQueryBuilder(adminFilter),
        adminUsersBuilder: _FakeQueryBuilder(founderFilter),
        rpcErrors: {'admin_reset_table': StateError('rpc unavailable')},
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'user-9', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(
        container,
        updates,
      ).resetTable(SupabaseConstants.feedbackTable);

      expect(result, isFalse);
      // Founder check runs before the RPC attempt.
      expect(client.requestedTables, [
        SupabaseConstants.profilesTable,
        SupabaseConstants.adminUsersTable,
      ]);
      expect(client.rpcCalls, hasLength(1));
      expect(client.rpcCalls.single.fn, 'admin_reset_table');
      expect(updates.last.isLoading, isFalse);
      // Error must be the localized l10n key (not raw exception text)
      // to avoid leaking internal details to admin UI.
      expect(updates.last.error, 'admin.action_error');
    });
  });

  group('AdminDatabaseManager deletion-order invariants', () {
    const deletionOrder = [
      SupabaseConstants.eventRemindersTable,
      SupabaseConstants.notificationSchedulesTable,
      SupabaseConstants.notificationsTable,
      SupabaseConstants.notificationSettingsTable,
      SupabaseConstants.photosTable,
      SupabaseConstants.growthMeasurementsTable,
      SupabaseConstants.healthRecordsTable,
      SupabaseConstants.eventsTable,
      SupabaseConstants.chicksTable,
      SupabaseConstants.eggsTable,
      SupabaseConstants.incubationsTable,
      SupabaseConstants.clutchesTable,
      SupabaseConstants.breedingPairsTable,
      SupabaseConstants.nestsTable,
      SupabaseConstants.birdsTable,
      SupabaseConstants.userPreferencesTable,
      SupabaseConstants.feedbackTable,
    ];

    test('eventReminders deletes before birds', () {
      expect(
        deletionOrder.indexOf(SupabaseConstants.eventRemindersTable),
        lessThan(deletionOrder.indexOf(SupabaseConstants.birdsTable)),
      );
    });

    test('all deletion order entries are unique', () {
      expect(deletionOrder.toSet().length, deletionOrder.length);
    });
  });
}
