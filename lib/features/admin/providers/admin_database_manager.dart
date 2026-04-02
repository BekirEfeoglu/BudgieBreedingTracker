import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import '../constants/admin_constants.dart';
import 'admin_auth_utils.dart';

part 'admin_database_manager_reset.dart';

/// Manages admin database operations (export, reset).
///
/// Delegates state updates to the parent [AdminActionsNotifier] via callbacks.
class AdminDatabaseManager {
  final Ref _ref;
  final void Function({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? successMessage,
  })
  _updateState;

  AdminDatabaseManager(this._ref, this._updateState);

  /// Allowed table names for admin operations (whitelist).
  static const _allowedTables = {
    SupabaseConstants.birdsTable,
    SupabaseConstants.eggsTable,
    SupabaseConstants.chicksTable,
    SupabaseConstants.incubationsTable,
    SupabaseConstants.clutchesTable,
    SupabaseConstants.breedingPairsTable,
    SupabaseConstants.nestsTable,
    SupabaseConstants.healthRecordsTable,
    SupabaseConstants.growthMeasurementsTable,
    SupabaseConstants.eventsTable,
    SupabaseConstants.notificationsTable,
    SupabaseConstants.notificationSettingsTable,
    SupabaseConstants.eventRemindersTable,
    SupabaseConstants.notificationSchedulesTable,
    SupabaseConstants.profilesTable,
    SupabaseConstants.userPreferencesTable,
    SupabaseConstants.photosTable,
    SupabaseConstants.feedbackTable,
  };

  /// Export a single table's data as JSON string.
  /// Tries RPC first, falls back to client-side SELECT if RPC is unavailable.
  Future<String?> exportTable(String tableName) async {
    if (!_allowedTables.contains(tableName)) {
      _updateState(
        isLoading: false,
        error: 'admin.invalid_table_name'.tr(args: [tableName]),
      );
      return null;
    }
    _updateState(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(_ref);
      final client = _ref.read(supabaseClientProvider);

      dynamic result;
      try {
        result = await client.rpc(
          'admin_export_table',
          params: {'p_table_name': tableName},
        );
      } catch (rpcError) {
        // RPC not available — fall back to client-side SELECT
        AppLogger.error(
          'AdminDatabaseManager.exportTable RPC unavailable, using fallback',
          rpcError,
          StackTrace.current,
        );
        result = await _exportTableChunked(_ref, tableName);
      }

      final jsonStr = const JsonEncoder.withIndent('  ').convert(result);

      _updateState(
        isLoading: false,
        isSuccess: true,
        successMessage: 'admin.export_table_success'.tr(
          args: [tableName, _formatBytes(jsonStr.length)],
        ),
      );
      return jsonStr;
    } catch (e, st) {
      AppLogger.error('AdminDatabaseManager.exportTable', e, st);
      _updateState(isLoading: false, error: '${'admin.action_error'.tr()}: $e');
      return null;
    }
  }

  /// Export all tables' data as a single JSON string.
  /// Tries RPC first, falls back to exporting each allowed table individually.
  Future<String?> exportAllTables() async {
    _updateState(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(_ref);
      final client = _ref.read(supabaseClientProvider);

      dynamic result;
      try {
        result = await client.rpc('admin_export_all_tables');
      } catch (rpcError) {
        // RPC not available — fall back to exporting each table individually
        AppLogger.error(
          'AdminDatabaseManager.exportAllTables RPC unavailable, using fallback',
          rpcError,
          StackTrace.current,
        );
        final allData = <String, dynamic>{};
        for (final table in _allowedTables) {
          try {
            allData[table] = await _exportTableChunked(_ref, table);
          } catch (tableError) {
            AppLogger.error(
              'AdminDatabaseManager.exportAllTables fallback: $table',
              tableError,
              StackTrace.current,
            );
            allData[table] = <dynamic>[];
          }
        }
        result = allData;
      }

      final jsonStr = const JsonEncoder.withIndent('  ').convert(result);

      _updateState(
        isLoading: false,
        isSuccess: true,
        successMessage: 'admin.export_all_success'.tr(
          args: [_formatBytes(jsonStr.length)],
        ),
      );
      return jsonStr;
    } catch (e, st) {
      AppLogger.error('AdminDatabaseManager.exportAllTables', e, st);
      _updateState(isLoading: false, error: '${'admin.action_error'.tr()}: $e');
      return null;
    }
  }

