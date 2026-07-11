import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/providers/auth.dart';
import '../constants/admin_constants.dart';
import 'admin_auth_utils.dart';

class ProtectedRoleError implements Exception {
  final String role;
  const ProtectedRoleError(this.role);

  @override
  String toString() => 'ProtectedRoleError: $role';
}

enum AdminUserOperationResult { success, protected, failed }

/// Manages admin user operations (activate/deactivate, premium grant/revoke).
///
/// Delegates state updates to the parent [AdminActionsNotifier] via callbacks.
class AdminUserManager {
  final Ref _ref;
  final void Function({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? successMessage,
  })
  _updateState;

  AdminUserManager(this._ref, this._updateState);

  /// Toggle user active/inactive status.
  Future<AdminUserOperationResult> toggleUserActive(
    String targetUserId,
    bool isActive,
  ) async {
    _updateState(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(_ref);
      final client = _ref.read(supabaseClientProvider);
      final role = await _fetchTargetUserRole(client, targetUserId);
      if (_isProtectedRole(role)) throw ProtectedRoleError(role!);

      await client.rpc(
        'admin_set_user_active',
        params: {'target_user_id': targetUserId, 'p_is_active': isActive},
      );

      _updateState(
        isLoading: false,
        isSuccess: true,
        successMessage: isActive
            ? 'admin.user_activated_success'.tr()
            : 'admin.user_deactivated_success'.tr(),
      );
      return AdminUserOperationResult.success;
    } on ProtectedRoleError {
      _updateState(isLoading: false, error: 'admin.protected_user_error'.tr());
      return AdminUserOperationResult.protected;
    } catch (e, st) {
      // Destructive admin op: report to Sentry (parity with admin_bulk_manager)
      // so a failed deactivate is observable, not just a breadcrumb.
      AppLogger.error('AdminUserManager.toggleUserActive', e, st);
      Sentry.captureException(e, stackTrace: st);
      _updateState(isLoading: false, error: 'admin.action_error'.tr());
      return AdminUserOperationResult.failed;
    }
  }

  /// Grant premium subscription to a user.
  Future<AdminUserOperationResult> grantPremium(String targetUserId) async {
    _updateState(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(_ref);
      final client = _ref.read(supabaseClientProvider);
      final role = await _fetchTargetUserRole(client, targetUserId);
      if (_isProtectedRole(role)) throw ProtectedRoleError(role!);

      await client.rpc(
        'admin_grant_premium',
        params: {'target_user_id': targetUserId},
      );

      _updateState(
        isLoading: false,
        isSuccess: true,
        successMessage: 'admin.premium_granted_success'.tr(),
      );
      return AdminUserOperationResult.success;
    } on ProtectedRoleError catch (e) {
      AppLogger.info(
        'AdminUserManager.grantPremium blocked for role: ${e.role}',
      );
      _updateState(
        isLoading: false,
        error: 'admin.protected_user_premium_error'.tr(),
      );
      return AdminUserOperationResult.protected;
    } on PostgrestException catch (e, st) {
      AppLogger.error('AdminUserManager.grantPremium Postgrest', e, st);
      if (_isProtectedRoleMutationError(e)) {
        _updateState(
          isLoading: false,
          error: 'admin.protected_user_premium_error'.tr(),
        );
      } else {
        // Genuine (non-protected-role) server failure — report to Sentry.
        Sentry.captureException(e, stackTrace: st);
        _updateState(isLoading: false, error: 'admin.action_error'.tr());
      }
      return AdminUserOperationResult.failed;
    } catch (e, st) {
      AppLogger.error('AdminUserManager.grantPremium', e, st);
      Sentry.captureException(e, stackTrace: st);
      _updateState(isLoading: false, error: 'admin.action_error'.tr());
      return AdminUserOperationResult.failed;
    }
  }

