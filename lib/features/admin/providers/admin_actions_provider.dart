import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../constants/admin_constants.dart';
import '../../auth/providers/auth_providers.dart';
import 'admin_auth_utils.dart';
import 'admin_dashboard_providers.dart';
import 'admin_data_providers.dart';
import 'admin_database_manager.dart';
import 'admin_filter_providers.dart';
import 'admin_user_manager.dart';

part 'admin_actions_bulk.dart';

enum ExportFormat { json, csv }

// ignore: unused_element
String _toCsv(List<Map<String, dynamic>> rows) {
  if (rows.isEmpty) return '';
  final headers = rows.first.keys.join(',');
  final lines = rows.map(
    (r) => r.values
        .map((v) => '"${(v ?? '').toString().replaceAll('"', '""')}"')
        .join(','),
  );
  return [headers, ...lines].join('\n');
}

/// State for admin actions (loading, error, success).
class AdminActionState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final String? successMessage;

  const AdminActionState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.successMessage,
  });

  AdminActionState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? successMessage,
  }) => AdminActionState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    isSuccess: isSuccess ?? this.isSuccess,
    successMessage: successMessage,
  );
}

/// Notifier for admin actions (user management, event dismissal, log clearing,
/// database export/reset).
///
/// Delegates user management to [AdminUserManager] and database operations
/// to [AdminDatabaseManager].
class AdminActionsNotifier extends Notifier<AdminActionState> {
  late final AdminUserManager _userManager;
  late final AdminDatabaseManager _databaseManager;

  @override
  AdminActionState build() {
    _userManager = AdminUserManager(ref, _updateState);
    _databaseManager = AdminDatabaseManager(ref, _updateState);
    return const AdminActionState();
  }

  void _updateState({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? successMessage,
  }) {
    state = AdminActionState(
      isLoading: isLoading ?? state.isLoading,
      error: error,
      isSuccess: isSuccess ?? state.isSuccess,
      successMessage: successMessage,
    );
  }

  // ── User Management (delegated) ──────────────────────

  /// Toggle user active/inactive status.
  Future<void> toggleUserActive(String targetUserId, bool isActive) =>
      _userManager.toggleUserActive(targetUserId, isActive);

  /// Grant premium subscription to a user.
  Future<void> grantPremium(String targetUserId) =>
      _userManager.grantPremium(targetUserId);

  /// Revoke premium subscription from a user.
  Future<void> revokePremium(String targetUserId) =>
      _userManager.revokePremium(targetUserId);

  // ── Database Operations (delegated) ──────────────────

  /// Export a single table's data as JSON string.
  Future<String?> exportTable(String tableName) =>
      _databaseManager.exportTable(tableName);

  /// Export all tables' data as a single JSON string.
  Future<String?> exportAllTables() => _databaseManager.exportAllTables();

  /// Reset (truncate) a single table.
  Future<bool> resetTable(String tableName) =>
      _databaseManager.resetTable(tableName);

  /// Reset all user data tables (protected system tables are preserved).
  Future<bool> resetAllUserData() => _databaseManager.resetAllUserData();

  // ── Security & Audit (local) ─────────────────────────

  /// Dismiss (resolve) a security event.
  Future<void> dismissSecurityEvent(String eventId) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(ref);
      final client = ref.read(supabaseClientProvider);

      await client
          .from(SupabaseConstants.securityEventsTable)
          .update({
            'is_resolved': true,
            'resolved_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', eventId);

      await logAdminAction(
        client,
        ref.read(currentUserIdProvider),
        'security_event_dismissed',
        details: {'message': 'Event $eventId resolved'},
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
      ref.invalidate(adminSecurityEventsProvider);
      ref.invalidate(adminSystemAlertsProvider);
    } catch (e, st) {
      AppLogger.error('AdminActions.dismissSecurityEvent', e, st);
      state = state.copyWith(
        isLoading: false,
        error: 'admin.action_error'.tr(),
      );
    }
  }

  /// Clear old audit logs before a given date.
  Future<void> clearAuditLogs({DateTime? before}) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(ref);
      final client = ref.read(supabaseClientProvider);
      final cutoff =
          before ?? DateTime.now().subtract(const Duration(days: 90));

      await client
          .from(SupabaseConstants.adminLogsTable)
          .delete()
          .lt('created_at', cutoff.toUtc().toIso8601String());

