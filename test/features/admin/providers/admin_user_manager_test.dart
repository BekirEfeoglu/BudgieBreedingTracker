import 'dart:async';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_user_manager.dart';
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
  _FakeFilterBuilder(this.maybeSingleBuilder);

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

class _FakeUpdateFilterBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  Object? error;
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
    if (error != null) {
      return Future<dynamic>.error(error!).then(onValue, onError: onError);
    }
    return Future<dynamic>.value(null).then(onValue, onError: onError);
  }
}

class _FakeUpsertFilterBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  Object? error;

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

class _FakeInsertFilterBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  Object? error;

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

class _FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeQueryBuilder(this.filterBuilder, {
    _FakeUpdateFilterBuilder? updateBuilder,
    _FakeUpsertFilterBuilder? upsertBuilder,
    _FakeInsertFilterBuilder? insertBuilder,
  })  : updateBuilder = updateBuilder ?? _FakeUpdateFilterBuilder(),
        upsertBuilder = upsertBuilder ?? _FakeUpsertFilterBuilder(),
        insertBuilder = insertBuilder ?? _FakeInsertFilterBuilder();

  final _FakeFilterBuilder filterBuilder;
  final _FakeUpdateFilterBuilder updateBuilder;
  final _FakeUpsertFilterBuilder upsertBuilder;
  final _FakeInsertFilterBuilder insertBuilder;
  final selectedColumns = <String>[];

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    selectedColumns.add(columns);
    return filterBuilder;
  }

  @override
  PostgrestFilterBuilder<dynamic> update(
    Object values, {
    bool defaultToNull = true,
  }) {
    return updateBuilder;
  }

  @override
  PostgrestFilterBuilder<dynamic> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
  }) {
    return upsertBuilder;
  }

  @override
  PostgrestFilterBuilder<dynamic> insert(
    Object values, {
    bool defaultToNull = true,
  }) {
    return insertBuilder;
  }
}

class _FakeUserManagerClient extends Fake implements SupabaseClient {
  _FakeUserManagerClient({
    required this.profilesBuilder,
    SupabaseQueryBuilder? subscriptionsBuilder,
    SupabaseQueryBuilder? adminLogsBuilder,
  })  : subscriptionsBuilder =
            subscriptionsBuilder ?? _FakeQueryBuilder(_dummyFilter()),
        adminLogsBuilder =
            adminLogsBuilder ?? _FakeQueryBuilder(_dummyFilter());

  final SupabaseQueryBuilder profilesBuilder;
  final SupabaseQueryBuilder subscriptionsBuilder;
  final SupabaseQueryBuilder adminLogsBuilder;
  final requestedTables = <String>[];

  static _FakeFilterBuilder _dummyFilter() =>
      _FakeFilterBuilder(_FakeMaybeSingleBuilder());

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTables.add(table);
    if (table == SupabaseConstants.profilesTable) return profilesBuilder;
    if (table == SupabaseConstants.userSubscriptionsTable) {
      return subscriptionsBuilder;
    }
    if (table == SupabaseConstants.adminLogsTable) return adminLogsBuilder;
    throw StateError('Unexpected table: $table');
  }
}

// ── State-tracking helper ──────────────────────────────────

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

// ── Test utilities ──────────────────────────────────────────

ProviderContainer _makeContainer({
  required String userId,
  required _FakeUserManagerClient client,
}) {
  return ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      supabaseClientProvider.overrideWithValue(client),
    ],
    retry: (_, __) => null,
  );
}

