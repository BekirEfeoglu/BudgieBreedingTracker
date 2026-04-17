// ignore_for_file: unused_element_parameter, must_be_immutable
import 'dart:async';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/features/admin/constants/admin_constants.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_maintenance_manager.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Fake Supabase builders (same pattern as admin_notification_manager_test.dart)
// ---------------------------------------------------------------------------

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

class _FakeAdminCheckBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  _FakeAdminCheckBuilder({this.result});

  final PostgrestMap? result;

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() =>
      _FakeMaybeSingleBuilder(result: result);
}

class _FakeAdminQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeAdminQueryBuilder(this.filterBuilder);

  final _FakeAdminCheckBuilder filterBuilder;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) =>
      filterBuilder;
}

/// Fake for the result of `.select('id')` — resolves to a List.
class _FakeSelectBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestList> {
  _FakeSelectBuilder({this.selectResult});

  final List<dynamic>? selectResult;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestList value) onValue, {
    Function? onError,
  }) {
    final result = (selectResult ?? <dynamic>[]).cast<Map<String, dynamic>>();
    return Future<PostgrestList>.value(result).then(onValue, onError: onError);
  }
}

class _FakeMutationBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  _FakeMutationBuilder({this.error, this.selectResult});

  final Object? error;
  final List<dynamic>? selectResult;

  @override
  PostgrestFilterBuilder<dynamic> eq(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<dynamic> lt(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<PostgrestList> select([String columns = '*']) =>
      _FakeSelectBuilder(selectResult: selectResult);

  @override
  Future<S> then<S>(
    FutureOr<S> Function(dynamic value) onValue, {
    Function? onError,
  }) {
    if (error != null) {
      return Future<dynamic>.error(error!).then(onValue, onError: onError);
    }
    return Future<dynamic>.value(null).then(onValue, onError: onError);
  }
}

class _FakeMutationQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeMutationQueryBuilder({
    this.insertError,
    this.mutationBuilder,
  });

  final Object? insertError;
  final _FakeMutationBuilder? mutationBuilder;
  Object? insertPayload;
  int insertCallCount = 0;

  @override
  PostgrestFilterBuilder<dynamic> insert(
    Object values, {
    bool defaultToNull = true,
  }) {
    insertPayload = values;
    insertCallCount++;
    return _FakeMutationBuilder(error: insertError);
  }

  @override
  PostgrestFilterBuilder<dynamic> update(
    Object values, {
    bool defaultToNull = true,
  }) =>
      mutationBuilder ?? _FakeMutationBuilder();

  @override
  PostgrestFilterBuilder<dynamic> delete() =>
      mutationBuilder ?? _FakeMutationBuilder();

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) =>
      _FakeAdminCheckBuilder();
}

// ---------------------------------------------------------------------------
// Fake SupabaseClient
// ---------------------------------------------------------------------------

class _FakeMaintenanceClient extends Fake implements SupabaseClient {
  _FakeMaintenanceClient({
    required this.adminQueryBuilder,
    required this.adminLogsQueryBuilder,
    this.securityEventsQueryBuilder,
    this.syncMetadataQueryBuilder,
    this.genericTableBuilder,
  });

  final _FakeAdminQueryBuilder adminQueryBuilder;
  final _FakeMutationQueryBuilder adminLogsQueryBuilder;
  final _FakeMutationQueryBuilder? securityEventsQueryBuilder;
  final _FakeMutationQueryBuilder? syncMetadataQueryBuilder;
  final _FakeMutationQueryBuilder? genericTableBuilder;
  final requestedTables = <String>[];

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTables.add(table);
    switch (table) {
      case SupabaseConstants.profilesTable:
        return adminQueryBuilder;
      case SupabaseConstants.adminLogsTable:
        return adminLogsQueryBuilder;
      case SupabaseConstants.securityEventsTable:
        return securityEventsQueryBuilder ?? _FakeMutationQueryBuilder();
      case SupabaseConstants.syncMetadataTable:
        return syncMetadataQueryBuilder ?? _FakeMutationQueryBuilder();
    }
    // For soft-deletable tables (birds, eggs, etc.) return generic builder
    return genericTableBuilder ?? _FakeMutationQueryBuilder();
  }
}

// ---------------------------------------------------------------------------
// State recorder
// ---------------------------------------------------------------------------

class _StateRecorder {
  bool isLoading = false;
  String? error;
  bool isSuccess = false;
  String? successMessage;

