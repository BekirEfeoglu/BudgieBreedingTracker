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

class _RpcCall {
  const _RpcCall(this.fn, this.params);

  final String fn;
  final Map<String, dynamic>? params;
}

class _FakeRpcBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  _FakeRpcBuilder({this.error});

  final Object? error;

  @override
  Future<S> then<S>(
    FutureOr<S> Function(T value) onValue, {
    Function? onError,
  }) {
    if (error != null) {
      return Future<T>.error(error!).then(onValue, onError: onError);
    }
    return Future<T>.value(null as T).then(onValue, onError: onError);
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
  _FakeMutationQueryBuilder({this.insertError});

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

  /// `upsert` is wired through the same counters as `insert` so existing
  /// assertions on `insertCallCount` / `insertPayload` keep working after
  /// the notification path migrated to `.upsert(..., onConflict: 'id')`
  /// for idempotency on retry.
  @override
  PostgrestFilterBuilder<dynamic> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
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
  }) => _FakeMutationBuilder();

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
    this.rpcErrors = const {},
    List<String>? operationLog,
  }) : operationLog = operationLog ?? <String>[];

  final _FakeAdminQueryBuilder adminQueryBuilder;
  final _FakeMutationQueryBuilder notificationsQueryBuilder;
  final _FakeMutationQueryBuilder adminLogsQueryBuilder;
  final Map<String, Object> rpcErrors;
  final List<String> operationLog;
  final requestedTables = <String>[];
  final rpcCalls = <_RpcCall>[];

  @override
  SupabaseQueryBuilder from(String table) {
    requestedTables.add(table);
    switch (table) {
      case SupabaseConstants.profilesTable:
        return adminQueryBuilder;
      case SupabaseConstants.notificationsTable:
        return notificationsQueryBuilder;
      case SupabaseConstants.adminLogsTable:
        return adminLogsQueryBuilder;
    }
    throw StateError('Unexpected table: $table');
  }

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    get = false,
  }) {
    operationLog.add('rpc:$fn');
    rpcCalls.add(_RpcCall(fn, params));
    return _FakeRpcBuilder<T>(error: rpcErrors[fn]);
  }
}

// ---------------------------------------------------------------------------
// Fake EdgeFunctionClient
// ---------------------------------------------------------------------------

class _FakeEdgeFunctionClient extends Fake implements EdgeFunctionClient {
  _FakeEdgeFunctionClient({this.pushResult, List<String>? operationLog})
    : operationLog = operationLog ?? <String>[];

  final EdgeFunctionResult? pushResult;
  final List<String> operationLog;
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
    bool respectQuietHours = false,
  }) async {
    operationLog.add('push');
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
  Map<String, Object> rpcErrors = const {},
  List<String>? operationLog,
}) {
  final normalizedAdminResult = adminUserResult == null
      ? null
      : {'is_active': true, ...adminUserResult};
  return _FakeNotificationClient(
    adminQueryBuilder: _FakeAdminQueryBuilder(
      _FakeAdminCheckBuilder(result: normalizedAdminResult),
    ),
    notificationsQueryBuilder: _FakeMutationQueryBuilder(
      insertError: notificationsInsertError,
    ),
    adminLogsQueryBuilder: _FakeMutationQueryBuilder(
      insertError: logsInsertError,
    ),
    rpcErrors: rpcErrors,
    operationLog: operationLog,
  );
}

/// Creates a [ProviderContainer] and a provider that builds the
/// [AdminNotificationManager] with a real [Ref].
///
/// Returns both the container and the provider so callers can read the
/// manager from the container.
({
  ProviderContainer container,
  Provider<AdminNotificationManager> managerProvider,
})
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
  addTearDown(container.dispose);

  return (container: container, managerProvider: managerProvider);
}

