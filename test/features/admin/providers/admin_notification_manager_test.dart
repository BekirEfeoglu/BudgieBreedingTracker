// ignore_for_file: unused_element_parameter, must_be_immutable
import 'dart:async';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_data_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_notification_manager.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Fake Supabase builders (reused pattern from admin_actions_provider_test.dart)
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

class _FakeMutationBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  _FakeMutationBuilder({this.error});

  final Object? error;

  @override
  PostgrestFilterBuilder<dynamic> eq(String column, Object value) => this;

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

class _FakeMutationQueryBuilder extends Fake implements SupabaseQueryBuilder {
  _FakeMutationQueryBuilder({
    this.insertError,
  });

  final Object? insertError;
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
      _FakeMutationBuilder();

  @override
  PostgrestFilterBuilder<dynamic> delete() => _FakeMutationBuilder();

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) =>
      _FakeAdminCheckBuilder();
}

// ---------------------------------------------------------------------------
// Fake SupabaseClient
// ---------------------------------------------------------------------------

class _FakeNotificationClient extends Fake implements SupabaseClient {
  _FakeNotificationClient({
    required this.adminQueryBuilder,
    required this.notificationsQueryBuilder,
    required this.adminLogsQueryBuilder,
  });

  final _FakeAdminQueryBuilder adminQueryBuilder;
  final _FakeMutationQueryBuilder notificationsQueryBuilder;
  final _FakeMutationQueryBuilder adminLogsQueryBuilder;
  final requestedTables = <String>[];

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTables.add(table);
    switch (table) {
      case SupabaseConstants.adminUsersTable:
        return adminQueryBuilder;
      case SupabaseConstants.notificationsTable:
        return notificationsQueryBuilder;
      case SupabaseConstants.adminLogsTable:
        return adminLogsQueryBuilder;
    }
    throw StateError('Unexpected table: $table');
  }
}

// ---------------------------------------------------------------------------
// Fake EdgeFunctionClient
// ---------------------------------------------------------------------------

class _FakeEdgeFunctionClient extends Fake implements EdgeFunctionClient {
  _FakeEdgeFunctionClient({this.pushResult});

  final EdgeFunctionResult? pushResult;
  List<String>? lastPushUserIds;
  String? lastPushTitle;
  String? lastPushBody;
  int pushCallCount = 0;

  @override
  Future<EdgeFunctionResult> sendPush({
    List<String>? userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    pushCallCount++;
    lastPushUserIds = userIds;
    lastPushTitle = title;
    lastPushBody = body;
    return pushResult ??
        const EdgeFunctionResult(
          success: true,
          data: {'success': 1, 'failure': 0},
        );
  }
}

// ---------------------------------------------------------------------------
// State recorder
// ---------------------------------------------------------------------------

/// Mutable holder so the updateState callback can be captured before manager
/// creation and inspected after method calls.
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

_FakeNotificationClient _makeClient({
  PostgrestMap? adminUserResult,
  Object? notificationsInsertError,
  Object? logsInsertError,
}) {
  return _FakeNotificationClient(
    adminQueryBuilder: _FakeAdminQueryBuilder(
      _FakeAdminCheckBuilder(result: adminUserResult),
    ),
    notificationsQueryBuilder: _FakeMutationQueryBuilder(
      insertError: notificationsInsertError,
    ),
    adminLogsQueryBuilder: _FakeMutationQueryBuilder(
      insertError: logsInsertError,
    ),
  );
}

/// Creates a [ProviderContainer] and a provider that builds the
/// [AdminNotificationManager] with a real [Ref].
///
/// Returns both the container and the provider so callers can read the
/// manager from the container.
({ProviderContainer container, Provider<AdminNotificationManager> managerProvider})
    _makeContainerAndManager({
  required String userId,
  required _FakeNotificationClient client,
  required _FakeEdgeFunctionClient edgeClient,
  required _StateRecorder recorder,
}) {
  final managerProvider = Provider<AdminNotificationManager>((ref) {
    return AdminNotificationManager(ref, recorder.call);
  });

  final container = ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWithValue(userId),
      supabaseClientProvider.overrideWithValue(client),
      edgeFunctionClientProvider.overrideWithValue(edgeClient),
    ],
    retry: (_, __) => null,
  );

  return (container: container, managerProvider: managerProvider);
}