  void call({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? successMessage,
  }) {
    this.isLoading = isLoading ?? false;
    this.error = error;
    this.isSuccess = isSuccess ?? false;
    this.successMessage = successMessage;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

_FakeMaintenanceClient _makeClient({
  PostgrestMap? adminUserResult,
  _FakeMutationQueryBuilder? securityEventsQueryBuilder,
  _FakeMutationQueryBuilder? syncMetadataQueryBuilder,
  _FakeMutationQueryBuilder? genericTableBuilder,
  Object? logsInsertError,
}) {
  return _FakeMaintenanceClient(
    adminQueryBuilder: _FakeAdminQueryBuilder(
      _FakeAdminCheckBuilder(result: adminUserResult),
    ),
    adminLogsQueryBuilder: _FakeMutationQueryBuilder(
      insertError: logsInsertError,
    ),
    securityEventsQueryBuilder: securityEventsQueryBuilder,
    syncMetadataQueryBuilder: syncMetadataQueryBuilder,
    genericTableBuilder: genericTableBuilder,
  );
}

({ProviderContainer container, Provider<AdminMaintenanceManager> managerProvider})
    _makeContainerAndManager({
  required String userId,
  required _FakeMaintenanceClient client,
  required _StateRecorder recorder,
}) {
  final managerProvider = Provider<AdminMaintenanceManager>((ref) {
    return AdminMaintenanceManager(ref, recorder.call);
  });

  final container = ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      supabaseClientProvider.overrideWithValue(client),
    ],
    retry: (_, __) => null,
  );
  addTearDown(container.dispose);

  return (container: container, managerProvider: managerProvider);
}

