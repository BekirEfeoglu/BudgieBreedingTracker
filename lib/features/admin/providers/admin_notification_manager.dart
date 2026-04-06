import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import 'admin_auth_utils.dart';
import 'admin_data_providers.dart';

/// Manages admin notification operations (single and bulk).
///
/// Delegates state updates to the parent [AdminActionsNotifier] via callbacks.
class AdminNotificationManager {
  final Ref _ref;
  final void Function({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? successMessage,
  })
  _updateState;

  AdminNotificationManager(this._ref, this._updateState);

  /// Send an in-app notification and push notification to a single user.
  Future<void> sendNotification(String targetUserId, String title, String body) async {
    _updateState(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(_ref);
      final client = _ref.read(supabaseClientProvider);

      final sanitizedTitle = title.trim().length > 200
          ? title.trim().substring(0, 200)
          : title.trim();
      final sanitizedBody = body.trim().length > 1000
          ? body.trim().substring(0, 1000)
          : body.trim();

      await client.from(SupabaseConstants.notificationsTable).insert({
        'id': const Uuid().v4(),
        'user_id': targetUserId,
        'title': sanitizedTitle,
        'body': sanitizedBody,
        'type': 'custom',
        'priority': 'normal',
        'read': false,
      });

      final edgeClient = _ref.read(edgeFunctionClientProvider);
      final pushResult = await edgeClient.sendPush(
        userIds: [targetUserId],
        title: sanitizedTitle,
        body: sanitizedBody,
      );

      bool pushFailed;
      if (!pushResult.success) {
        pushFailed = true;
        AppLogger.warning(
          'AdminActions.sendNotification: push request failed: ${pushResult.error}',
        );
      } else {
        final deliveredRaw = pushResult.data?['success'];
        final delivered = (deliveredRaw is num) ? deliveredRaw.toInt() : 0;
        pushFailed = delivered == 0;
        if (pushFailed) {
          final failureRaw = pushResult.data?['failure'];
          final failure = (failureRaw is num) ? failureRaw.toInt() : 0;
          AppLogger.warning(
            'AdminActions.sendNotification: push delivered to 0 devices '
            '(failures: $failure, data: ${pushResult.data})',
          );
        }
      }

      await logAdminAction(
        client,
        _ref.read(currentUserIdProvider),
        'notification_sent',
        targetUserId: targetUserId,
        details: {'title': sanitizedTitle, 'push_delivered': !pushFailed},
      );

      _updateState(
        isLoading: false,
        isSuccess: true,
        successMessage: pushFailed
            ? 'admin.notification_sent_no_push'.tr()
            : 'admin.notification_sent'.tr(),
      );
    } catch (e, st) {
      AppLogger.error('AdminActions.sendNotification', e, st);
      _updateState(isLoading: false, error: 'admin.action_error'.tr());
    }
  }

  /// Send an in-app notification and push notification to multiple users.
  Future<void> sendBulkNotification(List<String> userIds, String title, String body) async {
    _updateState(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(_ref);
      final client = _ref.read(supabaseClientProvider);

      final sanitizedTitle = title.trim().length > 200
          ? title.trim().substring(0, 200)
          : title.trim();
      final sanitizedBody = body.trim().length > 1000
          ? body.trim().substring(0, 1000)
          : body.trim();

      final rows = userIds.map((uid) => {
        'id': const Uuid().v4(),
        'user_id': uid,
        'title': sanitizedTitle,
        'body': sanitizedBody,
        'type': 'custom',
        'priority': 'normal',
        'read': false,
      }).toList();

      await client.from(SupabaseConstants.notificationsTable).insert(rows);

      final edgeClient = _ref.read(edgeFunctionClientProvider);
      final pushResult = await edgeClient.sendPush(
        userIds: userIds,
        title: sanitizedTitle,
        body: sanitizedBody,
      );

      bool pushFailed;
      if (!pushResult.success) {
        pushFailed = true;
        AppLogger.warning(
          'AdminActions.sendBulkNotification: push request failed: ${pushResult.error}',
        );
      } else {
        final deliveredRaw = pushResult.data?['success'];
        final delivered = (deliveredRaw is num) ? deliveredRaw.toInt() : 0;
        pushFailed = delivered == 0;
        if (pushFailed) {
          final failureRaw = pushResult.data?['failure'];
          final failure = (failureRaw is num) ? failureRaw.toInt() : 0;
          AppLogger.warning(
            'AdminActions.sendBulkNotification: push delivered to 0 devices '
            '(failures: $failure, data: ${pushResult.data})',
          );
        }
      }

      await logAdminAction(
        client,
        _ref.read(currentUserIdProvider),
        'bulk_notification_sent',
        details: {
          'title': sanitizedTitle,
          'count': userIds.length,
          'push_delivered': !pushFailed,
        },
      );

      final countStr = '${userIds.length}';
      _updateState(
        isLoading: false,
        isSuccess: true,
        successMessage: pushFailed
            ? 'admin.notification_sent_bulk_no_push'.tr(args: [countStr])
            : 'admin.notification_sent_bulk'.tr(args: [countStr]),
      );
    } catch (e, st) {
      AppLogger.error('AdminActions.sendBulkNotification', e, st);
      _updateState(isLoading: false, error: 'admin.action_error'.tr());
    }
  }
}
