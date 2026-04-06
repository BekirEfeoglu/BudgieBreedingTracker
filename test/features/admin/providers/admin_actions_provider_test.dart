// ignore_for_file: unused_element_parameter, must_be_immutable
import 'dart:async';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_actions_provider.dart';
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

class _FakeAdminCheckBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  _FakeAdminCheckBuilder({this.result});

  final PostgrestMap? result;
  final eqCalls = <MapEntry<String, Object>>[];

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    eqCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    return _FakeMaybeSingleBuilder(result: result);
  }
}

class _FakeListBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  _FakeListBuilder({this.result = const [], this.error});

  final List<Map<String, dynamic>> result;
  final Object? error;
  final inFilterCalls = <MapEntry<String, List<dynamic>>>[];

  @override
  PostgrestFilterBuilder<PostgrestList> inFilter(
    String column,
    List<dynamic> values,
  ) {
    inFilterCalls.add(MapEntry(column, values));
    return this;
  }

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestList value) onValue, {
    Function? onError,
  }) {
    final source = error == null
        ? Future<PostgrestList>.value(result)
        : Future<PostgrestList>.error(error!);
    return source.then(onValue, onError: onError);
  }
}

class _FakeMutationBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  _FakeMutationBuilder({this.error});

  final Object? error;
  final eqCalls = <MapEntry<String, Object>>[];
  final ltCalls = <MapEntry<String, Object>>[];

  @override
  PostgrestFilterBuilder<dynamic> eq(String column, Object value) {
    eqCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestFilterBuilder<dynamic> lt(String column, Object value) {
    ltCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  Future<S> then<S>(
    FutureOr<S> Function(dynamic value) onValue, {
    Function? onError,
  }) {
    final source = error == null
        ? Future<dynamic>.value(null)
        : Future<dynamic>.error(error!);
    return source.then(onValue, onError: onError);
  }
}

class _FakeAdminQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeAdminQueryBuilder(this.filterBuilder);

  final _FakeAdminCheckBuilder filterBuilder;
  final selectedColumns = <String>[];

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    selectedColumns.add(columns);
    return filterBuilder;
  }
}

class _FakeProfilesQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeProfilesQueryBuilder(this.selectBuilder);

  final _FakeListBuilder selectBuilder;
  final selectedColumns = <String>[];

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    selectedColumns.add(columns);
    return selectBuilder;
  }
}

class _FakeMutationQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeMutationQueryBuilder({
    required this.updateBuilder,
    required this.deleteBuilder,
    required this.insertBuilder,
  });

  final _FakeMutationBuilder updateBuilder;
  final _FakeMutationBuilder deleteBuilder;
  final _FakeMutationBuilder insertBuilder;
  Object? updatePayload;
  Object? insertPayload;

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

  @override
  PostgrestFilterBuilder<dynamic> insert(
    Object values, {
    bool defaultToNull = true,
  }) {
    insertPayload = values;
    return insertBuilder;
  }
}

class _FakeActionsClient extends Fake implements SupabaseClient {
  _FakeActionsClient({
    required this.adminQueryBuilder,
    required this.profilesQueryBuilder,
    required this.securityEventsQueryBuilder,
    required this.adminLogsQueryBuilder,
  });

  final _FakeAdminQueryBuilder adminQueryBuilder;
  final _FakeProfilesQueryBuilder profilesQueryBuilder;
  final _FakeMutationQueryBuilder securityEventsQueryBuilder;
  final _FakeMutationQueryBuilder adminLogsQueryBuilder;
  final requestedTables = <String>[];

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTables.add(table);
    switch (table) {
      case SupabaseConstants.adminUsersTable:
        return adminQueryBuilder;
      case SupabaseConstants.profilesTable:
        return profilesQueryBuilder;
      case SupabaseConstants.securityEventsTable:
        return securityEventsQueryBuilder;
      case SupabaseConstants.adminLogsTable:
        return adminLogsQueryBuilder;
    }
    throw StateError('Unexpected table: $table');
  }
}

ProviderContainer _makeContainer({
  required String userId,
  required _FakeActionsClient client,
}) {
  return ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      supabaseClientProvider.overrideWithValue(client),
    ],
    retry: (_, __) => null,
  );
}

_FakeActionsClient _makeClient({
  PostgrestMap? adminUserResult,
  List<Map<String, dynamic>> profilesResult = const [],
  Object? profilesError,
  Object? securityUpdateError,
  Object? logsDeleteError,
  Object? logsInsertError,
}) {
  return _FakeActionsClient(
    adminQueryBuilder: _FakeAdminQueryBuilder(
      _FakeAdminCheckBuilder(result: adminUserResult),
    ),
    profilesQueryBuilder: _FakeProfilesQueryBuilder(
      _FakeListBuilder(result: profilesResult, error: profilesError),
    ),
    securityEventsQueryBuilder: _FakeMutationQueryBuilder(
      updateBuilder: _FakeMutationBuilder(error: securityUpdateError),
      deleteBuilder: _FakeMutationBuilder(),
      insertBuilder: _FakeMutationBuilder(),
    ),
    adminLogsQueryBuilder: _FakeMutationQueryBuilder(
      updateBuilder: _FakeMutationBuilder(),
      deleteBuilder: _FakeMutationBuilder(error: logsDeleteError),
      insertBuilder: _FakeMutationBuilder(error: logsInsertError),
    ),
  );
}

