import 'dart:async';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_auth_utils.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
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

class _FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeQueryBuilder(this.filterBuilder);

  final _FakeFilterBuilder filterBuilder;
  final selectedColumns = <String>[];

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    selectedColumns.add(columns);
    return filterBuilder;
  }
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  _FakeSupabaseClient(this.queryBuilder);

  final _FakeQueryBuilder queryBuilder;
  final requestedTables = <String>[];

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTables.add(table);
    return queryBuilder;
  }
}

final _requireAdminRunnerProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => requireAdmin(ref),
);

void main() {
  group('requireAdmin', () {
    test('throws authentication required for anonymous user', () async {
      final maybeSingleBuilder = _FakeMaybeSingleBuilder(result: {'id': '1'});
      final filterBuilder = _FakeFilterBuilder(maybeSingleBuilder);
      final queryBuilder = _FakeQueryBuilder(filterBuilder);
      final client = _FakeSupabaseClient(queryBuilder);
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('anonymous'),
          supabaseClientProvider.overrideWithValue(client),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);
      final runCheck = container.read(_requireAdminRunnerProvider);

      Object? caught;
      try {
        await runCheck();
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<Exception>());
      expect(caught.toString(), contains(l10n('admin.auth_required')));
      expect(client.requestedTables, isEmpty);
    });

    test('throws permission denied when admin row is missing', () async {
      final maybeSingleBuilder = _FakeMaybeSingleBuilder(result: null);
      final filterBuilder = _FakeFilterBuilder(maybeSingleBuilder);
      final queryBuilder = _FakeQueryBuilder(filterBuilder);
      final client = _FakeSupabaseClient(queryBuilder);
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          supabaseClientProvider.overrideWithValue(client),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);
      final runCheck = container.read(_requireAdminRunnerProvider);

      Object? caught;
      try {
        await runCheck();
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<Exception>());
      expect(caught.toString(), contains(l10n('admin.permission_denied')));
      expect(client.requestedTables, [SupabaseConstants.adminUsersTable]);
      expect(queryBuilder.selectedColumns, ['id']);
      expect(filterBuilder.eqCalls, hasLength(1));
      expect(filterBuilder.eqCalls.first.key, 'user_id');
      expect(filterBuilder.eqCalls.first.value, 'user-1');
    });

    test('completes when user has an admin record', () async {
      final maybeSingleBuilder = _FakeMaybeSingleBuilder(result: {'id': '42'});
      final filterBuilder = _FakeFilterBuilder(maybeSingleBuilder);
      final queryBuilder = _FakeQueryBuilder(filterBuilder);
      final client = _FakeSupabaseClient(queryBuilder);
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-42'),
          supabaseClientProvider.overrideWithValue(client),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);
      final runCheck = container.read(_requireAdminRunnerProvider);

      await runCheck();
      expect(client.requestedTables, [SupabaseConstants.adminUsersTable]);
      expect(queryBuilder.selectedColumns, ['id']);
      expect(filterBuilder.eqCalls, hasLength(1));
      expect(filterBuilder.eqCalls.first.key, 'user_id');
      expect(filterBuilder.eqCalls.first.value, 'user-42');
    });

    test('bubbles query errors from supabase', () async {
      final maybeSingleBuilder = _FakeMaybeSingleBuilder(
        error: StateError('query failed'),
      );
      final filterBuilder = _FakeFilterBuilder(maybeSingleBuilder);
      final queryBuilder = _FakeQueryBuilder(filterBuilder);
      final client = _FakeSupabaseClient(queryBuilder);
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          supabaseClientProvider.overrideWithValue(client),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);
      final runCheck = container.read(_requireAdminRunnerProvider);

      Object? caught;
      try {
        await runCheck();
      } catch (e) {
        caught = e;
      }

      expect(caught, isA<StateError>());
      expect((caught as StateError).message, 'query failed');
      expect(client.requestedTables, [SupabaseConstants.adminUsersTable]);
    });
  });
}
