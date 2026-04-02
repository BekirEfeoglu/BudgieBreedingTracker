import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
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

  void reset() => state = const AdminActionState();
}

/// Admin actions provider.
final adminActionsProvider =
    NotifierProvider<AdminActionsNotifier, AdminActionState>(
      AdminActionsNotifier.new,
    );
