// ignore_for_file: unused_element_parameter
import 'dart:async';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_providers.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_url_resolver.dart';
import 'package:budgie_breeding_tracker/features/admin/constants/admin_constants.dart';
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
  }) => Future<PostgrestMap?>.value(result).then(onValue, onError: onError);
}

// ignore: must_be_immutable
class _FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  _FakeFilterBuilder({this.result = const []});

  PostgrestList result;
  final eqCalls = <MapEntry<String, Object>>[];
  final gteCalls = <MapEntry<String, Object>>[];
  final inFilterCalls = <MapEntry<String, List<dynamic>>>[];
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
  PostgrestFilterBuilder<PostgrestList> gte(String column, Object value) {
    gteCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestFilterBuilder<PostgrestList> or(
    String filters, {
    String? referencedTable,
  }) {
    orCalls.add(filters);
    return this;
  }

  @override
  PostgrestFilterBuilder<PostgrestList> inFilter(
    String column,
    List<dynamic> values,
  ) {
    inFilterCalls.add(MapEntry(column, values));
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
  }) => Future<PostgrestList>.value(result).then(onValue, onError: onError);
}

class _FakeTransformBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestList> {
  _FakeTransformBuilder(this._filter);
  final _FakeFilterBuilder _filter;

  @override
  PostgrestTransformBuilder<PostgrestList> limit(
    int count, {
    String? referencedTable,
  }) {
    _filter.lastLimit = count;
    return this;
  }

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestList value) onValue, {
    Function? onError,
  }) => Future<PostgrestList>.value(
    _filter.result,
  ).then(onValue, onError: onError);
}

class _FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeQueryBuilder(
    this.filterBuilder, {
    this.totalCount = 0,
    this.activeCount = 0,
  });
  final _FakeFilterBuilder filterBuilder;
  final int totalCount;
  final int activeCount;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    return filterBuilder;
  }

  @override
  PostgrestFilterBuilder<int> count([CountOption count = CountOption.exact]) {
    return _FakeCountBuilder(totalCount: totalCount, activeCount: activeCount);
  }
}

// ignore: must_be_immutable
class _FakeCountBuilder extends Fake implements PostgrestFilterBuilder<int> {
  _FakeCountBuilder({required this.totalCount, required this.activeCount});
  final int totalCount;
  final int activeCount;
  bool _activeOnly = false;

  @override
  PostgrestFilterBuilder<int> eq(String column, Object value) {
    if (column == 'is_active' && value == true) _activeOnly = true;
    return this;
  }

  @override
  Future<S> then<S>(
    FutureOr<S> Function(int value) onValue, {
    Function? onError,
  }) => Future<int>.value(
    _activeOnly ? activeCount : totalCount,
  ).then(onValue, onError: onError);
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  _FakeSupabaseClient({
    required this.adminCheckFilter,
    required this.usersListFilter,
    required this.sessionsListFilter,
    Map<String, _FakeFilterBuilder>? tableFilters,
    User? currentUser,
    this.totalCount = 0,
    this.activeCount = 0,
  }) : tableFilters = tableFilters ?? const {},
       _auth = _FakeGoTrueClient(currentUser: currentUser);

  final _FakeFilterBuilder adminCheckFilter;
  final _FakeFilterBuilder usersListFilter;
  final _FakeFilterBuilder sessionsListFilter;
  final Map<String, _FakeFilterBuilder> tableFilters;
  final _FakeGoTrueClient _auth;
  final int totalCount;
  final int activeCount;
  int _profilesCallCount = 0;

  @override
  GoTrueClient get auth => _auth;

  @override
  SupabaseQueryBuilder from(String table) {
    final tableFilter = tableFilters[table];
    if (tableFilter != null) {
      return _FakeQueryBuilder(tableFilter);
    }
    if (table == SupabaseConstants.profilesTable) {
      _profilesCallCount++;
      // First call: requireAdmin role check; second: actual user list
      if (_profilesCallCount == 1) {
        return _FakeQueryBuilder(adminCheckFilter);
      }
      return _FakeQueryBuilder(
        usersListFilter,
        totalCount: totalCount,
        activeCount: activeCount,
      );
    }
    if (table == SupabaseConstants.userSessionsTable) {
      return _FakeQueryBuilder(sessionsListFilter);
    }
    return _FakeQueryBuilder(usersListFilter);
  }
}