void main() {
  group('AdminMaintenanceManager', () {
    // -----------------------------------------------------------------------
    // dismissSecurityEvent
    // -----------------------------------------------------------------------
    group('dismissSecurityEvent', () {
      test('success - updates event, logs action, sets isSuccess', () async {
        final securityBuilder = _FakeMutationQueryBuilder();
        final client = _makeClient(
          adminUserResult: const {'role': 'admin'},
          securityEventsQueryBuilder: securityBuilder,
        );
        final recorder = _StateRecorder();
        final setup = _makeContainerAndManager(
          userId: 'admin-user',
          client: client,
          recorder: recorder,
        );
        addTearDown(setup.container.dispose);

        final manager = setup.container.read(setup.managerProvider);
        await manager.dismissSecurityEvent('event-123');

        // Verify state ends with success
        expect(recorder.isLoading, isFalse);
        expect(recorder.isSuccess, isTrue);
        expect(recorder.error, isNull);

        // Verify security_events table was accessed
        expect(
          client.requestedTables,
          contains(SupabaseConstants.securityEventsTable),
        );

        // Verify admin log was recorded
        expect(client.adminLogsQueryBuilder.insertCallCount, 1);
        final logPayload =
            client.adminLogsQueryBuilder.insertPayload as Map<String, dynamic>;
        expect(logPayload['action'], 'security_event_dismissed');
        expect(logPayload['admin_user_id'], 'admin-user');
        expect(
          (logPayload['details'] as Map)['message'],
          'Event event-123 resolved',
        );
      });

      test('fails when not admin', () async {
        final client = _makeClient(adminUserResult: null);
        final recorder = _StateRecorder();
        final setup = _makeContainerAndManager(
          userId: 'non-admin',
          client: client,
          recorder: recorder,
        );
        addTearDown(setup.container.dispose);

        final manager = setup.container.read(setup.managerProvider);
        await manager.dismissSecurityEvent('event-123');

        expect(recorder.isLoading, isFalse);
        expect(recorder.isSuccess, isFalse);
        expect(recorder.error, 'admin.action_error');

        // No admin log should be recorded
        expect(client.adminLogsQueryBuilder.insertCallCount, 0);
      });
    });

    // -----------------------------------------------------------------------
    // clearAuditLogs
    // -----------------------------------------------------------------------
    group('clearAuditLogs', () {
      test('success - deletes old logs, logs action, sets isSuccess', () async {
        final client = _makeClient(
          adminUserResult: const {'role': 'admin'},
        );
        final recorder = _StateRecorder();
        final setup = _makeContainerAndManager(
          userId: 'admin-user',
          client: client,
          recorder: recorder,
        );
        addTearDown(setup.container.dispose);

        final manager = setup.container.read(setup.managerProvider);
        await manager.clearAuditLogs();

        // Verify state ends with success
        expect(recorder.isLoading, isFalse);
        expect(recorder.isSuccess, isTrue);
        expect(recorder.error, isNull);

        // Verify admin_logs table was accessed (delete + log insert)
        expect(
          client.requestedTables
              .where((t) => t == SupabaseConstants.adminLogsTable)
              .length,
          greaterThanOrEqualTo(2),
        );

        // Verify admin log was recorded
        expect(client.adminLogsQueryBuilder.insertCallCount, 1);
        final logPayload =
            client.adminLogsQueryBuilder.insertPayload as Map<String, dynamic>;
        expect(logPayload['action'], 'audit_logs_cleared');
        expect(logPayload['admin_user_id'], 'admin-user');
      });

      test('fails when not admin', () async {
        final client = _makeClient(adminUserResult: null);
        final recorder = _StateRecorder();
        final setup = _makeContainerAndManager(
          userId: 'non-admin',
          client: client,
          recorder: recorder,
        );
        addTearDown(setup.container.dispose);

        final manager = setup.container.read(setup.managerProvider);
        await manager.clearAuditLogs();

        expect(recorder.isLoading, isFalse);
        expect(recorder.isSuccess, isFalse);
        expect(recorder.error, 'admin.action_error');
        expect(client.adminLogsQueryBuilder.insertCallCount, 0);
      });
    });

    // -----------------------------------------------------------------------
    // cleanSoftDeletedRecords
    // -----------------------------------------------------------------------
    group('cleanSoftDeletedRecords', () {
      test('success - iterates tables, logs total cleaned, sets successMessage',
          () async {
        // Return a list with 2 items for each soft-deletable table
        final genericBuilder = _FakeMutationQueryBuilder(
          mutationBuilder: _FakeMutationBuilder(
            selectResult: [
              {'id': 'r1'},
              {'id': 'r2'},
            ],
          ),
        );
        final client = _makeClient(
          adminUserResult: const {'role': 'admin'},
          genericTableBuilder: genericBuilder,
        );
        final recorder = _StateRecorder();
        final setup = _makeContainerAndManager(
          userId: 'admin-user',
          client: client,
          recorder: recorder,
        );
        addTearDown(setup.container.dispose);

        final manager = setup.container.read(setup.managerProvider);
        await manager.cleanSoftDeletedRecords(30);

        // Verify state ends with success
        expect(recorder.isLoading, isFalse);
        expect(recorder.isSuccess, isTrue);
        expect(recorder.error, isNull);
        expect(recorder.successMessage, 'admin.soft_deleted_cleaned');

        // Verify all soft-deletable tables were accessed
        for (final table in AdminConstants.softDeletableTables) {
          expect(client.requestedTables, contains(table));
        }

        // Verify admin log was recorded with cleaned count
        expect(client.adminLogsQueryBuilder.insertCallCount, 1);
        final logPayload =
            client.adminLogsQueryBuilder.insertPayload as Map<String, dynamic>;
        expect(logPayload['action'], 'soft_delete_cleanup');
        expect(logPayload['admin_user_id'], 'admin-user');
        expect((logPayload['details'] as Map)['days'], 30);
        expect(
          (logPayload['details'] as Map)['cleaned'],
          AdminConstants.softDeletableTables.length * 2,
        );
      });

      test('fails when not admin', () async {
        final client = _makeClient(adminUserResult: null);
        final recorder = _StateRecorder();
        final setup = _makeContainerAndManager(
          userId: 'non-admin',
          client: client,
          recorder: recorder,
        );
        addTearDown(setup.container.dispose);

        final manager = setup.container.read(setup.managerProvider);
        await manager.cleanSoftDeletedRecords(30);

        expect(recorder.isLoading, isFalse);
        expect(recorder.isSuccess, isFalse);
        expect(recorder.error, 'admin.action_error');
        expect(client.adminLogsQueryBuilder.insertCallCount, 0);
      });
    });

    // -----------------------------------------------------------------------
    // resetStuckSyncRecords
    // -----------------------------------------------------------------------
    group('resetStuckSyncRecords', () {
      test('success - deletes stuck records, logs action, sets successMessage',
          () async {
        final syncBuilder = _FakeMutationQueryBuilder();
        final client = _makeClient(
          adminUserResult: const {'role': 'admin'},
          syncMetadataQueryBuilder: syncBuilder,
        );
        final recorder = _StateRecorder();
        final setup = _makeContainerAndManager(
          userId: 'admin-user',
          client: client,
          recorder: recorder,
        );
        addTearDown(setup.container.dispose);

        final manager = setup.container.read(setup.managerProvider);
        await manager.resetStuckSyncRecords();

        // Verify state ends with success
        expect(recorder.isLoading, isFalse);
        expect(recorder.isSuccess, isTrue);
        expect(recorder.error, isNull);
        expect(recorder.successMessage, 'admin.stuck_reset');

        // Verify sync_metadata table was accessed
        expect(
          client.requestedTables,
          contains(SupabaseConstants.syncMetadataTable),
        );

        // Verify admin log was recorded
        expect(client.adminLogsQueryBuilder.insertCallCount, 1);
        final logPayload =
            client.adminLogsQueryBuilder.insertPayload as Map<String, dynamic>;
        expect(logPayload['action'], 'sync_stuck_reset');
        expect(logPayload['admin_user_id'], 'admin-user');
      });

      test('fails when not admin', () async {
        final client = _makeClient(adminUserResult: null);
        final recorder = _StateRecorder();
        final setup = _makeContainerAndManager(
          userId: 'non-admin',
          client: client,
          recorder: recorder,
        );
        addTearDown(setup.container.dispose);

        final manager = setup.container.read(setup.managerProvider);
        await manager.resetStuckSyncRecords();

        expect(recorder.isLoading, isFalse);
        expect(recorder.isSuccess, isFalse);
        expect(recorder.error, 'admin.action_error');
        expect(client.adminLogsQueryBuilder.insertCallCount, 0);
      });
    });
  });
}
