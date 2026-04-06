import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_bulk_manager.dart';
import 'admin_database_manager.dart';
import 'admin_maintenance_manager.dart';
import 'admin_notification_manager.dart';
import 'admin_user_manager.dart';

export 'admin_bulk_manager.dart' show ExportFormat;

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

/// Notifier for admin actions.
///
/// Delegates to specialized managers:
/// - [AdminUserManager] — user activate/deactivate, premium
/// - [AdminDatabaseManager] — export, reset tables
/// - [AdminNotificationManager] — send single/bulk notifications + push
/// - [AdminBulkManager] — bulk user operations (toggle, premium, export, delete)
/// - [AdminMaintenanceManager] — security events, audit logs, soft-delete cleanup, sync reset
class AdminActionsNotifier extends Notifier<AdminActionState> {
  late final AdminUserManager _userManager;
  late final AdminDatabaseManager _databaseManager;
  late final AdminNotificationManager _notificationManager;
  late final AdminBulkManager _bulkManager;
  late final AdminMaintenanceManager _maintenanceManager;

  @override
  AdminActionState build() {
    _userManager = AdminUserManager(ref, _updateState);
    _databaseManager = AdminDatabaseManager(ref, _updateState);
    _notificationManager = AdminNotificationManager(ref, _updateState);
    _bulkManager = AdminBulkManager(ref, _userManager, _updateState);
    _maintenanceManager = AdminMaintenanceManager(ref, _updateState);
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

  Future<void> toggleUserActive(String targetUserId, bool isActive) =>
      _userManager.toggleUserActive(targetUserId, isActive);

  Future<void> grantPremium(String targetUserId) =>
      _userManager.grantPremium(targetUserId);

  Future<void> revokePremium(String targetUserId) =>
      _userManager.revokePremium(targetUserId);

  // ── Database Operations (delegated) ──────────────────

  Future<String?> exportTable(String tableName) =>
      _databaseManager.exportTable(tableName);

  Future<String?> exportAllTables() => _databaseManager.exportAllTables();

  Future<bool> resetTable(String tableName) =>
      _databaseManager.resetTable(tableName);

  Future<bool> resetAllUserData() => _databaseManager.resetAllUserData();

  // ── Notification Operations (delegated) ──────────────

  Future<void> sendNotification(String targetUserId, String title, String body) =>
      _notificationManager.sendNotification(targetUserId, title, body);

  Future<void> sendBulkNotification(List<String> userIds, String title, String body) =>
      _notificationManager.sendBulkNotification(userIds, title, body);

  // ── Bulk Operations (delegated) ──────────────────────

  Future<({int succeeded, int skipped})> bulkToggleActive(
    Set<String> userIds, {
    required bool activate,
  }) => _bulkManager.bulkToggleActive(userIds, activate: activate);

  Future<({int succeeded, int skipped})> bulkGrantPremium(Set<String> userIds) =>
      _bulkManager.bulkGrantPremium(userIds);

  Future<({int succeeded, int skipped})> bulkRevokePremium(Set<String> userIds) =>
      _bulkManager.bulkRevokePremium(userIds);

  Future<String> bulkExport(
    Set<String> userIds, {
    ExportFormat format = ExportFormat.json,
  }) => _bulkManager.bulkExport(userIds, format: format);

  Future<({int succeeded, int skipped})> bulkDeleteUserData(Set<String> userIds) =>
      _bulkManager.bulkDeleteUserData(userIds);

  // ── Security & Audit (delegated) ─────────────────────

  Future<void> dismissSecurityEvent(String eventId) =>
      _maintenanceManager.dismissSecurityEvent(eventId);

  Future<void> clearAuditLogs({DateTime? before}) =>
      _maintenanceManager.clearAuditLogs(before: before);

  // ── Maintenance Operations (delegated) ──────────────

  Future<void> cleanSoftDeletedRecords(int days) =>
      _maintenanceManager.cleanSoftDeletedRecords(days);

  Future<void> resetStuckSyncRecords() =>
      _maintenanceManager.resetStuckSyncRecords();

  void reset() => state = const AdminActionState();
}

/// Admin actions provider.
final adminActionsProvider =
    NotifierProvider<AdminActionsNotifier, AdminActionState>(
      AdminActionsNotifier.new,
    );
