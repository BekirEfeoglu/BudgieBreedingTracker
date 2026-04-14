import 'dart:async';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_users_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Fake Supabase builders ──────────────────────────────────

class _FakeUser extends Fake implements User {
  _FakeUser({this.idValue = 'admin-user-id'});
  final String idValue;

  @override
  String get id => idValue;
}

class _FakeGoTrueClient extends Fake implements GoTrueClient {
  _FakeGoTrueClient({User? currentUser}) : _currentUser = currentUser;
  final User? _currentUser;

  @override
  User? get currentUser => _currentUser;
}

class _FakeMaybeSingleBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestMap?> {
  _FakeMaybeSingleBuilder({this.result});
  final PostgrestMap? result;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestMap? value) onValue, {
    Function? onError,
  }) =>
      Future<PostgrestMap?>.value(result).then(onValue, onError: onError);
}

class _FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  _FakeFilterBuilder({this.result = const []});

  PostgrestList result;
  final eqCalls = <MapEntry<String, Object>>[];
  final orCalls = <String>[];
  String? lastOrderColumn;
  bool? lastOrderAscending;
  int? lastLimit;

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    eqCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestFilterBuilder<PostgrestList> or(String filters,
      {String? referencedTable}) {
    orCalls.add(filters);
    return this;
  }

  @override
  PostgrestFilterBuilder<PostgrestList> inFilter(String column,
      List<dynamic> values) {
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestList> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    lastOrderColumn = column;
    lastOrderAscending = ascending;
    return _FakeTransformBuilder(this);
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    return _FakeMaybeSingleBuilder(
      result: result.isNotEmpty ? result.first : null,
    );
  }

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestList value) onValue, {
    Function? onError,
  }) =>
      Future<PostgrestList>.value(result).then(onValue, onError: onError);
}

class _FakeTransformBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestList> {
  _FakeTransformBuilder(this._filter);
  final _FakeFilterBuilder _filter;

  @override
  PostgrestTransformBuilder<PostgrestList> limit(int count,
      {String? referencedTable}) {
    _filter.lastLimit = count;
    return this;
  }

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestList value) onValue, {
    Function? onError,
  }) =>
      Future<PostgrestList>.value(_filter.result)
          .then(onValue, onError: onError);
}

class _FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeQueryBuilder(this.filterBuilder);
  final _FakeFilterBuilder filterBuilder;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    return filterBuilder;
  }
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  _FakeSupabaseClient({
    required this.adminCheckFilter,
    required this.usersListFilter,
    User? currentUser,
  }) : _auth = _FakeGoTrueClient(currentUser: currentUser);

  final _FakeFilterBuilder adminCheckFilter;
  final _FakeFilterBuilder usersListFilter;
  final _FakeGoTrueClient _auth;
  int _profilesCallCount = 0;

  @override
  GoTrueClient get auth => _auth;

  @override
  SupabaseQueryBuilder from(String table) {
    if (table == SupabaseConstants.profilesTable) {
      _profilesCallCount++;
      // First call: requireAdmin role check; second: actual user list
      if (_profilesCallCount == 1) {
        return _FakeQueryBuilder(adminCheckFilter);
      }
      return _FakeQueryBuilder(usersListFilter);
    }
    return _FakeQueryBuilder(usersListFilter);
  }
}

// ── Helpers ─────────────────────────────────────────────────

Map<String, dynamic> _userRow({
  String id = 'user-1',
  String email = 'test@test.com',
  String? fullName = 'Test User',
  bool isActive = true,
  bool isPremium = false,
  String? role,
}) =>
    {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': null,
      'created_at': '2025-01-01T00:00:00Z',
      'is_active': isActive,
      'is_premium': isPremium,
      'role': role,
    };

_FakeSupabaseClient _makeClient({
  List<Map<String, dynamic>> usersResult = const [],
  String adminRole = 'admin',
}) {
  return _FakeSupabaseClient(
    adminCheckFilter: _FakeFilterBuilder(
      result: [
        {'id': 'admin-user-id', 'role': adminRole},
      ],
    ),
    usersListFilter: _FakeFilterBuilder(result: usersResult),
    currentUser: _FakeUser(),
  );
}

ProviderContainer _makeContainer(_FakeSupabaseClient client,
    {String userId = 'admin-user-id'}) {
  return ProviderContainer(overrides: [
    supabaseClientProvider.overrideWithValue(client),
    currentUserIdProvider.overrideWithValue(userId),
    supabaseInitializedProvider.overrideWith((_) => true),
  ]);
}

// ── Tests ───────────────────────────────────────────────────