AdminUserManager _makeManager(
  ProviderContainer container,
  List<_StateUpdate> updates,
) {
  final provider = Provider<AdminUserManager>(
    (ref) => AdminUserManager(ref, ({
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

_FakeQueryBuilder _adminProfilesBuilder({String role = 'admin'}) {
  return _FakeQueryBuilder(
    _FakeFilterBuilder(
      _FakeMaybeSingleBuilder(result: {'role': role}),
    ),
  );
}

/// Builds profiles builder that returns [targetRole] on the second
/// maybeSingle call (the target user fetch), after the first admin check.
_FakeUserManagerClient _clientWithTargetRole({
  String adminRole = 'admin',
  String? targetRole,
  _FakeUpdateFilterBuilder? updateBuilder,
  _FakeUpsertFilterBuilder? upsertBuilder,
}) {
  // The requireAdmin call reads role, then _fetchTargetUserRole reads role
  // again from the same profiles table. We use a single filter builder that
  // always returns the targetRole; requireAdmin sees adminRole via a separate
  // select call. However, since both use the same builder, we need a builder
  // that can return different results. For simplicity, we chain two filter
  // builders: one for the admin check (first maybeSingle), one for the target
  // user check (second maybeSingle).
  //
  // Actually, the fake builder always returns the same result. We'll use a
  // stateful approach:
  final results = <PostgrestMap?>[
    {'role': adminRole},
    if (targetRole != null) {'role': targetRole} else null,
  ];

  final filterBuilder = _SequentialFilterBuilder(results);
  final profilesBuilder = _FakeQueryBuilderSequential(
    filterBuilder,
    updateBuilder: updateBuilder,
    upsertBuilder: upsertBuilder,
  );

  return _FakeUserManagerClient(
    profilesBuilder: profilesBuilder,
  );
}

/// A filter builder that returns sequential maybeSingle results.
class _SequentialFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  _SequentialFilterBuilder(this._results);

  final List<PostgrestMap?> _results;
  int _callIndex = 0;
  final eqCalls = <MapEntry<String, Object>>[];

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    eqCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    final result = _callIndex < _results.length
        ? _results[_callIndex]
        : _results.last;
    _callIndex++;
    return _FakeMaybeSingleBuilder(result: result);
  }
}

class _FakeQueryBuilderSequential extends Fake implements SupabaseQueryBuilder {
  _FakeQueryBuilderSequential(this.filterBuilder, {
    _FakeUpdateFilterBuilder? updateBuilder,
    _FakeUpsertFilterBuilder? upsertBuilder,
  })  : updateBuilder = updateBuilder ?? _FakeUpdateFilterBuilder(),
        upsertBuilder = upsertBuilder ?? _FakeUpsertFilterBuilder();

  final _SequentialFilterBuilder filterBuilder;
  final _FakeUpdateFilterBuilder updateBuilder;
  final _FakeUpsertFilterBuilder upsertBuilder;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    return filterBuilder;
  }

  @override
  PostgrestFilterBuilder<dynamic> update(
    Object values, {
    bool defaultToNull = true,
  }) {
    return updateBuilder;
  }

  @override
  PostgrestFilterBuilder<dynamic> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
  }) {
    return upsertBuilder;
  }

  @override
  PostgrestFilterBuilder<dynamic> insert(
    Object values, {
    bool defaultToNull = true,
  }) {
    return _FakeInsertFilterBuilder();
  }
}

// ── Tests ───────────────────────────────────────────────────

