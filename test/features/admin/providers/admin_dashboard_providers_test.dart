import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/admin_enums.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_dashboard_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

// ---------------------------------------------------------------------------
// Fake Supabase infrastructure
// ---------------------------------------------------------------------------

class _FakeMaybeSingleBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestMap?> {
  _FakeMaybeSingleBuilder({this.result});

  final PostgrestMap? result;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestMap? value) onValue, {
    Function? onError,
  }) =>
      Future<S>.value(onValue(result));
}

class _FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  _FakeFilterBuilder({
    required this.maybeSingleResult,
    this.listResult = const [],
  });

  final PostgrestMap? maybeSingleResult;
  final List<Map<String, dynamic>> listResult;

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<PostgrestList> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) =>
      this;

  @override
  PostgrestTransformBuilder<PostgrestList> limit(
    int count, {
    String? referencedTable,
  }) =>
      this;

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() =>
      _FakeMaybeSingleBuilder(result: maybeSingleResult);

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestList value) onValue, {
    Function? onError,
  }) =>
      Future<S>.value(onValue(listResult));
}

class _FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeQueryBuilder(this.filterBuilder);

  final _FakeFilterBuilder filterBuilder;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) =>
      filterBuilder;
}

/// Table-aware fake client: admin users table → returns maybeSingle result;
/// all other tables → return the configured list result.
class _FakeSupabaseClient extends Fake implements SupabaseClient {
  _FakeSupabaseClient({
    required this.adminUserResult,
    this.tableResults = const {},
  });

  final PostgrestMap? adminUserResult;
  final Map<String, List<Map<String, dynamic>>> tableResults;
  final requestedTables = <String>[];

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTables.add(table);
    if (table == SupabaseConstants.adminUsersTable) {
      return _FakeQueryBuilder(
        _FakeFilterBuilder(
          maybeSingleResult: adminUserResult,
          listResult: const [],
        ),
      );
    }
    final result = tableResults[table] ?? const [];
    return _FakeQueryBuilder(
      _FakeFilterBuilder(maybeSingleResult: null, listResult: result),
    );
  }
}