void main() {
  group('AdminNotificationManager', () {
    group('sendNotification', () {
      test(
        'success path - admin check passes, insert and push succeed',
        () async {
          final operationLog = <String>[];
          final client = _makeClient(
            adminUserResult: const {'role': 'admin'},
            operationLog: operationLog,
          );
          final edgeClient = _FakeEdgeFunctionClient(
            operationLog: operationLog,
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
          await manager.sendNotification(
            'target-user',
            'Test Title',
            'Test Body',
          );

          // Verify state ends with success
          expect(recorder.isLoading, isFalse);
          expect(recorder.isSuccess, isTrue);
          expect(recorder.error, isNull);
          expect(recorder.successMessage, 'admin.notification_sent');

          // Verify push was called
          expect(edgeClient.pushCallCount, 1);
          expect(edgeClient.lastPushUserIds, ['target-user']);
          expect(edgeClient.lastPushTitle, 'Test Title');
          expect(edgeClient.lastPushBody, 'Test Body');

          expect(operationLog, [
            'rpc:admin_send_notification',
            'push',
            'rpc:admin_update_notification_delivery',
          ]);

          // Verify in-app notification + audit are delegated to RPC before push.
          expect(client.rpcCalls, hasLength(2));
          expect(client.rpcCalls.first.fn, 'admin_send_notification');
          expect(client.rpcCalls.first.params, {
            'target_user_id': 'target-user',
            'p_title': 'Test Title',
            'p_body': 'Test Body',
          });
          expect(client.rpcCalls.last.fn, 'admin_update_notification_delivery');
          expect(client.rpcCalls.last.params, {
            'target_user_id': 'target-user',
            'p_push_delivered': true,
          });
          expect(client.notificationsQueryBuilder.insertCallCount, 0);
          expect(client.adminLogsQueryBuilder.insertCallCount, 0);
        },
      );

      test(
        'push fails but in-app notification succeeds (pushFailed = true)',
        () async {
          final client = _makeClient(adminUserResult: const {'role': 'admin'});
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

          // Notification + audit are still created by the server RPC.
          expect(client.rpcCalls.first.fn, 'admin_send_notification');
          expect(client.rpcCalls.last.fn, 'admin_update_notification_delivery');
          expect(client.rpcCalls.last.params?['p_push_delivered'], isFalse);
          expect(client.notificationsQueryBuilder.insertCallCount, 0);
        },
      );

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
        expect(client.rpcCalls, isEmpty);
        expect(edgeClient.pushCallCount, 0);
      });

      test('sanitizes long title and body', () async {
        final client = _makeClient(adminUserResult: const {'role': 'admin'});
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

        // Verify title/body were truncated before the RPC write.
        final params = client.rpcCalls.first.params!;
        expect((params['p_title'] as String).length, 200);
        expect(params['p_title'], 'A' * 200);
        expect((params['p_body'] as String).length, 1000);
        expect(params['p_body'], 'B' * 1000);

        // Verify push also got sanitized values
        expect(edgeClient.lastPushTitle!.length, 200);
        expect(edgeClient.lastPushBody!.length, 1000);
      });

      test(
        'push succeeds but delivered count is 0 (pushFailed = true)',
        () async {
          final client = _makeClient(adminUserResult: const {'role': 'admin'});
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
        },
      );
    });

    group('sendBulkNotification', () {
      test('success path - multiple users', () async {
        final operationLog = <String>[];
        final client = _makeClient(
          adminUserResult: const {'role': 'admin'},
          operationLog: operationLog,
        );
        final edgeClient = _FakeEdgeFunctionClient(
          operationLog: operationLog,
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

        expect(operationLog, [
          'rpc:admin_send_bulk_notification',
          'push',
          'rpc:admin_update_bulk_notification_delivery',
        ]);

        // Verify in-app notification batch + audit are delegated to RPC first.
        expect(client.rpcCalls, hasLength(2));
        expect(client.rpcCalls.first.fn, 'admin_send_bulk_notification');
        expect(client.rpcCalls.first.params, {
          'p_user_ids': userIds,
          'p_title': 'Bulk Title',
          'p_body': 'Bulk Body',
        });
        expect(
          client.rpcCalls.last.fn,
          'admin_update_bulk_notification_delivery',
        );
        expect(client.rpcCalls.last.params, {
          'p_user_ids': userIds,
          'p_push_delivered': true,
        });
        expect(client.adminLogsQueryBuilder.insertCallCount, 0);
      });

      test('passes all recipients to the bulk notification RPC', () async {
        final client = _makeClient(adminUserResult: const {'role': 'admin'});
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

        expect(client.rpcCalls.first.fn, 'admin_send_bulk_notification');
        expect(client.rpcCalls.first.params?['p_user_ids'], userIds);
        expect(client.rpcCalls.first.params?['p_title'], 'Title');
        expect(client.rpcCalls.first.params?['p_body'], 'Body');
        expect(client.notificationsQueryBuilder.insertCallCount, 0);
      });

      test('bulk push fails but in-app notifications succeed', () async {
        final client = _makeClient(adminUserResult: const {'role': 'admin'});
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
        expect(recorder.successMessage, 'admin.notification_sent_bulk_no_push');

        // Notifications are still created by the server RPC.
        expect(client.rpcCalls.first.fn, 'admin_send_bulk_notification');
        expect(
          client.rpcCalls.last.fn,
          'admin_update_bulk_notification_delivery',
        );
        expect(client.rpcCalls.last.params?['p_push_delivered'], isFalse);
        expect(client.notificationsQueryBuilder.insertCallCount, 0);
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
        expect(client.rpcCalls, isEmpty);
        expect(edgeClient.pushCallCount, 0);
      });
    });
  });
}