      await logAdminAction(
        client,
        ref.read(currentUserIdProvider),
        'audit_logs_cleared',
        details: {'message': 'Logs before ${cutoff.toIso8601String()} cleared'},
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('AdminActions.clearAuditLogs', e, st);
      state = state.copyWith(
        isLoading: false,
        error: 'admin.action_error'.tr(),
      );
    }
  }

  // ── Maintenance Operations ───────────────────────────

  /// Clean soft-deleted records older than [days] days from all soft-deletable tables.
  Future<void> cleanSoftDeletedRecords(int days) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(ref);
      final client = ref.read(supabaseClientProvider);
      final cutoff = DateTime.now().subtract(Duration(days: days));

      var totalCleaned = 0;
      for (final table in AdminConstants.softDeletableTables) {
        try {
          final result = await client
              .from(table)
              .delete()
              .eq('is_deleted', true)
              .lt('updated_at', cutoff.toUtc().toIso8601String())
              .select('id');
          totalCleaned += (result as List).length;
        } catch (e) {
          AppLogger.warning('cleanSoftDeleted: Failed for $table: $e');
        }
      }

      await logAdminAction(
        client,
        ref.read(currentUserIdProvider),
        'soft_delete_cleanup',
        details: {'days': days, 'cleaned': totalCleaned},
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        successMessage: 'admin.soft_deleted_cleaned'.tr(),
      );
    } catch (e, st) {
      AppLogger.error('AdminActions.cleanSoftDeletedRecords', e, st);
      state = state.copyWith(
        isLoading: false,
        error: 'admin.action_error'.tr(),
      );
    }
  }

  /// Reset stuck sync metadata records (error status older than 24h).
  Future<void> resetStuckSyncRecords() async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(ref);
      final client = ref.read(supabaseClientProvider);
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));

      await client
          .from(SupabaseConstants.syncMetadataTable)
          .delete()
          .eq('status', 'error')
          .lt('created_at', cutoff.toUtc().toIso8601String());

      await logAdminAction(
        client,
        ref.read(currentUserIdProvider),
        'sync_stuck_reset',
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        successMessage: 'admin.stuck_reset'.tr(),
      );
    } catch (e, st) {
      AppLogger.error('AdminActions.resetStuckSyncRecords', e, st);
      state = state.copyWith(
        isLoading: false,
        error: 'admin.action_error'.tr(),
      );
    }
  }

  // ── Notification Operations ──────────────────────────

  /// Send an in-app notification and push notification to a single user.
  Future<void> sendNotification(String targetUserId, String title, String body) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(ref);
      final client = ref.read(supabaseClientProvider);

      await client.from(SupabaseConstants.notificationsTable).insert({
        'id': const Uuid().v4(),
        'user_id': targetUserId,
        'title': title,
        'body': body,
        'type': 'custom',
        'priority': 'normal',
        'read': false,
      });

      // Send push notification via FCM edge function
      final edgeClient = ref.read(edgeFunctionClientProvider);
      final pushResult = await edgeClient.sendPush(
        userIds: [targetUserId],
        title: title,
        body: body,
      );

      // Check both HTTP success and actual FCM delivery count
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
        ref.read(currentUserIdProvider),
        'notification_sent',
        targetUserId: targetUserId,
        details: {'title': title, 'push_delivered': !pushFailed},
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        successMessage: pushFailed
            ? 'admin.notification_sent_no_push'.tr()
            : 'admin.notification_sent'.tr(),
      );
    } catch (e, st) {
      AppLogger.error('AdminActions.sendNotification', e, st);
      state = state.copyWith(
        isLoading: false,
        error: 'admin.action_error'.tr(),
      );
    }
  }

  /// Send an in-app notification and push notification to multiple users.
  Future<void> sendBulkNotification(List<String> userIds, String title, String body) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(ref);
      final client = ref.read(supabaseClientProvider);

      final rows = userIds.map((uid) => {
        'id': const Uuid().v4(),
        'user_id': uid,
        'title': title,
        'body': body,
        'type': 'custom',
        'priority': 'normal',
        'read': false,
      }).toList();

      await client.from(SupabaseConstants.notificationsTable).insert(rows);

      // Send push notifications via FCM edge function
      final edgeClient = ref.read(edgeFunctionClientProvider);
      final pushResult = await edgeClient.sendPush(
        userIds: userIds,
        title: title,
        body: body,
      );

      // Check both HTTP success and actual FCM delivery count
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
        ref.read(currentUserIdProvider),
        'bulk_notification_sent',
        details: {
          'title': title,
          'count': userIds.length,
          'push_delivered': !pushFailed,
        },
      );

      final countStr = '${userIds.length}';
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        successMessage: pushFailed
            ? 'admin.notification_sent_bulk_no_push'.tr(args: [countStr])
            : 'admin.notification_sent_bulk'.tr(args: [countStr]),
      );
    } catch (e, st) {
      AppLogger.error('AdminActions.sendBulkNotification', e, st);
      state = state.copyWith(
        isLoading: false,
        error: 'admin.action_error'.tr(),
      );
    }
  }

  void reset() => state = const AdminActionState();
}

/// Admin actions provider.
final adminActionsProvider =
    NotifierProvider<AdminActionsNotifier, AdminActionState>(
      AdminActionsNotifier.new,
    );