void main() {
  group('ProtectedRoleError', () {
    test('toString includes role', () {
      const error = ProtectedRoleError('founder');
      expect(error.toString(), contains('founder'));
      expect(error.role, 'founder');
    });

    test('toString includes ProtectedRoleError prefix', () {
      const error = ProtectedRoleError('admin');
      expect(error.toString(), startsWith('ProtectedRoleError'));
    });
  });

  group('AdminUserOperationResult', () {
    test('has expected values', () {
      expect(AdminUserOperationResult.values, hasLength(3));
      expect(AdminUserOperationResult.values, contains(AdminUserOperationResult.success));
      expect(AdminUserOperationResult.values, contains(AdminUserOperationResult.protected));
      expect(AdminUserOperationResult.values, contains(AdminUserOperationResult.failed));
    });
  });

  group('AdminUserManager.toggleUserActive', () {
    test('activates a regular user successfully', () async {
      final client = _clientWithTargetRole(
        adminRole: 'admin',
        targetRole: 'user',
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .toggleUserActive('target-user', true);

      expect(result, AdminUserOperationResult.success);
      expect(updates.first.isLoading, isTrue);
      expect(updates.last.isLoading, isFalse);
      expect(updates.last.isSuccess, isTrue);
      expect(
        updates.last.successMessage,
        contains('admin.user_activated_success'),
      );
    });

    test('deactivates a regular user successfully', () async {
      final client = _clientWithTargetRole(
        adminRole: 'admin',
        targetRole: 'user',
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .toggleUserActive('target-user', false);

      expect(result, AdminUserOperationResult.success);
      expect(
        updates.last.successMessage,
        contains('admin.user_deactivated_success'),
      );
    });

    test('returns protected when target is founder', () async {
      final client = _clientWithTargetRole(
        adminRole: 'admin',
        targetRole: 'founder',
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .toggleUserActive('founder-user', true);

      expect(result, AdminUserOperationResult.protected);
      expect(updates.last.error, contains('admin.protected_user_error'));
    });

    test('returns protected when target is admin', () async {
      final client = _clientWithTargetRole(
        adminRole: 'founder',
        targetRole: 'admin',
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'founder-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .toggleUserActive('admin-user', false);

      expect(result, AdminUserOperationResult.protected);
      expect(updates.last.error, contains('admin.protected_user_error'));
    });

    test('returns failed on unexpected error', () async {
      final client = _clientWithTargetRole(
        adminRole: 'admin',
        targetRole: 'user',
        updateBuilder: _FakeUpdateFilterBuilder()..error = Exception('db error'),
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .toggleUserActive('target-user', true);

      expect(result, AdminUserOperationResult.failed);
      expect(updates.last.error, contains('admin.action_error'));
    });

    test('fails when user is not admin', () async {
      // The admin check returns 'user' role so requireAdmin throws
      final client = _clientWithTargetRole(
        adminRole: 'user',
        targetRole: 'user',
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'regular-user', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .toggleUserActive('target-user', true);

      expect(result, AdminUserOperationResult.failed);
      expect(updates.last.error, contains('admin.action_error'));
    });

    test('fails when user is anonymous', () async {
      final client = _clientWithTargetRole(
        adminRole: 'admin',
        targetRole: 'user',
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'anonymous', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .toggleUserActive('target-user', true);

      expect(result, AdminUserOperationResult.failed);
      expect(updates.last.error, contains('admin.action_error'));
    });

    test('sets loading state before operation', () async {
      final client = _clientWithTargetRole(
        adminRole: 'admin',
        targetRole: 'user',
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      await _makeManager(container, updates)
          .toggleUserActive('target-user', true);

      expect(updates.first.isLoading, isTrue);
      expect(updates.first.error, isNull);
      expect(updates.first.isSuccess, isFalse);
    });
  });

  group('AdminUserManager.grantPremium', () {
    test('grants premium to a regular user successfully', () async {
      final client = _clientWithTargetRole(
        adminRole: 'admin',
        targetRole: 'user',
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .grantPremium('target-user');

      expect(result, AdminUserOperationResult.success);
      expect(updates.last.isSuccess, isTrue);
      expect(
        updates.last.successMessage,
        contains('admin.premium_granted_success'),
      );
    });

    test('returns protected when target is founder', () async {
      final client = _clientWithTargetRole(
        adminRole: 'admin',
        targetRole: 'founder',
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .grantPremium('founder-user');

      expect(result, AdminUserOperationResult.protected);
      expect(
        updates.last.error,
        contains('admin.protected_user_premium_error'),
      );
    });

    test('returns protected when target is admin', () async {
      final client = _clientWithTargetRole(
        adminRole: 'founder',
        targetRole: 'admin',
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'founder-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .grantPremium('admin-user');

      expect(result, AdminUserOperationResult.protected);
    });

    test('returns failed on unexpected error', () async {
      final client = _clientWithTargetRole(
        adminRole: 'admin',
        targetRole: 'user',
        updateBuilder: _FakeUpdateFilterBuilder()
          ..error = Exception('profile update failed'),
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .grantPremium('target-user');

      expect(result, AdminUserOperationResult.failed);
      expect(updates.last.error, contains('admin.action_error'));
    });

    test('sets loading state before operation', () async {
      final client = _clientWithTargetRole(
        adminRole: 'admin',
        targetRole: 'user',
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      await _makeManager(container, updates).grantPremium('target-user');

      expect(updates.first.isLoading, isTrue);
      expect(updates.first.error, isNull);
    });

    test('continues when subscription upsert fails (non-fatal)', () async {
      final client = _clientWithTargetRole(
        adminRole: 'admin',
        targetRole: 'user',
        upsertBuilder: _FakeUpsertFilterBuilder()
          ..error = Exception('upsert failed'),
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .grantPremium('target-user');

      // Should still succeed — subscription record is non-fatal
      expect(result, AdminUserOperationResult.success);
      expect(updates.last.isSuccess, isTrue);
    });
  });

  group('AdminUserManager.revokePremium', () {
    test('revokes premium from a regular user successfully', () async {
      final client = _clientWithTargetRole(
        adminRole: 'admin',
        targetRole: 'user',
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .revokePremium('target-user');

      expect(result, AdminUserOperationResult.success);
      expect(updates.last.isSuccess, isTrue);
      expect(
        updates.last.successMessage,
        contains('admin.premium_revoked_success'),
      );
    });

    test('returns protected when target is founder', () async {
      final client = _clientWithTargetRole(
        adminRole: 'admin',
        targetRole: 'founder',
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .revokePremium('founder-user');

      expect(result, AdminUserOperationResult.protected);
      expect(
        updates.last.error,
        contains('admin.protected_user_premium_error'),
      );
    });

    test('returns failed on unexpected error', () async {
      final client = _clientWithTargetRole(
        adminRole: 'admin',
        targetRole: 'user',
        updateBuilder: _FakeUpdateFilterBuilder()
          ..error = Exception('profile update failed'),
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .revokePremium('target-user');

      expect(result, AdminUserOperationResult.failed);
      expect(updates.last.error, contains('admin.action_error'));
    });

    test('fails when user is anonymous', () async {
      final client = _clientWithTargetRole(
        adminRole: 'admin',
        targetRole: 'user',
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'anonymous', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .revokePremium('target-user');

      expect(result, AdminUserOperationResult.failed);
      expect(updates.last.error, contains('admin.action_error'));
    });

    test('sets loading then clears on completion', () async {
      final client = _clientWithTargetRole(
        adminRole: 'admin',
        targetRole: 'user',
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      await _makeManager(container, updates).revokePremium('target-user');

      expect(updates.length, greaterThanOrEqualTo(2));
      expect(updates.first.isLoading, isTrue);
      expect(updates.last.isLoading, isFalse);
    });
  });

  group('AdminUserManager null role handling', () {
    test('target user not found results in failure', () async {
      // When maybeSingle returns null for the target user,
      // _fetchTargetUserRole throws "user not found"
      final results = <PostgrestMap?>[
        {'role': 'admin'}, // admin check
        null, // target user not found
      ];

      final filterBuilder = _SequentialFilterBuilder(results);
      final profilesBuilder = _FakeQueryBuilderSequential(filterBuilder);

      final client = _FakeUserManagerClient(
        profilesBuilder: profilesBuilder,
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .toggleUserActive('nonexistent-user', true);

      expect(result, AdminUserOperationResult.failed);
      expect(updates.last.error, contains('admin.action_error'));
    });

    test('target user with null role is not protected', () async {
      // User exists but has no role → role is null → not protected
      final results = <PostgrestMap?>[
        {'role': 'admin'}, // admin check
        {'role': null}, // target user exists, role is null
      ];

      final filterBuilder = _SequentialFilterBuilder(results);
      final profilesBuilder = _FakeQueryBuilderSequential(filterBuilder);

      final client = _FakeUserManagerClient(
        profilesBuilder: profilesBuilder,
      );
      final updates = <_StateUpdate>[];
      final container = _makeContainer(userId: 'admin-1', client: client);
      addTearDown(container.dispose);

      final result = await _makeManager(container, updates)
          .toggleUserActive('target-user', true);

      expect(result, AdminUserOperationResult.success);
    });
  });
}
