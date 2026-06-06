import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../constants/admin_constants.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import 'admin_auth_utils.dart';
import 'admin_data_providers.dart';
import 'admin_user_manager.dart';

/// Export format for bulk user export.
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

/// Manages admin bulk operations (toggle, premium, export, delete).
///
/// Delegates state updates to the parent [AdminActionsNotifier] via callbacks.
class AdminBulkManager {
  final Ref _ref;
  final AdminUserManager _userManager;
  final void Function({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? successMessage,
  })
  _updateState;

  AdminBulkManager(this._ref, this._userManager, this._updateState);

  bool _validateBulkSize(Set<String> userIds) {
    if (userIds.length <= AdminConstants.maxBulkOperationSize) return true;

    _updateState(
      isLoading: false,
      error: 'admin.bulk_limit_exceeded'.tr(
        args: [AdminConstants.maxBulkOperationSize.toString()],
      ),
      isSuccess: false,
    );
    return false;
  }

  Future<({int succeeded, int skipped})> bulkToggleActive(
    Set<String> userIds, {
    required bool activate,
  }) async {
    var succeeded = 0;
    var skipped = 0;
    if (!_validateBulkSize(userIds)) return (succeeded: 0, skipped: 0);
    _updateState(isLoading: true, error: null, isSuccess: false);

    try {
      for (final userId in userIds) {
        final result = await _userManager.toggleUserActive(userId, activate);
        switch (result) {
          case AdminUserOperationResult.success:
            succeeded++;
          case AdminUserOperationResult.protected:
            skipped++;
          case AdminUserOperationResult.failed:
            throw StateError(
              'bulk toggle failed for user ${AppLogger.obfuscate(userId)}',
            );
        }
      }
      _updateState(isLoading: false, isSuccess: true);
      _ref.invalidate(adminUsersProvider);
      return (succeeded: succeeded, skipped: skipped);
    } catch (e, st) {
      AppLogger.error('AdminBulkManager.bulkToggleActive', e, st);
      Sentry.captureException(e, stackTrace: st);
      _updateState(isLoading: false, error: 'admin.action_error'.tr());
      return (succeeded: succeeded, skipped: skipped);
    }
  }

  Future<({int succeeded, int skipped})> bulkGrantPremium(
    Set<String> userIds,
  ) async {
    var succeeded = 0;
    var skipped = 0;
    if (!_validateBulkSize(userIds)) return (succeeded: 0, skipped: 0);
    _updateState(isLoading: true, error: null, isSuccess: false);

    try {
      for (final userId in userIds) {
        final result = await _userManager.grantPremium(userId);
        switch (result) {
          case AdminUserOperationResult.success:
            succeeded++;
          case AdminUserOperationResult.protected:
            skipped++;
          case AdminUserOperationResult.failed:
            throw StateError(
              'bulk premium grant failed for user ${AppLogger.obfuscate(userId)}',
            );
        }
      }
      _updateState(isLoading: false, isSuccess: true);
      _ref.invalidate(adminUsersProvider);
      return (succeeded: succeeded, skipped: skipped);
    } catch (e, st) {
      AppLogger.error('AdminBulkManager.bulkGrantPremium', e, st);
      Sentry.captureException(e, stackTrace: st);
      _updateState(isLoading: false, error: 'admin.action_error'.tr());
      return (succeeded: succeeded, skipped: skipped);
    }
  }

