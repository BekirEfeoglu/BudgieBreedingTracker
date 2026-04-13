// ignore_for_file: unused_element_parameter, must_be_immutable
import 'dart:async';
import 'dart:convert';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_bulk_manager.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_user_manager.dart';
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

  @override
  PostgrestFilterBuilder<dynamic> eq(String column, Object value) {
    eqCalls.add(MapEntry(column, value));
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

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
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

class _FakeDeleteQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeDeleteQueryBuilder({this.deleteError});

  final Object? deleteError;
  final deletedTables = <String>[];

  @override
  PostgrestFilterBuilder<dynamic> delete() {
    return _FakeMutationBuilder(error: deleteError);
  }
}

class _FakeBulkClient extends Fake implements SupabaseClient {
  _FakeBulkClient({
    required this.adminQueryBuilder,
    required this.profilesQueryBuilder,
    this.deleteError,
  });

  final _FakeAdminQueryBuilder adminQueryBuilder;
  final _FakeProfilesQueryBuilder profilesQueryBuilder;
  final Object? deleteError;
  final requestedTables = <String>[];
  int _profilesCallCount = 0;

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTables.add(table);
    switch (table) {
      case SupabaseConstants.profilesTable:
        // First call is requireAdmin check, subsequent calls are export queries
        _profilesCallCount++;
        if (_profilesCallCount == 1) return adminQueryBuilder;
        return profilesQueryBuilder;
      default:
        // For bulkDeleteUserData — all other tables use delete().eq()
        return _FakeDeleteQueryBuilder(deleteError: deleteError);
    }
  }
}

// ── Stub AdminUserManager ──────────────────────────────

class _StubUserManager extends AdminUserManager {
  _StubUserManager(super.ref, super.updateState);

  int toggleCalls = 0;
  int grantCalls = 0;
  int revokeCalls = 0;
  final protectedUserIds = <String>{};

  @override
  Future<AdminUserOperationResult> toggleUserActive(
    String id,
    bool active,
  ) async {
    if (protectedUserIds.contains(id)) {
      return AdminUserOperationResult.protected;
    }
    toggleCalls++;
    return AdminUserOperationResult.success;
  }

  @override
  Future<AdminUserOperationResult> grantPremium(String id) async {
    if (protectedUserIds.contains(id)) {
      return AdminUserOperationResult.protected;
    }
    grantCalls++;
    return AdminUserOperationResult.success;
  }

  @override
  Future<AdminUserOperationResult> revokePremium(String id) async {
    if (protectedUserIds.contains(id)) {
      return AdminUserOperationResult.protected;
    }
    revokeCalls++;
    return AdminUserOperationResult.success;
  }
}

// ── Helpers ──────────────────────────────────────────────

_FakeBulkClient _makeClient({
  PostgrestMap? adminUserResult,
  List<Map<String, dynamic>> profilesResult = const [],
  Object? profilesError,
  Object? deleteError,
}) {
  return _FakeBulkClient(
    adminQueryBuilder: _FakeAdminQueryBuilder(
      _FakeAdminCheckBuilder(result: adminUserResult),
    ),
    profilesQueryBuilder: _FakeProfilesQueryBuilder(
      _FakeListBuilder(result: profilesResult, error: profilesError),
    ),
    deleteError: deleteError,
  );
}

ProviderContainer _makeContainer({
  required String userId,
  required _FakeBulkClient client,
}) {
  return ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      supabaseClientProvider.overrideWithValue(client),
    ],
    retry: (_, __) => null,
  );
}

/// Tracks updateState calls for assertions.
class _StateTracker {
  final calls = <Map<String, dynamic>>[];

  void call({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? successMessage,
  }) {
    calls.add({
      'isLoading': isLoading,
      'error': error,
      'isSuccess': isSuccess,
      'successMessage': successMessage,
    });
  }
}

