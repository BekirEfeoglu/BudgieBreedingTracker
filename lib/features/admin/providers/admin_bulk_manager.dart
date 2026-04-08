import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
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

  Future<({int succeeded, int skipped})> bulkToggleActive(
    Set<String> userIds, {
    required bool activate,
  }) async {
    var succeeded = 0;
    var skipped = 0;
    _updateState(isLoading: true, error: null, isSuccess: false);

    try {
      for (final userId in userIds) {
        try {
          await _userManager.toggleUserActive(userId, activate);
          succeeded++;
        } on ProtectedRoleError {
          skipped++;
        }
      }
      _updateState(isLoading: false, isSuccess: true);
      _ref.invalidate(adminUsersProvider);
      return (succeeded: succeeded, skipped: skipped);
    } catch (e) {
      _updateState(isLoading: false, error: e.toString());
      return (succeeded: succeeded, skipped: skipped);
    }
  }

  Future<({int succeeded, int skipped})> bulkGrantPremium(
    Set<String> userIds,
  ) async {
    var succeeded = 0;
    var skipped = 0;
    _updateState(isLoading: true, error: null, isSuccess: false);

    try {
      for (final userId in userIds) {
        try {
          await _userManager.grantPremium(userId);
          succeeded++;
        } on ProtectedRoleError {
          skipped++;
        }
      }
      _updateState(isLoading: false, isSuccess: true);
      _ref.invalidate(adminUsersProvider);
      return (succeeded: succeeded, skipped: skipped);
    } catch (e) {
      _updateState(isLoading: false, error: e.toString());
      return (succeeded: succeeded, skipped: skipped);
    }
  }

  Future<({int succeeded, int skipped})> bulkRevokePremium(
    Set<String> userIds,
  ) async {
    var succeeded = 0;
    var skipped = 0;
    _updateState(isLoading: true, error: null, isSuccess: false);

    try {
      for (final userId in userIds) {
        try {
          await _userManager.revokePremium(userId);
          succeeded++;
        } on ProtectedRoleError {
          skipped++;
        }
      }
      _updateState(isLoading: false, isSuccess: true);
      _ref.invalidate(adminUsersProvider);
      return (succeeded: succeeded, skipped: skipped);
    } catch (e) {
      _updateState(isLoading: false, error: e.toString());
      return (succeeded: succeeded, skipped: skipped);
    }
  }

  Future<String> bulkExport(
    Set<String> userIds, {
    ExportFormat format = ExportFormat.json,
  }) async {
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
    } catch (e) {
      _updateState(isLoading: false, error: e.toString());
      return '';
    }
  }

  Future<({int succeeded, int skipped})> bulkDeleteUserData(
    Set<String> userIds,
  ) async {
    var succeeded = 0;
    var skipped = 0;
    _updateState(isLoading: true, error: null, isSuccess: false);

    try {
      await requireAdmin(_ref);
      final client = _ref.read(supabaseClientProvider);

      AppLogger.info(
        '[admin] bulkDeleteUserData called for ${userIds.length} users',
      );

      const deletionOrder = [
        SupabaseConstants.eventRemindersTable,
        SupabaseConstants.growthMeasurementsTable,
        SupabaseConstants.healthRecordsTable,
        SupabaseConstants.photosTable,
        SupabaseConstants.eventsTable,
        SupabaseConstants.incubationsTable,
        SupabaseConstants.chicksTable,
        SupabaseConstants.eggsTable,
        SupabaseConstants.clutchesTable,
        SupabaseConstants.breedingPairsTable,
        SupabaseConstants.nestsTable,
        SupabaseConstants.notificationsTable,
        SupabaseConstants.notificationSettingsTable,
        SupabaseConstants.notificationSchedulesTable,
        SupabaseConstants.birdsTable,
      ];

      for (final userId in userIds) {
        try {
          for (final table in deletionOrder) {
            try {
              await client
                  .from(table)
                  .delete()
                  .eq('user_id', userId);
            } catch (_) {
              // Some tables may not have user_id column — skip silently.
            }
          }
          succeeded++;
        } catch (e) {
          AppLogger.warning(
            'admin: bulkDeleteUserData failed for $userId: $e',
          );
          skipped++;
        }
      }

      _updateState(isLoading: false, isSuccess: true);
      _ref.invalidate(adminUsersProvider);
      return (succeeded: succeeded, skipped: skipped);
    } catch (e) {
      _updateState(isLoading: false, error: e.toString());
      return (succeeded: succeeded, skipped: skipped);
    }
  }
}
