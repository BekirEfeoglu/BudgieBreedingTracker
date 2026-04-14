// ignore_for_file: unused_element_parameter
import 'dart:async';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_settings_action_provider.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Fake Supabase builders ──────────────────────────────────

class _FakeUser extends Fake implements User {
  _FakeUser({this.idValue = 'test-user-id'});
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

// ignore: must_be_immutable
class _FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  _FakeFilterBuilder({
    this.result = const [],
    this.error,
    this.maybeSingleResult,
    this.upsertError,
  });

  PostgrestList result;
  Object? error;
  _FakeMaybeSingleBuilder? maybeSingleResult;
  Object? upsertError;
  final eqCalls = <MapEntry<String, Object>>[];
  final upsertPayloads = <Map<String, dynamic>>[];

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    eqCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() {
    return maybeSingleResult ??
        _FakeMaybeSingleBuilder(
          result: result.isNotEmpty ? result.first : null,
        );
  }

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestList value) onValue, {
    Function? onError,
  }) {
    if (error != null) {
      return Future<PostgrestList>.error(error!)
          .then(onValue, onError: onError);
    }
    return Future<PostgrestList>.value(result)
        .then(onValue, onError: onError);
  }
}

class _FakeUpsertBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  _FakeUpsertBuilder({this.error});

  final Object? error;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestList value) onValue, {
    Function? onError,
  }) {
    if (error != null) {
      return Future<PostgrestList>.error(error!)
          .then(onValue, onError: onError);
    }
    return Future<PostgrestList>.value(<PostgrestMap>[])
        .then(onValue, onError: onError);
  }
}

class _FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeQueryBuilder(this.filterBuilder, {this.upsertBuilder});

  final _FakeFilterBuilder filterBuilder;
  final _FakeUpsertBuilder? upsertBuilder;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    return filterBuilder;
  }

  @override
  PostgrestFilterBuilder<PostgrestList> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
  }) {
    if (values is Map<String, dynamic>) {
      filterBuilder.upsertPayloads.add(values);
    }
    return upsertBuilder ?? _FakeUpsertBuilder(error: filterBuilder.upsertError);
  }
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  _FakeSupabaseClient({
    required this.adminFilterBuilder,
    this.settingsFilterBuilder,
    this.upsertBuilder,
    this.upsertError,
    User? currentUser,
  }) : _auth = _FakeGoTrueClient(currentUser: currentUser);

  final _FakeFilterBuilder adminFilterBuilder;
  final _FakeFilterBuilder? settingsFilterBuilder;
  final _FakeUpsertBuilder? upsertBuilder;
  final Object? upsertError;
  final _FakeGoTrueClient _auth;

  final requestedTables = <String>[];

  @override
  GoTrueClient get auth => _auth;

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTables.add(table);
    if (table == SupabaseConstants.profilesTable) {
      return _FakeQueryBuilder(adminFilterBuilder);
    }
    if (table == SupabaseConstants.systemSettingsTable) {
      final fb = settingsFilterBuilder ??
          _FakeFilterBuilder(upsertError: upsertError);
      return _FakeQueryBuilder(fb, upsertBuilder: upsertBuilder);
    }
    return _FakeQueryBuilder(_FakeFilterBuilder());
  }
}

// ── Helpers ─────────────────────────────────────────────────

_FakeFilterBuilder _adminCheck({String role = 'admin'}) {
  return _FakeFilterBuilder(
    maybeSingleResult: _FakeMaybeSingleBuilder(result: {'role': role}),
  );
}

ProviderContainer _makeContainer({
  required SupabaseClient client,
  String userId = 'test-user-id',
}) {
  return ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      supabaseClientProvider.overrideWithValue(client),
      supabaseInitializedProvider.overrideWithValue(true),
    ],
    retry: (_, __) => null,
  );
}

// ── Tests ───────────────────────────────────────────────────