void main() {
  group('AdminBulkManager', () {
    group('bulkExport', () {
      test('returns JSON with correct data when admin', () async {
        final client = _makeClient(
          adminUserResult: const {'role': 'admin'},
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
        final container = _makeContainer(userId: 'admin-1', client: client);
        addTearDown(container.dispose);
        final tracker = _StateTracker();

        final manager = AdminBulkManager(
          container.read(providerContainerRefProvider),
          _StubUserManager(
            container.read(providerContainerRefProvider),
            tracker.call,
          ),
          tracker.call,
        );

        final result = await manager.bulkExport({'u1'});

        expect(result, contains('"id":"u1"'));
        expect(result, contains('"email":"user1@test.com"'));
        final decoded = jsonDecode(result) as List;
        expect(decoded.length, 1);
        expect((decoded.first as Map)['full_name'], 'User One');

        // Verify select columns
        expect(
          client.profilesQueryBuilder.selectedColumns.single,
          'id, email, full_name, avatar_url, created_at, is_active',
        );
        // Verify inFilter called with correct ids
        expect(
          client.profilesQueryBuilder.selectBuilder.inFilterCalls.single.key,
          'id',
        );
        expect(
          client.profilesQueryBuilder.selectBuilder.inFilterCalls.single.value,
          ['u1'],
        );

        // Verify state transitions: loading → success
        expect(tracker.calls.first['isLoading'], isTrue);
        expect(tracker.calls.last['isSuccess'], isTrue);
        expect(tracker.calls.last['isLoading'], isFalse);
      });

      test('returns CSV format when requested', () async {
        final client = _makeClient(
          adminUserResult: const {'role': 'admin'},
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
        final container = _makeContainer(userId: 'admin-1', client: client);
        addTearDown(container.dispose);
        final tracker = _StateTracker();

        final manager = AdminBulkManager(
          container.read(providerContainerRefProvider),
          _StubUserManager(
            container.read(providerContainerRefProvider),
            tracker.call,
          ),
          tracker.call,
        );

        final result = await manager.bulkExport(
          {'u1'},
          format: ExportFormat.csv,
        );

        expect(
          result,
          startsWith('id,email,full_name,avatar_url,created_at,is_active'),
        );
        expect(result, contains('"u1"'));
        expect(result, contains('"user1@test.com"'));
        expect(result, contains('"User One"'));
      });

      test('returns empty string on error', () async {
        final client = _makeClient(
          adminUserResult: const {'role': 'admin'},
          profilesError: StateError('profiles query failed'),
        );
        final container = _makeContainer(userId: 'admin-1', client: client);
        addTearDown(container.dispose);
        final tracker = _StateTracker();

        final manager = AdminBulkManager(
          container.read(providerContainerRefProvider),
          _StubUserManager(
            container.read(providerContainerRefProvider),
            tracker.call,
          ),
          tracker.call,
        );

        final result = await manager.bulkExport({'u1'});

        expect(result, isEmpty);
        // Verify error state — isSuccess is not passed in catch, so null
        final lastCall = tracker.calls.last;
        expect(lastCall['isLoading'], isFalse);
        expect(lastCall['isSuccess'], isNull);
        expect(lastCall['error'], contains('profiles query failed'));
      });

      test('fails when not admin (requireAdmin throws)', () async {
        // adminUserResult is null → requireAdmin throws
        final client = _makeClient(adminUserResult: null);
        final container = _makeContainer(userId: 'anonymous', client: client);
        addTearDown(container.dispose);
        final tracker = _StateTracker();

        final manager = AdminBulkManager(
          container.read(providerContainerRefProvider),
          _StubUserManager(
            container.read(providerContainerRefProvider),
            tracker.call,
          ),
          tracker.call,
        );

        final result = await manager.bulkExport({'u1'});

        expect(result, isEmpty);
        final lastCall = tracker.calls.last;
        expect(lastCall['isLoading'], isFalse);
        expect(lastCall['isSuccess'], isNull);
        expect(lastCall['error'], isNotNull);
      });
    });

    group('bulkToggleActive', () {
      test('counts succeeded and skipped (protected users)', () async {
        final client = _makeClient(adminUserResult: const {'role': 'admin'});
        final container = _makeContainer(userId: 'admin-1', client: client);
        addTearDown(container.dispose);
        final tracker = _StateTracker();
        final ref = container.read(providerContainerRefProvider);

        final userManager = _StubUserManager(ref, tracker.call);
        userManager.protectedUserIds.add('protected-user');

        final manager = AdminBulkManager(ref, userManager, tracker.call);

        final result = await manager.bulkToggleActive(
          {'user-1', 'user-2', 'protected-user'},
          activate: true,
        );

        expect(result.succeeded, 2);
        expect(result.skipped, 1);
        expect(userManager.toggleCalls, 2);
        // Verify success state
        final lastCall = tracker.calls.last;
        expect(lastCall['isSuccess'], isTrue);
        expect(lastCall['isLoading'], isFalse);
      });

      test('all succeed when no protected users', () async {
        final client = _makeClient(adminUserResult: const {'role': 'admin'});
        final container = _makeContainer(userId: 'admin-1', client: client);
        addTearDown(container.dispose);
        final tracker = _StateTracker();
        final ref = container.read(providerContainerRefProvider);

        final userManager = _StubUserManager(ref, tracker.call);
        final manager = AdminBulkManager(ref, userManager, tracker.call);

        final result = await manager.bulkToggleActive(
          {'user-1', 'user-2'},
          activate: false,
        );

        expect(result.succeeded, 2);
        expect(result.skipped, 0);
        expect(userManager.toggleCalls, 2);
      });
    });

    group('bulkGrantPremium', () {
      test('counts succeeded and skipped', () async {
        final client = _makeClient(adminUserResult: const {'role': 'admin'});
        final container = _makeContainer(userId: 'admin-1', client: client);
        addTearDown(container.dispose);
        final tracker = _StateTracker();
        final ref = container.read(providerContainerRefProvider);

        final userManager = _StubUserManager(ref, tracker.call);
        userManager.protectedUserIds.add('protected-user');

        final manager = AdminBulkManager(ref, userManager, tracker.call);

        final result = await manager.bulkGrantPremium(
          {'user-1', 'protected-user'},
        );

        expect(result.succeeded, 1);
        expect(result.skipped, 1);
        expect(userManager.grantCalls, 1);
      });
    });

    group('bulkRevokePremium', () {
      test('counts succeeded and skipped', () async {
        final client = _makeClient(adminUserResult: const {'role': 'admin'});
        final container = _makeContainer(userId: 'admin-1', client: client);
        addTearDown(container.dispose);
        final tracker = _StateTracker();
        final ref = container.read(providerContainerRefProvider);

        final userManager = _StubUserManager(ref, tracker.call);
        userManager.protectedUserIds.add('protected-user');

        final manager = AdminBulkManager(ref, userManager, tracker.call);

        final result = await manager.bulkRevokePremium(
          {'user-1', 'user-2', 'protected-user'},
        );

        expect(result.succeeded, 2);
        expect(result.skipped, 1);
        expect(userManager.revokeCalls, 2);
      });
    });

    group('bulkDeleteUserData', () {
      test('succeeds for valid admin', () async {
        final client = _makeClient(
          adminUserResult: const {'role': 'admin'},
        );
        final container = _makeContainer(userId: 'admin-1', client: client);
        addTearDown(container.dispose);
        final tracker = _StateTracker();
        final ref = container.read(providerContainerRefProvider);

        final userManager = _StubUserManager(ref, tracker.call);
        final manager = AdminBulkManager(ref, userManager, tracker.call);

        final result = await manager.bulkDeleteUserData({'user-1', 'user-2'});

        expect(result.succeeded, 2);
        expect(result.skipped, 0);
        // Verify state transitions: loading → success
        expect(tracker.calls.first['isLoading'], isTrue);
        final lastCall = tracker.calls.last;
        expect(lastCall['isSuccess'], isTrue);
        expect(lastCall['isLoading'], isFalse);
        // Verify admin_users table was queried (requireAdmin)
        expect(
          client.requestedTables,
          contains(SupabaseConstants.profilesTable),
        );
      });

      test('fails when not admin', () async {
        final client = _makeClient(adminUserResult: null);
        final container = _makeContainer(userId: 'anonymous', client: client);
        addTearDown(container.dispose);
        final tracker = _StateTracker();
        final ref = container.read(providerContainerRefProvider);

        final userManager = _StubUserManager(ref, tracker.call);
        final manager = AdminBulkManager(ref, userManager, tracker.call);

        final result = await manager.bulkDeleteUserData({'user-1'});

        expect(result.succeeded, 0);
        expect(result.skipped, 0);
        final lastCall = tracker.calls.last;
        expect(lastCall['isLoading'], isFalse);
        expect(lastCall['error'], isNotNull);
      });
    });
    group('bulkDeleteUserData — partial table failure', () {
      test('succeeds per user even if individual tables throw', () async {
        // deleteError causes every table delete to throw, but the inner
        // try/catch in bulkDeleteUserData swallows per-table errors and
        // still counts the user as succeeded.
        final client = _makeClient(
          adminUserResult: const {'role': 'admin'},
          deleteError: StateError('table delete failed'),
        );
        final container = _makeContainer(userId: 'admin-1', client: client);
        addTearDown(container.dispose);
        final tracker = _StateTracker();
        final ref = container.read(providerContainerRefProvider);

        final userManager = _StubUserManager(ref, tracker.call);
        final manager = AdminBulkManager(ref, userManager, tracker.call);

        final result = await manager.bulkDeleteUserData({'user-1'});

        // The user still counts as succeeded because per-table errors
        // are caught inside the inner loop.
        expect(result.succeeded, 1);
        expect(result.skipped, 0);
        final lastCall = tracker.calls.last;
        expect(lastCall['isSuccess'], isTrue);
        expect(lastCall['isLoading'], isFalse);
      });

      test('handles multiple users with partial table failures', () async {
        final client = _makeClient(
          adminUserResult: const {'role': 'admin'},
          deleteError: StateError('table delete failed'),
        );
        final container = _makeContainer(userId: 'admin-1', client: client);
        addTearDown(container.dispose);
        final tracker = _StateTracker();
        final ref = container.read(providerContainerRefProvider);

        final userManager = _StubUserManager(ref, tracker.call);
        final manager = AdminBulkManager(ref, userManager, tracker.call);

        final result = await manager.bulkDeleteUserData(
          {'user-1', 'user-2', 'user-3'},
        );

        expect(result.succeeded, 3);
        expect(result.skipped, 0);
      });
    });

    group('empty userIds set', () {
      test('bulkToggleActive with empty set returns zero counts', () async {
        final client = _makeClient(adminUserResult: const {'role': 'admin'});
        final container = _makeContainer(userId: 'admin-1', client: client);
        addTearDown(container.dispose);
        final tracker = _StateTracker();
        final ref = container.read(providerContainerRefProvider);

        final userManager = _StubUserManager(ref, tracker.call);
        final manager = AdminBulkManager(ref, userManager, tracker.call);

        final result = await manager.bulkToggleActive(
          <String>{},
          activate: true,
        );

        expect(result.succeeded, 0);
        expect(result.skipped, 0);
        expect(userManager.toggleCalls, 0);
        final lastCall = tracker.calls.last;
        expect(lastCall['isSuccess'], isTrue);
        expect(lastCall['isLoading'], isFalse);
      });

      test('bulkGrantPremium with empty set returns zero counts', () async {
        final client = _makeClient(adminUserResult: const {'role': 'admin'});
        final container = _makeContainer(userId: 'admin-1', client: client);
        addTearDown(container.dispose);
        final tracker = _StateTracker();
        final ref = container.read(providerContainerRefProvider);

        final userManager = _StubUserManager(ref, tracker.call);
        final manager = AdminBulkManager(ref, userManager, tracker.call);

        final result = await manager.bulkGrantPremium(<String>{});

        expect(result.succeeded, 0);
        expect(result.skipped, 0);
        expect(userManager.grantCalls, 0);
      });

      test('bulkRevokePremium with empty set returns zero counts', () async {
        final client = _makeClient(adminUserResult: const {'role': 'admin'});
        final container = _makeContainer(userId: 'admin-1', client: client);
        addTearDown(container.dispose);
        final tracker = _StateTracker();
        final ref = container.read(providerContainerRefProvider);

        final userManager = _StubUserManager(ref, tracker.call);
        final manager = AdminBulkManager(ref, userManager, tracker.call);

        final result = await manager.bulkRevokePremium(<String>{});

        expect(result.succeeded, 0);
        expect(result.skipped, 0);
        expect(userManager.revokeCalls, 0);
      });

      test('bulkDeleteUserData with empty set returns zero counts', () async {
        final client = _makeClient(adminUserResult: const {'role': 'admin'});
        final container = _makeContainer(userId: 'admin-1', client: client);
        addTearDown(container.dispose);
        final tracker = _StateTracker();
        final ref = container.read(providerContainerRefProvider);

        final userManager = _StubUserManager(ref, tracker.call);
        final manager = AdminBulkManager(ref, userManager, tracker.call);

        final result = await manager.bulkDeleteUserData(<String>{});

        expect(result.succeeded, 0);
        expect(result.skipped, 0);
        final lastCall = tracker.calls.last;
        expect(lastCall['isSuccess'], isTrue);
      });
    });
  });
}

/// Helper provider that exposes the container's [Ref] for direct use.
///
/// This allows creating [AdminBulkManager] and [AdminUserManager] directly
/// without going through notifiers.
final providerContainerRefProvider = Provider<Ref>((ref) => ref);