void main() {
  group('AdminNotificationManager', () {
    group('sendNotification', () {
      test('success path - admin check passes, insert and push succeed',
          () async {
        final client = _makeClient(
          adminUserResult: const {'id': 'admin-1'},
        );
        final edgeClient = _FakeEdgeFunctionClient(
          pushResult: const EdgeFunctionResult(
            success: true,
            data: {'success': 1, 'failure': 0},
          ),
        );
        final recorder = _StateRecorder();
        final setup = _makeContainerAndManager(
          userId: 'admin-user',
          client: client,
          edgeClient: edgeClient,
          recorder: recorder,
        );
        addTearDown(setup.container.dispose);

        final manager = setup.container.read(setup.managerProvider);
        await manager.sendNotification('target-user', 'Test Title', 'Test Body');

        // Verify state ends with success
        expect(recorder.isLoading, isFalse);
        expect(recorder.isSuccess, isTrue);
        expect(recorder.error, isNull);
        expect(recorder.successMessage, 'admin.notification_sent');

        // Verify notification insert was called
        expect(client.notificationsQueryBuilder.insertCallCount, 1);
        final payload = client.notificationsQueryBuilder.insertPayload
            as Map<String, dynamic>;
        expect(payload['user_id'], 'target-user');
        expect(payload['title'], 'Test Title');
        expect(payload['body'], 'Test Body');
        expect(payload['type'], 'custom');
        expect(payload['priority'], 'normal');
        expect(payload['read'], false);

        // Verify push was called
        expect(edgeClient.pushCallCount, 1);
        expect(edgeClient.lastPushUserIds, ['target-user']);
        expect(edgeClient.lastPushTitle, 'Test Title');
        expect(edgeClient.lastPushBody, 'Test Body');

        // Verify admin log was recorded
        expect(client.adminLogsQueryBuilder.insertCallCount, 1);
        final logPayload = client.adminLogsQueryBuilder.insertPayload
            as Map<String, dynamic>;
        expect(logPayload['action'], 'notification_sent');
        expect(logPayload['target_user_id'], 'target-user');
        expect(logPayload['admin_user_id'], 'admin-user');
        expect(
          (logPayload['details'] as Map)['push_delivered'],
          isTrue,
        );
      });

      test('push fails but in-app notification succeeds (pushFailed = true)',
          () async {
        final client = _makeClient(
          adminUserResult: const {'id': 'admin-1'},
        );
        final edgeClient = _FakeEdgeFunctionClient(
          pushResult: const EdgeFunctionResult(
            success: false,
            error: 'FCM unavailable',
          ),
        );
        final recorder = _StateRecorder();
        final setup = _makeContainerAndManager(
          userId: 'admin-user',
          client: client,
          edgeClient: edgeClient,
          recorder: recorder,
        );
        addTearDown(setup.container.dispose);

        final manager = setup.container.read(setup.managerProvider);
        await manager.sendNotification('target-user', 'Title', 'Body');

        expect(recorder.isSuccess, isTrue);
        expect(recorder.successMessage, 'admin.notification_sent_no_push');

        // Notification was still inserted
        expect(client.notificationsQueryBuilder.insertCallCount, 1);

        // Admin log records push_delivered as false
        final logPayload = client.adminLogsQueryBuilder.insertPayload
            as Map<String, dynamic>;
        expect(
          (logPayload['details'] as Map)['push_delivered'],
          isFalse,
        );
      });

      test('requireAdmin fails (not admin user)', () async {
        final client = _makeClient(adminUserResult: null);
        final edgeClient = _FakeEdgeFunctionClient();
        final recorder = _StateRecorder();
        final setup = _makeContainerAndManager(
          userId: 'non-admin',
          client: client,
          edgeClient: edgeClient,
          recorder: recorder,
        );
        addTearDown(setup.container.dispose);

        final manager = setup.container.read(setup.managerProvider);
        await manager.sendNotification('target-user', 'Title', 'Body');

        expect(recorder.isLoading, isFalse);
        expect(recorder.isSuccess, isFalse);
        expect(recorder.error, 'admin.action_error');

        // No notification insert or push should happen
        expect(client.notificationsQueryBuilder.insertCallCount, 0);
        expect(edgeClient.pushCallCount, 0);
      });

      test('sanitizes long title and body', () async {
        final client = _makeClient(
          adminUserResult: const {'id': 'admin-1'},
        );
        final edgeClient = _FakeEdgeFunctionClient(
          pushResult: const EdgeFunctionResult(
            success: true,
            data: {'success': 1, 'failure': 0},
          ),
        );
        final recorder = _StateRecorder();
        final setup = _makeContainerAndManager(
          userId: 'admin-user',
          client: client,
          edgeClient: edgeClient,
          recorder: recorder,
        );
        addTearDown(setup.container.dispose);

        final manager = setup.container.read(setup.managerProvider);

        final longTitle = 'A' * 300;
        final longBody = 'B' * 2000;

        await manager.sendNotification('target-user', longTitle, longBody);

        expect(recorder.isSuccess, isTrue);

        // Verify title was truncated to 200 chars
        final payload = client.notificationsQueryBuilder.insertPayload
            as Map<String, dynamic>;
        expect((payload['title'] as String).length, 200);
        expect(payload['title'], 'A' * 200);

        // Verify body was truncated to 1000 chars
        expect((payload['body'] as String).length, 1000);
        expect(payload['body'], 'B' * 1000);

        // Verify push also got sanitized values
        expect(edgeClient.lastPushTitle!.length, 200);
        expect(edgeClient.lastPushBody!.length, 1000);
      });

      test('push succeeds but delivered count is 0 (pushFailed = true)',
          () async {
        final client = _makeClient(
          adminUserResult: const {'id': 'admin-1'},
        );
        final edgeClient = _FakeEdgeFunctionClient(
          pushResult: const EdgeFunctionResult(
            success: true,
            data: {'success': 0, 'failure': 1},
          ),
        );
        final recorder = _StateRecorder();
        final setup = _makeContainerAndManager(
          userId: 'admin-user',
          client: client,
          edgeClient: edgeClient,
          recorder: recorder,
        );
        addTearDown(setup.container.dispose);

        final manager = setup.container.read(setup.managerProvider);
        await manager.sendNotification('target-user', 'Title', 'Body');

        expect(recorder.isSuccess, isTrue);
        expect(recorder.successMessage, 'admin.notification_sent_no_push');
      });
    });

    group('sendBulkNotification', () {
      test('success path - multiple users', () async {
        final client = _makeClient(
          adminUserResult: const {'id': 'admin-1'},
        );
        final edgeClient = _FakeEdgeFunctionClient(
          pushResult: const EdgeFunctionResult(
            success: true,
            data: {'success': 3, 'failure': 0},
          ),
        );
        final recorder = _StateRecorder();
        final setup = _makeContainerAndManager(
          userId: 'admin-user',
          client: client,
          edgeClient: edgeClient,
          recorder: recorder,
        );
        addTearDown(setup.container.dispose);

        final manager = setup.container.read(setup.managerProvider);
        final userIds = ['user-1', 'user-2', 'user-3'];
        await manager.sendBulkNotification(userIds, 'Bulk Title', 'Bulk Body');

        expect(recorder.isLoading, isFalse);
        expect(recorder.isSuccess, isTrue);
        expect(recorder.error, isNull);
        // .tr() in test returns the key itself
        expect(recorder.successMessage, 'admin.notification_sent_bulk');

        // Verify push was called with all user IDs
        expect(edgeClient.pushCallCount, 1);
        expect(edgeClient.lastPushUserIds, userIds);
        expect(edgeClient.lastPushTitle, 'Bulk Title');
        expect(edgeClient.lastPushBody, 'Bulk Body');

        // Verify admin log was recorded
        final logPayload = client.adminLogsQueryBuilder.insertPayload
            as Map<String, dynamic>;
        expect(logPayload['action'], 'bulk_notification_sent');
        expect(logPayload['admin_user_id'], 'admin-user');
        expect(
          (logPayload['details'] as Map)['count'],
          3,
        );
        expect(
          (logPayload['details'] as Map)['push_delivered'],
          isTrue,
        );
      });

      test('inserts correct number of notification rows', () async {
        final client = _makeClient(
          adminUserResult: const {'id': 'admin-1'},
        );
        final edgeClient = _FakeEdgeFunctionClient(
          pushResult: const EdgeFunctionResult(
            success: true,
            data: {'success': 3, 'failure': 0},
          ),
        );
        final recorder = _StateRecorder();
        final setup = _makeContainerAndManager(
          userId: 'admin-user',
          client: client,
          edgeClient: edgeClient,
          recorder: recorder,
        );
        addTearDown(setup.container.dispose);

        final manager = setup.container.read(setup.managerProvider);
        final userIds = ['user-1', 'user-2', 'user-3'];
        await manager.sendBulkNotification(userIds, 'Title', 'Body');

        // Verify insert was called once with a list of 3 rows
        expect(client.notificationsQueryBuilder.insertCallCount, 1);
        final rows = client.notificationsQueryBuilder.insertPayload
            as List<Map<String, dynamic>>;
        expect(rows.length, 3);

        // Verify each row has the correct user_id
        expect(rows[0]['user_id'], 'user-1');
        expect(rows[1]['user_id'], 'user-2');
        expect(rows[2]['user_id'], 'user-3');

        // Verify common fields
        for (final row in rows) {
          expect(row['title'], 'Title');
          expect(row['body'], 'Body');
          expect(row['type'], 'custom');
          expect(row['priority'], 'normal');
          expect(row['read'], false);
          expect(row['id'], isA<String>());
        }

        // Verify all IDs are unique
        final ids = rows.map((r) => r['id']).toSet();
        expect(ids.length, 3);
      });

      test('bulk push fails but in-app notifications succeed', () async {
        final client = _makeClient(
          adminUserResult: const {'id': 'admin-1'},
        );
        final edgeClient = _FakeEdgeFunctionClient(
          pushResult: const EdgeFunctionResult(
            success: false,
            error: 'FCM unavailable',
          ),
        );
        final recorder = _StateRecorder();
        final setup = _makeContainerAndManager(
          userId: 'admin-user',
          client: client,
          edgeClient: edgeClient,
          recorder: recorder,
        );
        addTearDown(setup.container.dispose);

        final manager = setup.container.read(setup.managerProvider);
        await manager.sendBulkNotification(
          ['user-1', 'user-2'],
          'Title',
          'Body',
        );

        expect(recorder.isSuccess, isTrue);
        expect(
          recorder.successMessage,
          'admin.notification_sent_bulk_no_push',
        );

        // Notifications still inserted
        expect(client.notificationsQueryBuilder.insertCallCount, 1);
      });

      test('requireAdmin fails for bulk notification', () async {
        final client = _makeClient(adminUserResult: null);
        final edgeClient = _FakeEdgeFunctionClient();
        final recorder = _StateRecorder();
        final setup = _makeContainerAndManager(
          userId: 'non-admin',
          client: client,
          edgeClient: edgeClient,
          recorder: recorder,
        );
        addTearDown(setup.container.dispose);

        final manager = setup.container.read(setup.managerProvider);
        await manager.sendBulkNotification(
          ['user-1', 'user-2'],
          'Title',
          'Body',
        );

        expect(recorder.isLoading, isFalse);
        expect(recorder.isSuccess, isFalse);
        expect(recorder.error, 'admin.action_error');
        expect(client.notificationsQueryBuilder.insertCallCount, 0);
        expect(edgeClient.pushCallCount, 0);
      });
    });
  });
}