  /// Reset (truncate) a single table.
  /// Tries RPC first, falls back to client-side DELETE if RPC is unavailable.
  Future<bool> resetTable(String tableName) async {
    if (!_allowedTables.contains(tableName)) {
      _updateState(
        isLoading: false,
        error: 'admin.invalid_table_name'.tr(args: [tableName]),
      );
      return false;
    }
    _updateState(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(_ref);
      final client = _ref.read(supabaseClientProvider);

      int rowsDeleted = 0;
      try {
        final result = await client.rpc(
          'admin_reset_table',
          params: {'p_table_name': tableName},
        );
        if (result is Map<String, dynamic>) {
          rowsDeleted = (result['rows_deleted'] as num?)?.toInt() ?? 0;
        }
      } catch (rpcError) {
        AppLogger.error(
          'AdminDatabaseManager.resetTable RPC unavailable, using fallback',
          rpcError,
          StackTrace.current,
        );
        Sentry.captureMessage(
          'Admin resetTable fallback: $tableName',
          level: SentryLevel.warning,
        );
        final countBefore = await client.from(tableName).count();
        await client.from(tableName).delete().not('id', 'is', null);
        rowsDeleted = countBefore;
      }

      _updateState(
        isLoading: false,
        isSuccess: true,
        successMessage: 'admin.reset_table_success'.tr(
          args: [tableName, rowsDeleted.toString()],
        ),
      );
      return true;
    } catch (e, st) {
      AppLogger.error('AdminDatabaseManager.resetTable', e, st);
      _updateState(isLoading: false, error: '${'admin.action_error'.tr()}: $e');
      return false;
    }
  }

  /// Reset all user data tables (protected system tables are preserved).
  /// Tries RPC first, falls back to client-side DELETE in FK-safe order.
  Future<bool> resetAllUserData() async {
    _updateState(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(_ref);
      final client = _ref.read(supabaseClientProvider);

      int totalDeleted = 0;
      try {
        final result = await client.rpc('admin_reset_all_user_data');
        if (result is Map<String, dynamic>) {
          totalDeleted = (result['total_rows_deleted'] as num?)?.toInt() ?? 0;
        }
      } catch (rpcError) {
        AppLogger.error(
          'AdminDatabaseManager.resetAllUserData RPC unavailable, using fallback',
          rpcError,
          StackTrace.current,
        );
        Sentry.captureMessage(
          'Admin resetAllUserData fallback triggered',
          level: SentryLevel.warning,
        );
        AppLogger.warning(
          'admin: resetAllUserData fallback path — no transaction guarantee, '
          'partial deletes are possible if interrupted',
        );
        for (final table in _deletionOrder) {
          try {
            final count = await client.from(table).count();
            if (count > 0) {
              await client.from(table).delete().not('id', 'is', null);
              totalDeleted += count;
            }
          } catch (tableError) {
            AppLogger.error(
              'AdminDatabaseManager.resetAllUserData fallback: $table',
              tableError,
              StackTrace.current,
            );
          }
        }
      }

      _updateState(
        isLoading: false,
        isSuccess: true,
        successMessage: 'admin.reset_all_success'.tr(
          args: [totalDeleted.toString()],
        ),
      );
      return true;
    } catch (e, st) {
      AppLogger.error('AdminDatabaseManager.resetAllUserData', e, st);
      _updateState(isLoading: false, error: '${'admin.action_error'.tr()}: $e');
      return false;
    }
  }
}