ProviderContainer _makeContainer({
  required String userId,
  required _FakeSupabaseClient client,
}) {
  return ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      supabaseClientProvider.overrideWithValue(client),
    ],
    retry: (_, __) => null,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // adminSystemAlertsProvider
  // -------------------------------------------------------------------------
  group('adminSystemAlertsProvider', () {
    test('throws for anonymous user', () async {
      final client = _FakeSupabaseClient(adminUserResult: {'id': 'admin-1'});
      final container = _makeContainer(userId: 'anonymous', client: client);
      final sub = container.listen(adminSystemAlertsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      await expectLater(
        container.read(adminSystemAlertsProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('returns empty list when no alerts exist', () async {
      final client = _FakeSupabaseClient(adminUserResult: {'id': 'admin-1'});
      final container = _makeContainer(userId: 'user-1', client: client);
      final sub = container.listen(adminSystemAlertsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final result = await container.read(adminSystemAlertsProvider.future);
      expect(result, isEmpty);
    });

    test('returns parsed SystemAlert list for authenticated admin', () async {
      final client = _FakeSupabaseClient(
        adminUserResult: {'id': 'admin-1'},
        tableResults: {
          SupabaseConstants.systemAlertsTable: [
            {
              'id': 'alert-1',
              'title': 'High CPU',
              'message': 'CPU at 95%',
              'severity': 'critical',
              'alert_type': 'system',
              'is_active': true,
              'is_acknowledged': false,
              'created_at': '2026-01-01T00:00:00.000Z',
            },
            {
              'id': 'alert-2',
              'title': 'Low Disk',
              'message': 'Disk at 85%',
              'severity': 'warning',
              'alert_type': 'storage',
              'is_active': true,
              'is_acknowledged': false,
              'created_at': '2026-01-02T00:00:00.000Z',
            },
          ],
        },
      );
      final container = _makeContainer(userId: 'user-1', client: client);
      final sub = container.listen(adminSystemAlertsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final result = await container.read(adminSystemAlertsProvider.future);
      expect(result, hasLength(2));
      expect(result.first.id, 'alert-1');
      expect(result.first.title, 'High CPU');
      expect(result.first.severity, AlertSeverity.critical);
      expect(result[1].id, 'alert-2');
      expect(result[1].severity, AlertSeverity.warning);
    });

    test('queries admin users table and system alerts table', () async {
      final client = _FakeSupabaseClient(adminUserResult: {'id': 'admin-1'});
      final container = _makeContainer(userId: 'user-1', client: client);
      final sub = container.listen(adminSystemAlertsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      await container.read(adminSystemAlertsProvider.future);
      expect(
        client.requestedTables,
        containsAll([
          SupabaseConstants.adminUsersTable,
          SupabaseConstants.systemAlertsTable,
        ]),
      );
    });
  });

  // -------------------------------------------------------------------------
  // adminPendingReviewCountProvider
  // -------------------------------------------------------------------------
  group('adminPendingReviewCountProvider', () {
    test('throws for anonymous user', () async {
      final client = _FakeSupabaseClient(adminUserResult: {'id': 'admin-1'});
      final container =
          _makeContainer(userId: 'anonymous', client: client);
      final sub =
          container.listen(adminPendingReviewCountProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      await expectLater(
        container.read(adminPendingReviewCountProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('returns 0 when no content needs review', () async {
      final client = _FakeSupabaseClient(adminUserResult: {'id': 'admin-1'});
      final container = _makeContainer(userId: 'user-1', client: client);
      final sub =
          container.listen(adminPendingReviewCountProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final result =
          await container.read(adminPendingReviewCountProvider.future);
      expect(result, 0);
    });

    test('returns sum of posts and comments needing review', () async {
      final client = _FakeSupabaseClient(
        adminUserResult: {'id': 'admin-1'},
        tableResults: {
          SupabaseConstants.communityPostsTable: [
            {'id': 'post-1'},
            {'id': 'post-2'},
          ],
          SupabaseConstants.communityCommentsTable: [
            {'id': 'comment-1'},
          ],
        },
      );
      final container = _makeContainer(userId: 'user-1', client: client);
      final sub =
          container.listen(adminPendingReviewCountProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final result =
          await container.read(adminPendingReviewCountProvider.future);
      expect(result, 3); // 2 posts + 1 comment
    });

    test('queries posts and comments tables', () async {
      final client = _FakeSupabaseClient(
        adminUserResult: {'id': 'admin-1'},
        tableResults: {
          SupabaseConstants.communityPostsTable: [{'id': 'p1'}],
          SupabaseConstants.communityCommentsTable: [{'id': 'c1'}],
        },
      );
      final container = _makeContainer(userId: 'user-1', client: client);
      final sub =
          container.listen(adminPendingReviewCountProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      await container.read(adminPendingReviewCountProvider.future);
      expect(
        client.requestedTables,
        containsAll([
          SupabaseConstants.adminUsersTable,
          SupabaseConstants.communityPostsTable,
          SupabaseConstants.communityCommentsTable,
        ]),
      );
    });
  });

  // -------------------------------------------------------------------------
  // recentAdminActionsProvider
  // -------------------------------------------------------------------------
  group('recentAdminActionsProvider', () {
    test('throws for anonymous user', () async {
      final client = _FakeSupabaseClient(adminUserResult: {'id': 'admin-1'});
      final container =
          _makeContainer(userId: 'anonymous', client: client);
      final sub =
          container.listen(recentAdminActionsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      await expectLater(
        container.read(recentAdminActionsProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('returns empty list when no recent actions', () async {
      final client = _FakeSupabaseClient(adminUserResult: {'id': 'admin-1'});
      final container = _makeContainer(userId: 'user-1', client: client);
      final sub =
          container.listen(recentAdminActionsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final result =
          await container.read(recentAdminActionsProvider.future);
      expect(result, isEmpty);
    });

    test('returns parsed AdminLog list for authenticated admin', () async {
      final client = _FakeSupabaseClient(
        adminUserResult: {'id': 'admin-1'},
        tableResults: {
          SupabaseConstants.adminLogsTable: [
            {
              'id': 'log-1',
              'action': 'user.ban',
              'admin_user_id': 'admin-1',
              'target_user_id': 'user-1',
              'created_at': '2026-01-01T00:00:00.000Z',
            },
            {
              'id': 'log-2',
              'action': 'system.update',
              'admin_user_id': 'admin-1',
              'created_at': '2026-01-02T00:00:00.000Z',
            },
          ],
        },
      );
      final container = _makeContainer(userId: 'user-1', client: client);
      final sub =
          container.listen(recentAdminActionsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final result =
          await container.read(recentAdminActionsProvider.future);
      expect(result, hasLength(2));
      expect(result.first.id, 'log-1');
      expect(result.first.action, 'user.ban');
      expect(result[1].action, 'system.update');
    });

    test('queries admin logs table', () async {
      final client = _FakeSupabaseClient(adminUserResult: {'id': 'admin-1'});
      final container = _makeContainer(userId: 'user-1', client: client);
      final sub =
          container.listen(recentAdminActionsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      await container.read(recentAdminActionsProvider.future);
      expect(
        client.requestedTables,
        containsAll([
          SupabaseConstants.adminUsersTable,
          SupabaseConstants.adminLogsTable,
        ]),
      );
    });
  });

  // -------------------------------------------------------------------------
  // adminSystemSettingsProvider
  // -------------------------------------------------------------------------
  group('adminSystemSettingsProvider', () {
    test('throws for anonymous user', () async {
      final client = _FakeSupabaseClient(adminUserResult: {'id': 'admin-1'});
      final container =
          _makeContainer(userId: 'anonymous', client: client);
      final sub =
          container.listen(adminSystemSettingsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      await expectLater(
        container.read(adminSystemSettingsProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('returns empty map when no settings exist', () async {
      final client = _FakeSupabaseClient(adminUserResult: {'id': 'admin-1'});
      final container = _makeContainer(userId: 'user-1', client: client);
      final sub =
          container.listen(adminSystemSettingsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final result =
          await container.read(adminSystemSettingsProvider.future);
      expect(result, isEmpty);
    });

    test('returns settings map with correct structure', () async {
      final client = _FakeSupabaseClient(
        adminUserResult: {'id': 'admin-1'},
        tableResults: {
          SupabaseConstants.systemSettingsTable: [
            {
              'key': 'max_upload_size',
              'value': '10MB',
              'updated_at': '2026-01-01T00:00:00.000Z',
              'category': 'storage',
              'updated_by': 'admin-1',
            },
            {
              'key': 'maintenance_mode',
              'value': 'false',
              'updated_at': null,
              'category': 'system',
              'updated_by': null,
            },
          ],
        },
      );
      final container = _makeContainer(userId: 'user-1', client: client);
      final sub =
          container.listen(adminSystemSettingsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final result =
          await container.read(adminSystemSettingsProvider.future);
      expect(result, hasLength(2));
      expect(result.containsKey('max_upload_size'), isTrue);
      expect(result['max_upload_size']?['value'], '10MB');
      expect(result['max_upload_size']?['category'], 'storage');
      expect(result.containsKey('maintenance_mode'), isTrue);
      expect(result['maintenance_mode']?['category'], 'system');
      expect(result['maintenance_mode']?['updated_by'], isNull);
    });
  });
}
