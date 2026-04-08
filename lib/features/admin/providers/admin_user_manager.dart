import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import 'admin_auth_utils.dart';

class ProtectedRoleError implements Exception {
  final String role;
  const ProtectedRoleError(this.role);

  @override
  String toString() => 'ProtectedRoleError: $role';
}

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
  Future<void> toggleUserActive(String targetUserId, bool isActive) async {
    _updateState(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(_ref);
      final client = _ref.read(supabaseClientProvider);
      final role = await _fetchTargetUserRole(client, targetUserId);
      if (_isProtectedRole(role)) throw ProtectedRoleError(role!);

      await client
          .from(SupabaseConstants.profilesTable)
          .update({'is_active': isActive})
          .eq('id', targetUserId);

      await logAdminAction(
        client,
        _ref.read(currentUserIdProvider),
        isActive ? 'user_activated' : 'user_deactivated',
        targetUserId: targetUserId,
        details: {'message': isActive ? 'User activated' : 'User deactivated'},
      );

      _updateState(
        isLoading: false,
        isSuccess: true,
        successMessage: isActive
            ? 'admin.user_activated_success'.tr()
            : 'admin.user_deactivated_success'.tr(),
      );
    } on ProtectedRoleError {
      _updateState(
        isLoading: false,
        error: 'admin.protected_user_error'.tr(),
      );
      rethrow;
    } catch (e, st) {
      AppLogger.error('AdminUserManager.toggleUserActive', e, st);
      _updateState(isLoading: false, error: 'admin.action_error'.tr());
    }
  }

  /// Grant premium subscription to a user.
  Future<void> grantPremium(String targetUserId) async {
    _updateState(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(_ref);
      final client = _ref.read(supabaseClientProvider);
      final now = DateTime.now().toUtc().toIso8601String();
      final role = await _fetchTargetUserRole(client, targetUserId);
      if (_isProtectedRole(role)) throw ProtectedRoleError(role!);

      await client
          .from(SupabaseConstants.profilesTable)
          .update({'is_premium': true, 'subscription_status': 'premium'})
          .eq('id', targetUserId);

      // Supplementary record: check existing then insert or update
      await _upsertSubscription(client, targetUserId, {
        'plan': 'premium',
        'status': 'active',
        'updated_at': now,
      });

      await logAdminAction(
        client,
        _ref.read(currentUserIdProvider),
        'premium_granted',
        targetUserId: targetUserId,
        details: {'message': 'Premium subscription granted'},
      );

      _updateState(
        isLoading: false,
        isSuccess: true,
        successMessage: 'admin.premium_granted_success'.tr(),
      );
    } on ProtectedRoleError catch (e) {
      AppLogger.info(
        'AdminUserManager.grantPremium blocked for role: ${e.role}',
      );
      _updateState(
        isLoading: false,
        error: 'admin.protected_user_premium_error'.tr(),
      );
      rethrow;
    } on PostgrestException catch (e, st) {
      AppLogger.error('AdminUserManager.grantPremium Postgrest', e, st);
      if (_isProtectedRoleMutationError(e)) {
        _updateState(
          isLoading: false,
          error: 'admin.protected_user_premium_error'.tr(),
        );
      } else {
        _updateState(isLoading: false, error: 'admin.action_error'.tr());
      }
    } catch (e, st) {
      AppLogger.error('AdminUserManager.grantPremium', e, st);
      _updateState(isLoading: false, error: 'admin.action_error'.tr());
    }
  }

  /// Revoke premium subscription from a user.
  Future<void> revokePremium(String targetUserId) async {
    _updateState(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(_ref);
      final client = _ref.read(supabaseClientProvider);
      final role = await _fetchTargetUserRole(client, targetUserId);
      if (_isProtectedRole(role)) throw ProtectedRoleError(role!);

      await client
          .from(SupabaseConstants.profilesTable)
          .update({'is_premium': false, 'subscription_status': 'free'})
          .eq('id', targetUserId);

      // Soft-revoke subscription record to preserve audit trail
      await client
          .from(SupabaseConstants.userSubscriptionsTable)
          .update({
            'status': 'revoked',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', targetUserId);

      await logAdminAction(
        client,
        _ref.read(currentUserIdProvider),
        'premium_revoked',
        targetUserId: targetUserId,
        details: {'message': 'Premium subscription revoked'},
      );

      _updateState(
        isLoading: false,
        isSuccess: true,
        successMessage: 'admin.premium_revoked_success'.tr(),
      );
    } on ProtectedRoleError catch (e) {
      AppLogger.info(
        'AdminUserManager.revokePremium blocked for role: ${e.role}',
      );
      _updateState(
        isLoading: false,
        error: 'admin.protected_user_premium_error'.tr(),
      );
      rethrow;
    } on PostgrestException catch (e, st) {
      AppLogger.error('AdminUserManager.revokePremium Postgrest', e, st);
      if (_isProtectedRoleMutationError(e)) {
        _updateState(
          isLoading: false,
          error: 'admin.protected_user_premium_error'.tr(),
        );
      } else {
        _updateState(isLoading: false, error: 'admin.action_error'.tr());
      }
    } catch (e, st) {
      AppLogger.error('AdminUserManager.revokePremium', e, st);
      _updateState(isLoading: false, error: 'admin.action_error'.tr());
    }
  }

  // ── Private helpers ──────────────────────────────────

  bool _isProtectedRole(String? role) {
    if (role == null) return false;
    final normalized = role.toLowerCase().trim();
    return normalized == 'founder' || normalized == 'admin';
  }

  bool _isProtectedRoleMutationError(PostgrestException e) {
    final payload = '${e.message} ${e.details ?? ''} ${e.hint ?? ''}'
        .toLowerCase();
    return payload.contains('protected_role_premium_mutation');
  }

  Future<String?> _fetchTargetUserRole(
    SupabaseClient client,
    String targetUserId,
  ) async {
    final row = await client
        .from(SupabaseConstants.profilesTable)
        .select('role')
        .eq('id', targetUserId)
        .maybeSingle();
    if (row == null) {
      throw Exception('admin.user_not_found'.tr());
    }
    return row['role'] as String?;
  }

  /// Atomic upsert for user_subscriptions using PostgREST's onConflict.
  /// Eliminates the read-then-write race condition of the previous
  /// select-then-insert/update pattern.
  Future<void> _upsertSubscription(
    SupabaseClient client,
    String targetUserId,
    Map<String, dynamic> data,
  ) async {
    await client.from(SupabaseConstants.userSubscriptionsTable).upsert(
      {
        ...data,
        'user_id': targetUserId,
      },
      onConflict: 'user_id',
    );
  }

}