  /// Revoke premium subscription from a user.
  Future<AdminUserOperationResult> revokePremium(String targetUserId) async {
    _updateState(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(_ref);
      final client = _ref.read(supabaseClientProvider);
      final role = await _fetchTargetUserRole(client, targetUserId);
      if (_isProtectedRole(role)) throw ProtectedRoleError(role!);

      await client.rpc(
        'admin_revoke_premium',
        params: {'target_user_id': targetUserId},
      );

      _updateState(
        isLoading: false,
        isSuccess: true,
        successMessage: 'admin.premium_revoked_success'.tr(),
      );
      return AdminUserOperationResult.success;
    } on ProtectedRoleError catch (e) {
      AppLogger.info(
        'AdminUserManager.revokePremium blocked for role: ${e.role}',
      );
      _updateState(
        isLoading: false,
        error: 'admin.protected_user_premium_error'.tr(),
      );
      return AdminUserOperationResult.protected;
    } on PostgrestException catch (e, st) {
      AppLogger.error('AdminUserManager.revokePremium Postgrest', e, st);
      if (_isProtectedRoleMutationError(e)) {
        _updateState(
          isLoading: false,
          error: 'admin.protected_user_premium_error'.tr(),
        );
      } else {
        // Genuine (non-protected-role) server failure — report to Sentry.
        Sentry.captureException(e, stackTrace: st);
        _updateState(isLoading: false, error: 'admin.action_error'.tr());
      }
      return AdminUserOperationResult.failed;
    } catch (e, st) {
      AppLogger.error('AdminUserManager.revokePremium', e, st);
      Sentry.captureException(e, stackTrace: st);
      _updateState(isLoading: false, error: 'admin.action_error'.tr());
      return AdminUserOperationResult.failed;
    }
  }

  /// Force logout a user from all devices.
  Future<AdminUserOperationResult> forceLogout(String targetUserId) async {
    _updateState(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(_ref);
      final client = _ref.read(supabaseClientProvider);
      final role = await _fetchTargetUserRole(client, targetUserId);
      if (_isProtectedRole(role)) throw ProtectedRoleError(role!);

      await client.rpc(
        'admin_force_logout',
        params: {'target_user_id': targetUserId},
      );

      _updateState(
        isLoading: false,
        isSuccess: true,
        successMessage: 'admin.force_logout_success'.tr(),
      );
      return AdminUserOperationResult.success;
    } on ProtectedRoleError catch (e) {
      AppLogger.info(
        'AdminUserManager.forceLogout blocked for role: ${e.role}',
      );
      _updateState(isLoading: false, error: 'admin.protected_user_error'.tr());
      return AdminUserOperationResult.protected;
    } catch (e, st) {
      AppLogger.error('AdminUserManager.forceLogout', e, st);
      Sentry.captureException(e, stackTrace: st);
      _updateState(isLoading: false, error: 'admin.action_error'.tr());
      return AdminUserOperationResult.failed;
    }
  }

  // ── Private helpers ──────────────────────────────────

  bool _isProtectedRole(String? role) {
    if (role == null) return false;
    final normalized = role.toLowerCase().trim();
    return normalized == AdminConstants.roleFounder ||
        normalized == AdminConstants.roleAdmin;
  }

  bool _isProtectedRoleMutationError(PostgrestException e) {
    final payload = '${e.message} ${e.details ?? ''} ${e.hint ?? ''}'
        .toLowerCase();
    return payload.contains('protected_role_premium_mutation') ||
        payload.contains('protected_role_admin_action');
  }

  Future<String?> _fetchTargetUserRole(
    SupabaseClient client,
    String targetUserId,
  ) async {
    final row = await client
        .from(SupabaseConstants.profilesTable)
        .select(SupabaseConstants.colRole)
        .eq(SupabaseConstants.colId, targetUserId)
        .maybeSingle();
    if (row == null) {
      throw Exception('admin.user_not_found'.tr());
    }
    return row[SupabaseConstants.colRole] as String?;
  }
}