void main() {
  group('adminUsersProvider', () {
    group('search term sanitization', () {
      test('should strip control characters from search term', () async {
        final client = _makeClient(usersResult: [_userRow()]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        final query = AdminUsersQuery(searchTerm: 'test\x00\x01\x1f');
        await container.read(adminUsersProvider(query).future);

        expect(client.usersListFilter.orCalls, hasLength(1));
        expect(client.usersListFilter.orCalls.first, contains('test'));
        expect(
            client.usersListFilter.orCalls.first, isNot(contains('\x00')));
      });

      test('should strip PostgREST special characters', () async {
        final client = _makeClient(usersResult: [_userRow()]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        final query = AdminUsersQuery(searchTerm: 'te,s.t(a)[b]\\c');
        await container.read(adminUsersProvider(query).future);

        expect(client.usersListFilter.orCalls, hasLength(1));
        expect(client.usersListFilter.orCalls.first, contains('testabc'));
      });

      test('should escape SQL wildcards in search term', () async {
        final client = _makeClient(usersResult: [_userRow()]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        final query = AdminUsersQuery(searchTerm: 'test%user_name');
        await container.read(adminUsersProvider(query).future);

        expect(client.usersListFilter.orCalls, hasLength(1));
        expect(client.usersListFilter.orCalls.first,
            contains(r'test\%user\_name'));
      });

      test('should skip search filter when sanitized term is empty', () async {
        final client = _makeClient(usersResult: [_userRow()]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        final query = AdminUsersQuery(searchTerm: ',.()[]\\');
        await container.read(adminUsersProvider(query).future);

        expect(client.usersListFilter.orCalls, isEmpty);
      });

      test('should skip search filter when search term is empty', () async {
        final client = _makeClient(usersResult: [_userRow()]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const query = AdminUsersQuery();
        await container.read(adminUsersProvider(query).future);

        expect(client.usersListFilter.orCalls, isEmpty);
      });

      test('should use ilike for case-insensitive search', () async {
        final client = _makeClient(usersResult: [_userRow()]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        final query = AdminUsersQuery(searchTerm: 'john');
        await container.read(adminUsersProvider(query).future);

        expect(client.usersListFilter.orCalls, hasLength(1));
        expect(client.usersListFilter.orCalls.first,
            'email.ilike.%john%,full_name.ilike.%john%');
      });
    });

    group('sort field validation', () {
      test('should use allowed sort field when valid', () async {
        final client = _makeClient(usersResult: [_userRow()]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        final query =
            AdminUsersQuery(sortField: 'email', sortAscending: true);
        await container.read(adminUsersProvider(query).future);

        expect(client.usersListFilter.lastOrderColumn, 'email');
        expect(client.usersListFilter.lastOrderAscending, true);
      });

      test('should fallback to created_at for invalid sort field', () async {
        final client = _makeClient(usersResult: [_userRow()]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        final query =
            AdminUsersQuery(sortField: 'id; DROP TABLE users');
        await container.read(adminUsersProvider(query).future);

        expect(client.usersListFilter.lastOrderColumn, 'created_at');
      });

      test('should accept all allowed sort fields', () async {
        const allowedFields = [
          'created_at', 'email', 'full_name',
          'is_active', 'is_premium', 'role',
        ];

        for (final field in allowedFields) {
          final client = _makeClient(usersResult: [_userRow()]);
          final container = _makeContainer(client);
          addTearDown(container.dispose);

          final query = AdminUsersQuery(sortField: field);
          await container.read(adminUsersProvider(query).future);

          expect(client.usersListFilter.lastOrderColumn, field,
              reason: '$field should be accepted as sort field');
        }
      });
    });

    group('active filter', () {
      test('should apply isActive filter when provided', () async {
        final client = _makeClient(usersResult: [_userRow(isActive: true)]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        final query = AdminUsersQuery(isActiveFilter: true);
        await container.read(adminUsersProvider(query).future);

        final isActiveCall = client.usersListFilter.eqCalls.firstWhere(
          (e) => e.key == 'is_active',
          orElse: () => const MapEntry('', ''),
        );
        expect(isActiveCall.key, 'is_active');
        expect(isActiveCall.value, true);
      });

      test('should skip isActive filter when null', () async {
        final client = _makeClient(usersResult: [_userRow()]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const query = AdminUsersQuery();
        await container.read(adminUsersProvider(query).future);

        final isActiveCalls = client.usersListFilter.eqCalls.where(
          (e) => e.key == 'is_active',
        );
        expect(isActiveCalls, isEmpty);
      });
    });

    group('result parsing', () {
      test('should parse AdminUser list from Supabase response', () async {
        final client = _makeClient(usersResult: [
          _userRow(
            id: 'u1',
            email: 'a@b.com',
            fullName: 'Alpha',
            isActive: true,
            isPremium: true,
            role: 'admin',
          ),
          _userRow(
            id: 'u2',
            email: 'c@d.com',
            fullName: 'Beta',
            isActive: false,
          ),
        ]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const query = AdminUsersQuery();
        final users =
            await container.read(adminUsersProvider(query).future);

        expect(users, hasLength(2));
        expect(users[0].id, 'u1');
        expect(users[0].email, 'a@b.com');
        expect(users[0].fullName, 'Alpha');
        expect(users[0].isActive, true);
        expect(users[0].isPremium, true);
        expect(users[0].role, 'admin');
        expect(users[1].id, 'u2');
        expect(users[1].isActive, false);
      });

      test('should return empty list when no users found', () async {
        final client = _makeClient();
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const query = AdminUsersQuery();
        final users =
            await container.read(adminUsersProvider(query).future);

        expect(users, isEmpty);
      });
    });

    // Note: Admin authorization (requireAdmin) is tested in
    // admin_auth_utils_test.dart with 14 dedicated tests.

    group('query limits', () {
      test('should apply query limit parameter', () async {
        final client = _makeClient();
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        final query = AdminUsersQuery(limit: 25);
        await container.read(adminUsersProvider(query).future);

        expect(client.usersListFilter.lastLimit, 25);
      });
    });
  });
}