void main() {
  group('categoryForKey', () {
    test('should return maintenance when key contains maintenance', () {
      expect(categoryForKey('maintenance_mode'), 'maintenance');
    });

    test('should return maintenance when key contains registration', () {
      expect(categoryForKey('registration_open'), 'maintenance');
    });

    test('should return maintenance when key contains email_verification', () {
      expect(categoryForKey('email_verification_required'), 'maintenance');
    });

    test('should return security when key contains rate_limiting', () {
      expect(categoryForKey('rate_limiting_enabled'), 'security');
    });

    test('should return security when key contains two_factor', () {
      expect(categoryForKey('two_factor_required'), 'security');
    });

    test('should return backup when key contains backup', () {
      expect(categoryForKey('auto_backup_enabled'), 'backup');
    });

    test('should return backup when key contains cleanup', () {
      expect(categoryForKey('auto_cleanup_enabled'), 'backup');
    });

    test('should return notification when key contains push', () {
      expect(categoryForKey('global_push_enabled'), 'notification');
    });

    test('should return notification when key contains email_alerts', () {
      expect(categoryForKey('email_alerts_enabled'), 'notification');
    });

    test('should return storage when key contains storage', () {
      expect(categoryForKey('storage_limit'), 'storage');
    });

    test('should return community when key contains community', () {
      expect(categoryForKey('community_feature'), 'community');
    });

    test('should return general when key does not match any category', () {
      expect(categoryForKey('random_unknown_key'), 'general');
    });

    test('should return general for empty string', () {
      expect(categoryForKey(''), 'general');
    });

    test('should return general for premium_enabled key', () {
      expect(categoryForKey('premium_enabled'), 'general');
    });
  });

  group('settingDefaults', () {
    test('should contain 10 setting keys', () {
      expect(settingDefaults, hasLength(10));
    });

    test('should have expected keys', () {
      expect(
        settingDefaults.keys,
        containsAll([
          'maintenance_mode',
          'registration_open',
          'email_verification_required',
          'premium_enabled',
          'rate_limiting_enabled',
          'two_factor_required',
          'auto_backup_enabled',
          'auto_cleanup_enabled',
          'global_push_enabled',
          'email_alerts_enabled',
        ]),
      );
    });

    test('should have correct default values for disabled settings', () {
      expect(settingDefaults['maintenance_mode'], false);
      expect(settingDefaults['two_factor_required'], false);
      expect(settingDefaults['auto_backup_enabled'], false);
      expect(settingDefaults['auto_cleanup_enabled'], false);
    });

    test('should have correct default values for enabled settings', () {
      expect(settingDefaults['registration_open'], true);
      expect(settingDefaults['email_verification_required'], true);
      expect(settingDefaults['premium_enabled'], true);
      expect(settingDefaults['rate_limiting_enabled'], true);
      expect(settingDefaults['global_push_enabled'], true);
      expect(settingDefaults['email_alerts_enabled'], true);
    });

    test('should be an unmodifiable view of bool values', () {
      for (final entry in settingDefaults.entries) {
        expect(entry.key, isA<String>());
        expect(entry.value, isA<bool>());
      }
    });
  });

  group('AdminSettingsActionState', () {
    test('should have correct default values', () {
      const state = AdminSettingsActionState();
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.isSuccess, false);
    });

    test('should create state with custom values', () {
      const state = AdminSettingsActionState(
        isLoading: true,
        error: 'something went wrong',
        isSuccess: false,
      );
      expect(state.isLoading, true);
      expect(state.error, 'something went wrong');
      expect(state.isSuccess, false);
    });

    test('should preserve isLoading with copyWith', () {
      const state = AdminSettingsActionState(isLoading: true);
      final copied = state.copyWith(isSuccess: true);
      expect(copied.isLoading, true);
      expect(copied.isSuccess, true);
    });

    test('should preserve isSuccess with copyWith', () {
      const state = AdminSettingsActionState(isSuccess: true);
      final copied = state.copyWith(isLoading: true);
      expect(copied.isSuccess, true);
      expect(copied.isLoading, true);
    });

    test('should clear error when copyWith passes null error', () {
      const state = AdminSettingsActionState(error: 'old error');
      final copied = state.copyWith(isLoading: true);
      // error is not passed, so it becomes null (copyWith uses positional null)
      expect(copied.error, isNull);
    });

    test('should set error with copyWith', () {
      const state = AdminSettingsActionState();
      final copied = state.copyWith(error: 'new error');
      expect(copied.error, 'new error');
    });

    test('should override all fields with copyWith', () {
      const state = AdminSettingsActionState();
      final copied = state.copyWith(
        isLoading: true,
        error: 'err',
        isSuccess: true,
      );
      expect(copied.isLoading, true);
      expect(copied.error, 'err');
      expect(copied.isSuccess, true);
    });
  });

  group('AdminSettingsActionNotifier', () {
    test('should have default state initially', () {
      final client = _FakeSupabaseClient(
        adminFilterBuilder: _adminCheck(),
        currentUser: _FakeUser(),
      );
      final container = _makeContainer(client: client);
      addTearDown(container.dispose);

      final state = container.read(adminSettingsActionProvider);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.isSuccess, false);
    });

    test('should reset state to default', () {
      final client = _FakeSupabaseClient(
        adminFilterBuilder: _adminCheck(),
        currentUser: _FakeUser(),
      );
      final container = _makeContainer(client: client);
      addTearDown(container.dispose);

      // Manually set a non-default state via updateSetting then reset
      final notifier = container.read(adminSettingsActionProvider.notifier);
      notifier.reset();

      final state = container.read(adminSettingsActionProvider);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.isSuccess, false);
    });

    group('updateSetting', () {
      test('should return true and set success on successful update', () async {
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _adminCheck(),
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(client: client);
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        final result = await notifier.updateSetting(
          key: 'maintenance_mode',
          value: true,
        );

        expect(result, true);
        final state = container.read(adminSettingsActionProvider);
        expect(state.isLoading, false);
        expect(state.isSuccess, true);
        expect(state.error, isNull);
      });

      test('should call upsert on system_settings table', () async {
        final settingsFilter = _FakeFilterBuilder();
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _adminCheck(),
          settingsFilterBuilder: settingsFilter,
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(client: client);
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        await notifier.updateSetting(key: 'maintenance_mode', value: true);

        expect(
          client.requestedTables,
          contains(SupabaseConstants.systemSettingsTable),
        );
        expect(settingsFilter.upsertPayloads, hasLength(1));
        expect(settingsFilter.upsertPayloads.first['key'], 'maintenance_mode');
        expect(settingsFilter.upsertPayloads.first['value'], true);
        expect(
          settingsFilter.upsertPayloads.first['category'],
          'maintenance',
        );
        expect(settingsFilter.upsertPayloads.first['is_public'], false);
      });

      test('should set correct category for different keys', () async {
        final settingsFilter = _FakeFilterBuilder();
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _adminCheck(),
          settingsFilterBuilder: settingsFilter,
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(client: client);
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        await notifier.updateSetting(
          key: 'rate_limiting_enabled',
          value: false,
        );

        expect(settingsFilter.upsertPayloads.first['category'], 'security');
      });

      test('should include user id in upsert payload', () async {
        final settingsFilter = _FakeFilterBuilder();
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _adminCheck(),
          settingsFilterBuilder: settingsFilter,
          currentUser: _FakeUser(idValue: 'admin-123'),
        );
        final container = _makeContainer(
          client: client,
          userId: 'admin-123',
        );
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        await notifier.updateSetting(key: 'maintenance_mode', value: true);

        expect(
          settingsFilter.upsertPayloads.first['updated_by'],
          'admin-123',
        );
      });

      test('should return false and set error on admin check failure',
          () async {
        // Non-admin user
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _FakeFilterBuilder(
            maybeSingleResult:
                _FakeMaybeSingleBuilder(result: {'role': 'user'}),
          ),
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(client: client);
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        final result = await notifier.updateSetting(
          key: 'maintenance_mode',
          value: true,
        );

        expect(result, false);
        final state = container.read(adminSettingsActionProvider);
        expect(state.isLoading, false);
        expect(state.isSuccess, false);
        expect(state.error, isNotNull);
      });

      test('should return false and set error on upsert failure', () async {
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _adminCheck(),
          upsertError: Exception('DB write failed'),
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(client: client);
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        final result = await notifier.updateSetting(
          key: 'maintenance_mode',
          value: true,
        );

        expect(result, false);
        final state = container.read(adminSettingsActionProvider);
        expect(state.isLoading, false);
        expect(state.isSuccess, false);
        expect(state.error, isNotNull);
      });

      test('should return false when user is anonymous', () async {
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _adminCheck(),
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(
          client: client,
          userId: 'anonymous',
        );
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        final result = await notifier.updateSetting(
          key: 'maintenance_mode',
          value: true,
        );

        expect(result, false);
        final state = container.read(adminSettingsActionProvider);
        expect(state.isLoading, false);
        expect(state.error, isNotNull);
      });
    });

    group('resetToDefaults', () {
      test('should return true and set success on successful reset', () async {
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _adminCheck(),
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(client: client);
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        final result = await notifier.resetToDefaults();

        expect(result, true);
        final state = container.read(adminSettingsActionProvider);
        expect(state.isLoading, false);
        expect(state.isSuccess, true);
        expect(state.error, isNull);
      });

      test('should upsert all default settings', () async {
        final settingsFilter = _FakeFilterBuilder();
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _adminCheck(),
          settingsFilterBuilder: settingsFilter,
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(client: client);
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        await notifier.resetToDefaults();

        // Should upsert one entry per default setting
        expect(
          settingsFilter.upsertPayloads,
          hasLength(settingDefaults.length),
        );

        // Verify all default keys are present
        final upsertedKeys =
            settingsFilter.upsertPayloads.map((p) => p['key']).toSet();
        for (final key in settingDefaults.keys) {
          expect(upsertedKeys, contains(key));
        }
      });

      test('should use correct default values in upsert payloads', () async {
        final settingsFilter = _FakeFilterBuilder();
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _adminCheck(),
          settingsFilterBuilder: settingsFilter,
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(client: client);
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        await notifier.resetToDefaults();

        for (final payload in settingsFilter.upsertPayloads) {
          final key = payload['key'] as String;
          final value = payload['value'] as bool;
          expect(
            value,
            settingDefaults[key],
            reason: 'Default value mismatch for key: $key',
          );
        }
      });

      test('should set correct categories for each default setting', () async {
        final settingsFilter = _FakeFilterBuilder();
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _adminCheck(),
          settingsFilterBuilder: settingsFilter,
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(client: client);
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        await notifier.resetToDefaults();

        for (final payload in settingsFilter.upsertPayloads) {
          final key = payload['key'] as String;
          final category = payload['category'] as String;
          expect(
            category,
            categoryForKey(key),
            reason: 'Category mismatch for key: $key',
          );
        }
      });

      test('should return false and set error on admin check failure',
          () async {
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _FakeFilterBuilder(
            maybeSingleResult:
                _FakeMaybeSingleBuilder(result: {'role': 'user'}),
          ),
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(client: client);
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        final result = await notifier.resetToDefaults();

        expect(result, false);
        final state = container.read(adminSettingsActionProvider);
        expect(state.isLoading, false);
        expect(state.isSuccess, false);
        expect(state.error, isNotNull);
      });

      test('should return false and set error on upsert failure', () async {
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _adminCheck(),
          upsertError: Exception('Batch write failed'),
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(client: client);
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        final result = await notifier.resetToDefaults();

        expect(result, false);
        final state = container.read(adminSettingsActionProvider);
        expect(state.isLoading, false);
        expect(state.isSuccess, false);
        expect(state.error, isNotNull);
      });

      test('should return false when user is anonymous', () async {
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _adminCheck(),
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(
          client: client,
          userId: 'anonymous',
        );
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        final result = await notifier.resetToDefaults();

        expect(result, false);
        final state = container.read(adminSettingsActionProvider);
        expect(state.isLoading, false);
        expect(state.error, isNotNull);
      });

      test('should include user id and timestamp in all payloads', () async {
        final settingsFilter = _FakeFilterBuilder();
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _adminCheck(),
          settingsFilterBuilder: settingsFilter,
          currentUser: _FakeUser(idValue: 'admin-456'),
        );
        final container = _makeContainer(
          client: client,
          userId: 'admin-456',
        );
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        await notifier.resetToDefaults();

        for (final payload in settingsFilter.upsertPayloads) {
          expect(payload['updated_by'], 'admin-456');
          expect(payload['updated_at'], isNotNull);
          expect(payload['is_public'], false);
        }
      });
    });

    group('reset', () {
      test('should return state to default after updateSetting success',
          () async {
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _adminCheck(),
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(client: client);
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        await notifier.updateSetting(key: 'maintenance_mode', value: true);

        // State should be success
        expect(container.read(adminSettingsActionProvider).isSuccess, true);

        // Reset to default
        notifier.reset();

        final state = container.read(adminSettingsActionProvider);
        expect(state.isLoading, false);
        expect(state.error, isNull);
        expect(state.isSuccess, false);
      });

      test('should clear error state after failed operation', () async {
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _FakeFilterBuilder(
            maybeSingleResult:
                _FakeMaybeSingleBuilder(result: {'role': 'user'}),
          ),
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(client: client);
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        await notifier.updateSetting(key: 'maintenance_mode', value: true);

        // State should have error
        expect(container.read(adminSettingsActionProvider).error, isNotNull);

        // Reset clears error
        notifier.reset();

        final state = container.read(adminSettingsActionProvider);
        expect(state.error, isNull);
        expect(state.isLoading, false);
        expect(state.isSuccess, false);
      });
    });

    group('admin role checks', () {
      test('should succeed with founder role', () async {
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _adminCheck(role: 'founder'),
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(client: client);
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        final result = await notifier.updateSetting(
          key: 'maintenance_mode',
          value: true,
        );

        expect(result, true);
      });

      test('should fail with regular user role', () async {
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _adminCheck(role: 'user'),
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(client: client);
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        final result = await notifier.updateSetting(
          key: 'maintenance_mode',
          value: true,
        );

        expect(result, false);
      });

      test('should fail with moderator role', () async {
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _adminCheck(role: 'moderator'),
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(client: client);
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        final result = await notifier.updateSetting(
          key: 'maintenance_mode',
          value: true,
        );

        expect(result, false);
      });

      test('should fail when profile not found', () async {
        final client = _FakeSupabaseClient(
          adminFilterBuilder: _FakeFilterBuilder(
            maybeSingleResult: _FakeMaybeSingleBuilder(result: null),
          ),
          currentUser: _FakeUser(),
        );
        final container = _makeContainer(client: client);
        addTearDown(container.dispose);

        final notifier = container.read(adminSettingsActionProvider.notifier);
        final result = await notifier.updateSetting(
          key: 'maintenance_mode',
          value: true,
        );

        expect(result, false);
      });
    });
  });
}
