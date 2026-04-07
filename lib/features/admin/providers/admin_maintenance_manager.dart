import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import '../constants/admin_constants.dart';
import 'admin_auth_utils.dart';
import 'admin_dashboard_providers.dart';
import 'admin_filter_providers.dart';

/// Manages admin security/audit and maintenance operations.
///
/// Delegates state updates to the parent [AdminActionsNotifier] via callbacks.
class AdminMaintenanceManager {
  final Ref _ref;
  final void Function({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? successMessage,
  })
  _updateState;

  AdminMaintenanceManager(this._ref, this._updateState);

  /// Mark a security event as resolved.
  Future<void> dismissSecurityEvent(String eventId) async {
    _updateState(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(_ref);
      final client = _ref.read(supabaseClientProvider);

      await client
          .from(SupabaseConstants.securityEventsTable)
          .update({
            'is_resolved': true,
            'resolved_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', eventId);

      await logAdminAction(
        client,
        _ref.read(currentUserIdProvider),
        'security_event_dismissed',
        details: {'message': 'Event $eventId resolved'},
      );

      _updateState(isLoading: false, isSuccess: true);
      _ref.invalidate(adminSecurityEventsProvider);
      _ref.invalidate(adminSystemAlertsProvider);
    } catch (e, st) {
      AppLogger.error('AdminMaintenanceManager.dismissSecurityEvent', e, st);
      _updateState(isLoading: false, error: 'admin.action_error'.tr());
    }
  }

  /// Clear audit logs older than [before] (defaults to 90 days ago).
  ///
  /// Restricted to founder role only to prevent admins from
  /// covering their tracks by clearing audit trails.
  Future<void> clearAuditLogs({DateTime? before}) async {
    _updateState(isLoading: true, error: null, isSuccess: false);
    try {
      await requireFounder(_ref);
      final client = _ref.read(supabaseClientProvider);
      final cutoff = before ?? DateTime.now().subtract(const Duration(days: 90));

      await client
          .from(SupabaseConstants.adminLogsTable)
          .delete()
          .lt('created_at', cutoff.toUtc().toIso8601String());

      await logAdminAction(
        client,
        _ref.read(currentUserIdProvider),
        'audit_logs_cleared',
        details: {'message': 'Logs before ${cutoff.toIso8601String()} cleared'},
      );

      _updateState(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('AdminMaintenanceManager.clearAuditLogs', e, st);
      _updateState(isLoading: false, error: 'admin.action_error'.tr());
    }
  }

  /// Permanently delete soft-deleted records older than [days] days.
  Future<void> cleanSoftDeletedRecords(int days) async {
    _updateState(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(_ref);
      final client = _ref.read(supabaseClientProvider);
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
        _ref.read(currentUserIdProvider),
        'soft_delete_cleanup',
        details: {'days': days, 'cleaned': totalCleaned},
      );

      _updateState(
        isLoading: false,
        isSuccess: true,
        successMessage: 'admin.soft_deleted_cleaned'.tr(),
      );
    } catch (e, st) {
      AppLogger.error('AdminMaintenanceManager.cleanSoftDeletedRecords', e, st);
      _updateState(isLoading: false, error: 'admin.action_error'.tr());
    }
  }

  /// Reset sync metadata records stuck in error state for over 24 hours.
  Future<void> resetStuckSyncRecords() async {
    _updateState(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(_ref);
      final client = _ref.read(supabaseClientProvider);
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));

      await client
          .from(SupabaseConstants.syncMetadataTable)
          .delete()
          .eq('status', 'error')
          .lt('created_at', cutoff.toUtc().toIso8601String());

      await logAdminAction(
        client,
        _ref.read(currentUserIdProvider),
        'sync_stuck_reset',
      );

      _updateState(
        isLoading: false,
        isSuccess: true,
        successMessage: 'admin.stuck_reset'.tr(),
      );
    } catch (e, st) {
      AppLogger.error('AdminMaintenanceManager.resetStuckSyncRecords', e, st);
      _updateState(isLoading: false, error: 'admin.action_error'.tr());
    }
  }
}