class _NoopSupabaseClient extends Fake implements SupabaseClient {}

class _FakeStorageUrlResolver extends StorageUrlResolver {
  _FakeStorageUrlResolver(this.resolvedUrls) : super(_NoopSupabaseClient());

  final Map<String, String> resolvedUrls;
  final seenUrls = <String?>[];

  @override
  Future<String?> resolve(String? url) async {
    seenUrls.add(url);
    if (url == null) return null;
    return resolvedUrls[url] ?? url;
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
  String? lastActiveAt,
}) => {
  'id': id,
  'email': email,
  'full_name': fullName,
  'avatar_url': null,
  'created_at': '2025-01-01T00:00:00Z',
  'is_active': isActive,
  'is_premium': isPremium,
  'role': role,
  if (lastActiveAt != null) 'last_active_at': lastActiveAt,
};

Map<String, dynamic> _sessionRow({
  String userId = 'user-1',
  String lastActiveAt = '2026-05-05T20:00:00Z',
  String createdAt = '2026-05-05T19:00:00Z',
}) => {
  'user_id': userId,
  'last_active_at': lastActiveAt,
  'created_at': createdAt,
};

_FakeSupabaseClient _makeClient({
  List<Map<String, dynamic>> usersResult = const [],
  List<Map<String, dynamic>> sessionsResult = const [],
  Map<String, _FakeFilterBuilder>? tableFilters,
  String adminRole = 'admin',
  int totalCount = 0,
  int activeCount = 0,
}) {
  return _FakeSupabaseClient(
    adminCheckFilter: _FakeFilterBuilder(
      result: [
        {'id': 'admin-user-id', 'role': adminRole, 'is_active': true},
      ],
    ),
    usersListFilter: _FakeFilterBuilder(result: usersResult),
    sessionsListFilter: _FakeFilterBuilder(result: sessionsResult),
    tableFilters: tableFilters,
    currentUser: _FakeUser(),
    totalCount: totalCount,
    activeCount: activeCount,
  );
}

ProviderContainer _makeContainer(
  _FakeSupabaseClient client, {
  String userId = 'admin-user-id',
  AdminLocalPresence? localPresence,
  StorageUrlResolver? storageUrlResolver,
}) {
  final overrides = [
    supabaseClientProvider.overrideWithValue(client),
    currentUserIdProvider.overrideWithValue(userId),
    supabaseInitializedProvider.overrideWith((_) => true),
    adminLocalPresenceProvider.overrideWithValue(localPresence),
    if (storageUrlResolver != null)
      storageUrlResolverProvider.overrideWithValue(storageUrlResolver),
  ];

  return ProviderContainer(overrides: overrides);
}

// ── Tests ───────────────────────────────────────────────────