void main() {
  group('AdminActionState', () {
    test('default values', () {
      const state = AdminActionState();
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
      expect(state.successMessage, isNull);
    });

    test('copyWith updates isLoading', () {
      const state = AdminActionState();
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
      expect(updated.error, isNull);
      expect(updated.isSuccess, isFalse);
    });

    test('copyWith updates isSuccess', () {
      const state = AdminActionState();
      final updated = state.copyWith(isSuccess: true);
      expect(updated.isSuccess, isTrue);
    });

    test('copyWith sets error', () {
      const state = AdminActionState();
      final updated = state.copyWith(error: 'Something went wrong');
      expect(updated.error, 'Something went wrong');
    });

    test('copyWith clears error when null passed', () {
      const state = AdminActionState(error: 'prev error');
      final updated = state.copyWith(error: null);
      expect(updated.error, isNull);
    });

    test('copyWith updates successMessage', () {
      const state = AdminActionState();
      final updated = state.copyWith(successMessage: 'Export done');
      expect(updated.successMessage, 'Export done');
    });
  });

  group('AdminActionsNotifier', () {
    test('initial state is default AdminActionState', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(adminActionsProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('reset() returns state to default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(adminActionsProvider.notifier).reset();
      final state = container.read(adminActionsProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('notifier type is AdminActionsNotifier', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(adminActionsProvider.notifier);
      expect(notifier, isA<AdminActionsNotifier>());
    });

    test('bulkExport returns JSON and tracks selected ids', () async {
      final client = _makeClient(
        adminUserResult: const {'id': 'admin-1'},
        profilesResult: const [
          {
            'id': 'u1',
            'email': 'user1@test.com',
            'full_name': 'User One',
            'avatar_url': null,
            'created_at': '2026-01-01T00:00:00Z',
            'is_active': true,
          },
        ],
      );
      final container = _makeContainer(userId: 'user-1', client: client);
      addTearDown(container.dispose);

      final result = await container
          .read(adminActionsProvider.notifier)
          .bulkExport({'u1'});

      expect(result, contains('"id":"u1"'));
      expect(
        client.profilesQueryBuilder.selectedColumns.single,
        'id, email, full_name, avatar_url, created_at, is_active',
      );
      expect(
        client.profilesQueryBuilder.selectBuilder.inFilterCalls.single.key,
        'id',
      );
      expect(
        client.profilesQueryBuilder.selectBuilder.inFilterCalls.single.value,
        ['u1'],
      );
      final state = container.read(adminActionsProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isTrue);
      expect(state.error, isNull);
    });

    test('bulkExport returns CSV when requested', () async {
      final client = _makeClient(
        adminUserResult: const {'id': 'admin-1'},
        profilesResult: const [
          {
            'id': 'u1',
            'email': 'user1@test.com',
            'full_name': 'User One',
            'avatar_url': null,
            'created_at': '2026-01-01T00:00:00Z',
            'is_active': true,
          },
        ],
      );
      final container = _makeContainer(userId: 'user-1', client: client);
      addTearDown(container.dispose);

      final result = await container
          .read(adminActionsProvider.notifier)
          .bulkExport({'u1'}, format: ExportFormat.csv);

      expect(
        result,
        startsWith('id,email,full_name,avatar_url,created_at,is_active'),
      );
      expect(result, contains('"u1"'));
      expect(result, contains('"user1@test.com"'));
    });

    test(
      'bulkExport returns empty string and exposes error on failure',
      () async {
        final client = _makeClient(
          adminUserResult: const {'id': 'admin-1'},
          profilesError: StateError('profiles failed'),
        );
        final container = _makeContainer(userId: 'user-1', client: client);
        addTearDown(container.dispose);

        final result = await container
            .read(adminActionsProvider.notifier)
            .bulkExport({'u1'});

        expect(result, isEmpty);
        final state = container.read(adminActionsProvider);
        expect(state.isLoading, isFalse);
        expect(state.isSuccess, isFalse);
        expect(state.error, contains('profiles failed'));
      },
    );

    test(
      'dismissSecurityEvent marks event resolved and logs admin action',
      () async {
        final client = _makeClient(adminUserResult: const {'id': 'admin-1'});
        final container = _makeContainer(userId: 'admin-user', client: client);
        addTearDown(container.dispose);

        await container
            .read(adminActionsProvider.notifier)
            .dismissSecurityEvent('event-1');

        expect(client.securityEventsQueryBuilder.updatePayload, isA<Map>());
        final payload = Map<String, dynamic>.from(
          client.securityEventsQueryBuilder.updatePayload! as Map,
        );
        expect(payload['is_resolved'], isTrue);
        expect(payload['resolved_at'], isA<String>());
        expect(
          client.securityEventsQueryBuilder.updateBuilder.eqCalls.single.key,
          'id',
        );
        expect(
          client.securityEventsQueryBuilder.updateBuilder.eqCalls.single.value,
          'event-1',
        );
        expect(client.adminLogsQueryBuilder.insertPayload, isA<Map>());
        final logPayload = Map<String, dynamic>.from(
          client.adminLogsQueryBuilder.insertPayload! as Map,
        );
        expect(logPayload['action'], 'security_event_dismissed');
        expect(logPayload['admin_user_id'], 'admin-user');
        expect(container.read(adminActionsProvider).isSuccess, isTrue);
      },
    );

    test(
      'clearAuditLogs stores translated action error when admin check fails',
      () async {
        final client = _makeClient(adminUserResult: null);
        final container = _makeContainer(userId: 'anonymous', client: client);
        addTearDown(container.dispose);

        await container.read(adminActionsProvider.notifier).clearAuditLogs();

        final state = container.read(adminActionsProvider);
        expect(state.isLoading, isFalse);
        expect(state.isSuccess, isFalse);
        expect(state.error, 'admin.action_error');
        expect(client.adminLogsQueryBuilder.insertPayload, isNull);
      },
    );
  });
}
