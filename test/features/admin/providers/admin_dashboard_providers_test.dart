import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/admin_enums.dart';
import 'package:budgie_breeding_tracker/features/admin/constants/admin_constants.dart';
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
  }) => Future<S>.value(onValue(result));
}

class _FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  _FakeFilterBuilder({
    required this.maybeSingleResult,
    this.listResult = const [],
  });

  final PostgrestMap? maybeSingleResult;
  final List<Map<String, dynamic>> listResult;
  final eqCalls = <MapEntry<String, Object>>[];
  final orderCalls = <({String column, bool ascending})>[];
  final limitCalls = <int>[];

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    eqCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestList> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    orderCalls.add((column: column, ascending: ascending));
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestList> limit(
    int count, {
    String? referencedTable,
  }) {
    limitCalls.add(count);
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() =>
      _FakeMaybeSingleBuilder(result: maybeSingleResult);

  @override
  Future<S> then<S>(
    FutureOr<S> Function(PostgrestList value) onValue, {
    Function? onError,
  }) => Future<S>.value(onValue(listResult));
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
  final buildersByTable = <String, _FakeQueryBuilder>{};

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTables.add(table);
    if (table == SupabaseConstants.profilesTable) {
      return buildersByTable.putIfAbsent(
        table,
        () => _FakeQueryBuilder(
          _FakeFilterBuilder(
            maybeSingleResult: adminUserResult,
            listResult: const [],
          ),
        ),
      );
    }
    final result = tableResults[table] ?? const [];
    return buildersByTable.putIfAbsent(
      table,
      () => _FakeQueryBuilder(
        _FakeFilterBuilder(maybeSingleResult: null, listResult: result),
      ),
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
      final client = _FakeSupabaseClient(adminUserResult: {'role': 'admin'});
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
      final client = _FakeSupabaseClient(adminUserResult: {'role': 'admin'});
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
        adminUserResult: {'role': 'admin'},
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
      final client = _FakeSupabaseClient(adminUserResult: {'role': 'admin'});
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
          SupabaseConstants.profilesTable,
          SupabaseConstants.systemAlertsTable,
        ]),
      );
      final alertsBuilder =
          client.buildersByTable[SupabaseConstants.systemAlertsTable]!;
      expect(alertsBuilder.selectedColumns, ['*']);
      expect(alertsBuilder.filterBuilder.eqCalls, hasLength(2));
      expect(alertsBuilder.filterBuilder.eqCalls.first.key, 'is_active');
      expect(alertsBuilder.filterBuilder.eqCalls.first.value, true);
      expect(alertsBuilder.filterBuilder.eqCalls[1].key, 'is_acknowledged');
      expect(alertsBuilder.filterBuilder.eqCalls[1].value, false);
      expect(
        alertsBuilder.filterBuilder.orderCalls.single.column,
        'created_at',
      );
      expect(alertsBuilder.filterBuilder.orderCalls.single.ascending, isFalse);
      expect(
        alertsBuilder.filterBuilder.limitCalls.single,
        AdminConstants.maxAlertsLimit,
      );
    });
  });

  // -------------------------------------------------------------------------
  // adminPendingReviewCountProvider
  // -------------------------------------------------------------------------
  group('adminPendingReviewCountProvider', () {
    test('throws for anonymous user', () async {
      final client = _FakeSupabaseClient(adminUserResult: {'role': 'admin'});
      final container = _makeContainer(userId: 'anonymous', client: client);
      final sub = container.listen(adminPendingReviewCountProvider, (_, __) {});
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
      final client = _FakeSupabaseClient(adminUserResult: {'role': 'admin'});
      final container = _makeContainer(userId: 'user-1', client: client);
      final sub = container.listen(adminPendingReviewCountProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final result = await container.read(
        adminPendingReviewCountProvider.future,
      );
      expect(result, 0);
    });

    test('returns sum of posts and comments needing review', () async {
      final client = _FakeSupabaseClient(
        adminUserResult: {'role': 'admin'},
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
      final sub = container.listen(adminPendingReviewCountProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final result = await container.read(
        adminPendingReviewCountProvider.future,
      );
      expect(result, 3); // 2 posts + 1 comment
    });

    test('queries posts and comments tables', () async {
      final client = _FakeSupabaseClient(
        adminUserResult: {'role': 'admin'},
        tableResults: {
          SupabaseConstants.communityPostsTable: [
            {'id': 'p1'},
          ],
          SupabaseConstants.communityCommentsTable: [
            {'id': 'c1'},
          ],
        },
      );
      final container = _makeContainer(userId: 'user-1', client: client);
      final sub = container.listen(adminPendingReviewCountProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      await container.read(adminPendingReviewCountProvider.future);
      expect(
        client.requestedTables,
        containsAll([
          SupabaseConstants.profilesTable,
          SupabaseConstants.communityPostsTable,
          SupabaseConstants.communityCommentsTable,
        ]),
      );
      final postsBuilder =
          client.buildersByTable[SupabaseConstants.communityPostsTable]!;
      final commentsBuilder =
          client.buildersByTable[SupabaseConstants.communityCommentsTable]!;
      expect(postsBuilder.selectedColumns, ['id']);
      expect(commentsBuilder.selectedColumns, ['id']);
      expect(postsBuilder.filterBuilder.eqCalls, hasLength(2));
      expect(postsBuilder.filterBuilder.eqCalls.first.key, 'is_deleted');
      expect(postsBuilder.filterBuilder.eqCalls.first.value, false);
      expect(postsBuilder.filterBuilder.eqCalls[1].key, 'needs_review');
      expect(postsBuilder.filterBuilder.eqCalls[1].value, true);
      expect(commentsBuilder.filterBuilder.eqCalls, hasLength(2));
      expect(commentsBuilder.filterBuilder.eqCalls.first.key, 'is_deleted');
      expect(commentsBuilder.filterBuilder.eqCalls.first.value, false);
      expect(commentsBuilder.filterBuilder.eqCalls[1].key, 'needs_review');
      expect(commentsBuilder.filterBuilder.eqCalls[1].value, true);
    });
  });

  // -------------------------------------------------------------------------
  // recentAdminActionsProvider
  // -------------------------------------------------------------------------
  group('recentAdminActionsProvider', () {
    test('throws for anonymous user', () async {
      final client = _FakeSupabaseClient(adminUserResult: {'role': 'admin'});
      final container = _makeContainer(userId: 'anonymous', client: client);
      final sub = container.listen(recentAdminActionsProvider, (_, __) {});
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
      final client = _FakeSupabaseClient(adminUserResult: {'role': 'admin'});
      final container = _makeContainer(userId: 'user-1', client: client);
      final sub = container.listen(recentAdminActionsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final result = await container.read(recentAdminActionsProvider.future);
      expect(result, isEmpty);
    });

    test('returns parsed AdminLog list for authenticated admin', () async {
      final client = _FakeSupabaseClient(
        adminUserResult: {'role': 'admin'},
        tableResults: {
          SupabaseConstants.adminLogsTable: [
            {
              'id': 'log-1',
              'action': 'user.ban',
              'admin_user_id': 'admin-1',
              'target_user_id': 'user-1',
              'details': {'message': 'manual review'},
              'created_at': '2026-01-01T00:00:00.000Z',
            },
            {
              'id': 'log-2',
              'action': 'system.update',
              'admin_user_id': 'admin-1',
              'details': ['cache', 'warm'],
              'created_at': '2026-01-02T00:00:00.000Z',
            },
          ],
        },
      );
      final container = _makeContainer(userId: 'user-1', client: client);
      final sub = container.listen(recentAdminActionsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final result = await container.read(recentAdminActionsProvider.future);
      expect(result, hasLength(2));
      expect(result.first.id, 'log-1');
      expect(result.first.action, 'user.ban');
      expect(result.first.details, 'manual review');
      expect(result[1].action, 'system.update');
      expect(result[1].details, 'cache, warm');
    });

    test('queries admin logs table', () async {
      final client = _FakeSupabaseClient(adminUserResult: {'role': 'admin'});
      final container = _makeContainer(userId: 'user-1', client: client);
      final sub = container.listen(recentAdminActionsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      await container.read(recentAdminActionsProvider.future);
      expect(
        client.requestedTables,
        containsAll([
          SupabaseConstants.profilesTable,
          SupabaseConstants.adminLogsTable,
        ]),
      );
      final logsBuilder =
          client.buildersByTable[SupabaseConstants.adminLogsTable]!;
      expect(logsBuilder.selectedColumns, ['*']);
      expect(logsBuilder.filterBuilder.orderCalls.single.column, 'created_at');
      expect(logsBuilder.filterBuilder.orderCalls.single.ascending, isFalse);
      expect(
        logsBuilder.filterBuilder.limitCalls.single,
        AdminConstants.recentActionsLimit,
      );
    });
  });

  // -------------------------------------------------------------------------
  // adminSystemSettingsProvider
  // -------------------------------------------------------------------------
  group('adminSystemSettingsProvider', () {
    test('throws for anonymous user', () async {
      final client = _FakeSupabaseClient(adminUserResult: {'role': 'admin'});
      final container = _makeContainer(userId: 'anonymous', client: client);
      final sub = container.listen(adminSystemSettingsProvider, (_, __) {});
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
      final client = _FakeSupabaseClient(adminUserResult: {'role': 'admin'});
      final container = _makeContainer(userId: 'user-1', client: client);
      final sub = container.listen(adminSystemSettingsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final result = await container.read(adminSystemSettingsProvider.future);
      expect(result, isEmpty);
    });

    test('returns settings map with correct structure', () async {
      final client = _FakeSupabaseClient(
        adminUserResult: {'role': 'admin'},
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
      final sub = container.listen(adminSystemSettingsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final result = await container.read(adminSystemSettingsProvider.future);
      expect(result, hasLength(2));
      expect(result.containsKey('max_upload_size'), isTrue);
      expect(result['max_upload_size']?['value'], '10MB');
      expect(result['max_upload_size']?['category'], 'storage');
      expect(result.containsKey('maintenance_mode'), isTrue);
      expect(result['maintenance_mode']?['category'], 'system');
      expect(result['maintenance_mode']?['updated_by'], isNull);
    });

    test('last duplicate system setting row wins for same key', () async {
      final client = _FakeSupabaseClient(
        adminUserResult: {'role': 'admin'},
        tableResults: {
          SupabaseConstants.systemSettingsTable: [
            {
              'key': 'maintenance_mode',
              'value': 'false',
              'updated_at': '2026-01-01T00:00:00.000Z',
              'category': 'system',
              'updated_by': 'admin-1',
            },
            {
              'key': 'maintenance_mode',
              'value': 'true',
              'updated_at': '2026-01-02T00:00:00.000Z',
              'category': 'system',
              'updated_by': 'admin-2',
            },
          ],
        },
      );
      final container = _makeContainer(userId: 'user-1', client: client);
      final sub = container.listen(adminSystemSettingsProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final result = await container.read(adminSystemSettingsProvider.future);

      expect(result, hasLength(1));
      expect(result['maintenance_mode']?['value'], 'true');
      expect(result['maintenance_mode']?['updated_by'], 'admin-2');
    });
  });
}