  Future<({int succeeded, int skipped})> bulkRevokePremium(
    Set<String> userIds,
  ) async {
    var succeeded = 0;
    var skipped = 0;
    if (!_validateBulkSize(userIds)) return (succeeded: 0, skipped: 0);
    _updateState(isLoading: true, error: null, isSuccess: false);

    try {
      for (final userId in userIds) {
        final result = await _userManager.revokePremium(userId);
        switch (result) {
          case AdminUserOperationResult.success:
            succeeded++;
          case AdminUserOperationResult.protected:
            skipped++;
          case AdminUserOperationResult.failed:
            throw StateError(
              'bulk premium revoke failed for user ${AppLogger.obfuscate(userId)}',
            );
        }
      }
      _updateState(isLoading: false, isSuccess: true);
      _ref.invalidate(adminUsersProvider);
      return (succeeded: succeeded, skipped: skipped);
    } catch (e, st) {
      AppLogger.error('AdminBulkManager.bulkRevokePremium', e, st);
      Sentry.captureException(e, stackTrace: st);
      _updateState(isLoading: false, error: 'admin.action_error'.tr());
      return (succeeded: succeeded, skipped: skipped);
    }
  }

  Future<String> bulkExport(
    Set<String> userIds, {
    ExportFormat format = ExportFormat.json,
  }) async {
    if (!_validateBulkSize(userIds)) return '';
    _updateState(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(_ref);
      final client = _ref.read(supabaseClientProvider);
      final rows = await client
          .from(SupabaseConstants.profilesTable)
          .select('id, email, full_name, avatar_url, created_at, is_active')
          .inFilter('id', userIds.toList());
      _updateState(isLoading: false, isSuccess: true);
      final data = List<Map<String, dynamic>>.from(rows);
      return format == ExportFormat.csv ? _toCsv(data) : jsonEncode(data);
    } catch (e, st) {
      AppLogger.error('AdminBulkManager.bulkExport', e, st);
      Sentry.captureException(e, stackTrace: st);
      _updateState(isLoading: false, error: 'admin.action_error'.tr());
      return '';
    }
  }

  Future<({int succeeded, int skipped})> bulkDeleteUserData(
    Set<String> userIds,
  ) async {
    var succeeded = 0;
    var skipped = 0;
    if (!_validateBulkSize(userIds)) return (succeeded: 0, skipped: 0);
    _updateState(isLoading: true, error: null, isSuccess: false);

    try {
      await requireFounder(_ref);
      final client = _ref.read(supabaseClientProvider);

      AppLogger.info(
        '[admin] bulkDeleteUserData called for ${userIds.length} users',
      );

      const deletionOrder = AdminConstants.userDataDeletionOrder;

      for (final userId in userIds) {
        try {
          var userHadDeleteError = false;
          for (final table in deletionOrder) {
            try {
              await client.from(table).delete().eq('user_id', userId);
            } catch (e, st) {
              userHadDeleteError = true;
              AppLogger.warning(
                'bulkDeleteUserData: table $table for ${AppLogger.obfuscate(userId)}: $e\n$st',
              );
              Sentry.addBreadcrumb(
                Breadcrumb(
                  message:
                      'bulkDeleteUserData table delete failed for ${AppLogger.obfuscate(userId)}',
                  category: 'admin.bulk_delete',
                  level: SentryLevel.warning,
                  data: {'table': table, 'error': e.toString()},
                ),
              );
            }
          }
          if (userHadDeleteError) {
            skipped++;
          } else {
            succeeded++;
          }
        } catch (e, st) {
          AppLogger.warning(
            'admin: bulkDeleteUserData failed for ${AppLogger.obfuscate(userId)}: $e\n$st',
          );
          skipped++;
        }
      }

      _updateState(isLoading: false, isSuccess: true);
      await logAdminAction(
        client,
        _ref.read(currentUserIdProvider),
        'bulk_user_data_deleted',
        details: {'user_count': userIds.length, 'succeeded': succeeded},
      );
      _ref.invalidate(adminUsersProvider);
      return (succeeded: succeeded, skipped: skipped);
    } catch (e, st) {
      AppLogger.error('AdminBulkManager.bulkDeleteUserData', e, st);
      Sentry.captureException(e, stackTrace: st);
      _updateState(isLoading: false, error: 'admin.action_error'.tr());
      return (succeeded: succeeded, skipped: skipped);
    }
  }
}