void main() {
  group('adminUsersProvider', () {
    group('search term sanitization', () {
      test('should strip control characters from search term', () async {
        final client = _makeClient(usersResult: [_userRow()]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const query = AdminUsersQuery(searchTerm: 'test\x00\x01\x1f');
        await container.read(adminUsersProvider(query).future);

        expect(client.usersListFilter.orCalls, hasLength(1));
        expect(client.usersListFilter.orCalls.first, contains('test'));
        expect(client.usersListFilter.orCalls.first, isNot(contains('\x00')));
      });

      test('should strip PostgREST special characters', () async {
        final client = _makeClient(usersResult: [_userRow()]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const query = AdminUsersQuery(searchTerm: 'te,s.t(a)[b]\\c');
        await container.read(adminUsersProvider(query).future);

        expect(client.usersListFilter.orCalls, hasLength(1));
        expect(client.usersListFilter.orCalls.first, contains('testabc'));
      });

      test('should escape SQL wildcards in search term', () async {
        final client = _makeClient(usersResult: [_userRow()]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const query = AdminUsersQuery(searchTerm: 'test%user_name');
        await container.read(adminUsersProvider(query).future);

        expect(client.usersListFilter.orCalls, hasLength(1));
        expect(
          client.usersListFilter.orCalls.first,
          contains(r'test\%user\_name'),
        );
      });

      test('should skip search filter when sanitized term is empty', () async {
        final client = _makeClient(usersResult: [_userRow()]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const query = AdminUsersQuery(searchTerm: ',.()[]\\');
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

        const query = AdminUsersQuery(searchTerm: 'john');
        await container.read(adminUsersProvider(query).future);

        expect(client.usersListFilter.orCalls, hasLength(1));
        expect(
          client.usersListFilter.orCalls.first,
          'email.ilike.%john%,full_name.ilike.%john%',
        );
      });

      test('should include exact user ID search for UUID terms', () async {
        final client = _makeClient(usersResult: [_userRow()]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const userId = '123e4567-e89b-12d3-a456-426614174000';
        const query = AdminUsersQuery(searchTerm: userId);
        await container.read(adminUsersProvider(query).future);

        expect(client.usersListFilter.orCalls, hasLength(1));
        expect(
          client.usersListFilter.orCalls.first,
          'email.ilike.%$userId%,full_name.ilike.%$userId%,id.eq.$userId',
        );
      });
    });

    group('sort field validation', () {
      test('should use allowed sort field when valid', () async {
        final client = _makeClient(usersResult: [_userRow()]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const query = AdminUsersQuery(sortField: 'email', sortAscending: true);
        await container.read(adminUsersProvider(query).future);

        expect(client.usersListFilter.lastOrderColumn, 'email');
        expect(client.usersListFilter.lastOrderAscending, true);
      });

      test('should fallback to created_at for invalid sort field', () async {
        final client = _makeClient(usersResult: [_userRow()]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const query = AdminUsersQuery(sortField: 'id; DROP TABLE users');
        await container.read(adminUsersProvider(query).future);

        expect(client.usersListFilter.lastOrderColumn, 'created_at');
      });

      test('should accept all allowed sort fields', () async {
        const allowedFields = [
          'created_at',
          'email',
          'full_name',
          'is_active',
          'is_premium',
          'role',
        ];

        for (final field in allowedFields) {
          final client = _makeClient(usersResult: [_userRow()]);
          final container = _makeContainer(client);
          addTearDown(container.dispose);

          final query = AdminUsersQuery(sortField: field);
          await container.read(adminUsersProvider(query).future);

          expect(
            client.usersListFilter.lastOrderColumn,
            field,
            reason: '$field should be accepted as sort field',
          );
        }
      });

      test('should sort online users by last active locally', () async {
        final older = DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 4))
            .toIso8601String();
        final newer = DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 1))
            .toIso8601String();
        final client = _makeClient(
          usersResult: [
            _userRow(id: 'u1', email: 'older@test.com'),
            _userRow(id: 'u2', email: 'newer@test.com'),
          ],
          sessionsResult: [
            _sessionRow(userId: 'u1', lastActiveAt: older),
            _sessionRow(userId: 'u2', lastActiveAt: newer),
          ],
        );
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const query = AdminUsersQuery(
          onlineOnly: true,
          sortField: 'last_active_at',
        );
        final users = await container.read(adminUsersProvider(query).future);

        expect(users.map((user) => user.id), ['u2', 'u1']);
        expect(client.usersListFilter.lastOrderColumn, 'created_at');
        expect(
          client.usersListFilter.lastLimit,
          AdminConstants.onlineUsersCandidateLimit,
        );
      });
    });

    group('active filter', () {
      test('should apply isActive filter when provided', () async {
        final client = _makeClient(usersResult: [_userRow(isActive: true)]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const query = AdminUsersQuery(isActiveFilter: true);
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

      test('should apply created today filter when requested', () async {
        final client = _makeClient(usersResult: [_userRow()]);
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const query = AdminUsersQuery(createdTodayOnly: true);
        await container.read(adminUsersProvider(query).future);

        final createdAtCall = client.usersListFilter.gteCalls.firstWhere(
          (e) => e.key == SupabaseConstants.colCreatedAt,
          orElse: () => const MapEntry('', ''),
        );
        expect(createdAtCall.key, SupabaseConstants.colCreatedAt);
        expect(DateTime.tryParse(createdAtCall.value as String), isNotNull);
      });

      test(
        'should filter active today users from recent session activity',
        () async {
          final lastActive = DateTime.now()
              .toUtc()
              .subtract(const Duration(minutes: 15))
              .toIso8601String();
          final client = _makeClient(
            usersResult: [_userRow(id: 'u1')],
            sessionsResult: [
              _sessionRow(userId: 'u1', lastActiveAt: lastActive),
            ],
          );
          final container = _makeContainer(client);
          addTearDown(container.dispose);

          const query = AdminUsersQuery(activeTodayOnly: true);
          final users = await container.read(adminUsersProvider(query).future);

          expect(users.map((user) => user.id), ['u1']);
          expect(
            client.sessionsListFilter.gteCalls.single.key,
            SupabaseConstants.colCreatedAt,
          );
          final idFilter = client.usersListFilter.inFilterCalls.single;
          expect(idFilter.key, 'id');
          expect(idFilter.value, ['u1']);
        },
      );

      test(
        'should fall back to profiles updated today when no sessions exist today',
        () async {
          final client = _makeClient(usersResult: [_userRow(id: 'u1')]);
          final container = _makeContainer(client);
          addTearDown(container.dispose);

          const query = AdminUsersQuery(activeTodayOnly: true);
          final users = await container.read(adminUsersProvider(query).future);

          expect(users.map((user) => user.id), ['u1']);
          expect(client.usersListFilter.inFilterCalls, isEmpty);
          final updatedAtCall = client.usersListFilter.gteCalls.singleWhere(
            (entry) => entry.key == SupabaseConstants.colUpdatedAt,
          );
          expect(DateTime.tryParse(updatedAtCall.value as String), isNotNull);
        },
      );
    });

    group('result parsing', () {
      test('should parse AdminUser list from Supabase response', () async {
        final client = _makeClient(
          usersResult: [
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
          ],
        );
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const query = AdminUsersQuery();
        final users = await container.read(adminUsersProvider(query).future);

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

      test('should attach recent session activity to visible users', () async {
        final lastActive = DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 1))
            .toIso8601String();
        final client = _makeClient(
          usersResult: [_userRow(id: 'u1')],
          sessionsResult: [_sessionRow(userId: 'u1', lastActiveAt: lastActive)],
        );
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const query = AdminUsersQuery();
        final users = await container.read(adminUsersProvider(query).future);

        expect(users, hasLength(1));
        expect(users.first.lastActiveAt, isNotNull);
        expect(users.first.isOnline, isTrue);
        final userIdFilter = client.sessionsListFilter.inFilterCalls.single;
        expect(userIdFilter.key, 'user_id');
        expect(userIdFilter.value, ['u1']);
      });

      test(
        'should attach local active session before remote read catches up',
        () async {
          final localLastActive = DateTime.now().toUtc().subtract(
            const Duration(seconds: 5),
          );
          final client = _makeClient(
            usersResult: [_userRow(id: 'admin-user-id')],
          );
          final container = _makeContainer(
            client,
            localPresence: (
              userId: 'admin-user-id',
              lastActiveAt: localLastActive,
            ),
          );
          addTearDown(container.dispose);

          const query = AdminUsersQuery();
          final users = await container.read(adminUsersProvider(query).future);

          expect(users, hasLength(1));
          expect(users.first.id, 'admin-user-id');
          expect(users.first.lastActiveAt, localLastActive);
          expect(users.first.isOnline, isTrue);
        },
      );

      test('should return empty list when no users found', () async {
        final client = _makeClient();
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const query = AdminUsersQuery();
        final users = await container.read(adminUsersProvider(query).future);

        expect(users, isEmpty);
      });
    });

    // Note: Admin authorization (requireAdmin) is tested in
    // admin_auth_utils_test.dart with 14 dedicated tests.

    group('online filter', () {
      test('should filter profiles by online session user ids', () async {
        final lastActive = DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 1))
            .toIso8601String();
        final client = _makeClient(
          usersResult: [_userRow(id: 'u1')],
          sessionsResult: [_sessionRow(userId: 'u1', lastActiveAt: lastActive)],
        );
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const query = AdminUsersQuery(onlineOnly: true);
        final users = await container.read(adminUsersProvider(query).future);

        expect(users, hasLength(1));
        expect(users.first.id, 'u1');
        expect(users.first.isOnline, isTrue);
        expect(
          client.sessionsListFilter.eqCalls.any(
            (call) => call.key == 'is_active' && call.value == true,
          ),
          isTrue,
        );
        expect(client.sessionsListFilter.gteCalls.single.key, 'last_active_at');
        final idFilter = client.usersListFilter.inFilterCalls.single;
        expect(idFilter.key, 'id');
        expect(idFilter.value, ['u1']);
      });

      test(
        'should return empty result without profile query when none online',
        () async {
          final client = _makeClient(usersResult: [_userRow(id: 'u1')]);
          final container = _makeContainer(client);
          addTearDown(container.dispose);

          const query = AdminUsersQuery(onlineOnly: true);
          final users = await container.read(adminUsersProvider(query).future);

          expect(users, isEmpty);
          expect(client.usersListFilter.inFilterCalls, isEmpty);
          expect(client.usersListFilter.lastLimit, isNull);
        },
      );

      test(
        'should include local active session when remote sessions are empty',
        () async {
          final localLastActive = DateTime.now().toUtc().subtract(
            const Duration(seconds: 5),
          );
          final client = _makeClient(
            usersResult: [_userRow(id: 'admin-user-id')],
          );
          final container = _makeContainer(
            client,
            localPresence: (
              userId: 'admin-user-id',
              lastActiveAt: localLastActive,
            ),
          );
          addTearDown(container.dispose);

          const query = AdminUsersQuery(onlineOnly: true);
          final users = await container.read(adminUsersProvider(query).future);

          expect(users, hasLength(1));
          expect(users.first.id, 'admin-user-id');
          expect(users.first.isOnline, isTrue);
          final idFilter = client.usersListFilter.inFilterCalls.single;
          expect(idFilter.key, 'id');
          expect(idFilter.value, ['admin-user-id']);
        },
      );
    });

    group('query limits', () {
      test('should apply query limit parameter', () async {
        final client = _makeClient();
        final container = _makeContainer(client);
        addTearDown(container.dispose);

        const query = AdminUsersQuery(limit: 25);
        await container.read(adminUsersProvider(query).future);

        expect(client.usersListFilter.lastLimit, 25);
      });
    });
  });

  group('adminUserContentProvider', () {
    test('resolves private storage URLs before exposing admin content', () async {
      const birdUrl =
          'https://example.supabase.co/storage/v1/object/sign/bird-photos/user-1/bird-1/main.jpg?token=old';
      const eggUrl =
          'https://example.supabase.co/storage/v1/object/sign/egg-photos/user-1/egg-1/main.jpg?token=old';
      const chickUrl =
          'https://example.supabase.co/storage/v1/object/sign/chick-photos/user-1/chick-1/main.jpg?token=old';
      const thumbUrl =
          'https://example.supabase.co/storage/v1/object/sign/bird-photos/user-1/bird-1/gallery.jpg?token=old';
      final resolver = _FakeStorageUrlResolver({
        birdUrl: 'signed-bird-url',
        eggUrl: 'signed-egg-url',
        chickUrl: 'signed-chick-url',
        thumbUrl: 'signed-thumb-url',
      });
      final client = _makeClient(
        tableFilters: {
          SupabaseConstants.birdsTable: _FakeFilterBuilder(
            result: [
              {
                'id': 'bird-1',
                'name': 'Kuş-4',
                'gender': 'male',
                'status': 'alive',
                'species': 'budgie',
                'ring_number': null,
                'cage_number': null,
                'photo_url': birdUrl,
                'created_at': '2026-05-01T00:00:00Z',
              },
            ],
          ),
          SupabaseConstants.breedingPairsTable: _FakeFilterBuilder(),
          SupabaseConstants.eggsTable: _FakeFilterBuilder(
            result: [
              {
                'id': 'egg-1',
                'status': 'laid',
                'egg_number': 1,
                'clutch_id': null,
                'lay_date': '2026-05-01T00:00:00Z',
                'hatch_date': null,
                'photo_url': eggUrl,
                'created_at': '2026-05-01T00:00:00Z',
              },
            ],
          ),
          SupabaseConstants.chicksTable: _FakeFilterBuilder(
            result: [
              {
                'id': 'chick-1',
                'name': 'Yavru-1',
                'gender': 'unknown',
                'health_status': 'healthy',
                'ring_number': null,
                'hatch_date': null,
                'photo_url': chickUrl,
                'bird_id': null,
                'created_at': '2026-05-01T00:00:00Z',
              },
            ],
          ),
          SupabaseConstants.photosTable: _FakeFilterBuilder(
            result: [
              {
                'id': 'photo-1',
                'entity_type': 'bird',
                'entity_id': 'bird-1',
                'url': thumbUrl,
                'thumbnail_url': thumbUrl,
                'is_primary': true,
                'sort_order': null,
                'file_size': 123,
                'mime_type': 'image/jpeg',
                'created_at': '2026-05-01T00:00:00Z',
              },
            ],
          ),
        },
      );
      final container = _makeContainer(client, storageUrlResolver: resolver);
      addTearDown(container.dispose);

      final content = await container.read(
        adminUserContentProvider('user-1').future,
      );

      expect(content.birds.single.photoUrl, 'signed-bird-url');
      expect(content.eggs.single.photoUrl, 'signed-egg-url');
      expect(content.chicks.single.photoUrl, 'signed-chick-url');
      expect(content.photos.single.filePath, 'signed-thumb-url');
      expect(content.photos.single.entityLabel, 'Kuş-4');
      expect(content.photos.single.isPrimary, isTrue);
      expect(
        resolver.seenUrls,
        containsAll([birdUrl, eggUrl, chickUrl, thumbUrl]),
      );
    });

    test('uses photo table URL when entity photo_url is empty', () async {
      const thumbUrl =
          'https://example.supabase.co/storage/v1/object/sign/bird-photos/user-1/bird-1/gallery.jpg?token=old';
      final resolver = _FakeStorageUrlResolver({thumbUrl: 'signed-thumb-url'});
      final client = _makeClient(
        tableFilters: {
          SupabaseConstants.birdsTable: _FakeFilterBuilder(
            result: [
              {
                'id': 'bird-1',
                'name': 'Bird 1',
                'gender': 'male',
                'status': 'alive',
                'species': 'budgie',
                'ring_number': null,
                'cage_number': null,
                'photo_url': null,
                'created_at': '2026-05-01T00:00:00Z',
              },
            ],
          ),
          SupabaseConstants.breedingPairsTable: _FakeFilterBuilder(),
          SupabaseConstants.eggsTable: _FakeFilterBuilder(),
          SupabaseConstants.chicksTable: _FakeFilterBuilder(),
          SupabaseConstants.photosTable: _FakeFilterBuilder(
            result: [
              {
                'id': 'photo-1',
                'entity_type': 'bird',
                'entity_id': 'bird-1',
                'url': thumbUrl,
                'thumbnail_url': thumbUrl,
                'is_primary': false,
                'sort_order': 0,
                'file_size': 123,
                'mime_type': 'image/jpeg',
                'created_at': '2026-05-01T00:00:00Z',
              },
            ],
          ),
        },
      );
      final container = _makeContainer(client, storageUrlResolver: resolver);
      addTearDown(container.dispose);

      final content = await container.read(
        adminUserContentProvider('user-1').future,
      );

      expect(content.birds.single.photoUrl, 'signed-thumb-url');
      expect(content.photos.single.filePath, 'signed-thumb-url');
      expect(content.photos.single.isPrimary, isFalse);
      expect(resolver.seenUrls, contains(thumbUrl));
    });
  });

  group('adminUserCountsProvider', () {
    test('returns DB-wide counts, not the paginated page size', () async {
      final client = _makeClient(
        totalCount: 247,
        activeCount: 245,
        sessionsResult: [
          _sessionRow(userId: 'u1'),
          _sessionRow(userId: 'u2'),
          _sessionRow(userId: 'u1'), // duplicate session -> counted once
        ],
      );
      final container = _makeContainer(client);
      addTearDown(container.dispose);

      final counts = await container.read(adminUserCountsProvider.future);

      expect(counts.total, 247);
      expect(counts.active, 245);
      expect(counts.inactive, 2);
      expect(counts.online, 2);
    });

    test('clamps inactive to zero when active exceeds total', () async {
      final client = _makeClient(totalCount: 5, activeCount: 8);
      final container = _makeContainer(client);
      addTearDown(container.dispose);

      final counts = await container.read(adminUserCountsProvider.future);

      expect(counts.inactive, 0);
      expect(counts.online, 0);
    });
  });
}
