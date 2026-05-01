import 'dart:io';

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, SupabaseQueryBuilder, PostgrestException;
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';

/// Abstract base class for all Supabase remote data sources.
///
/// Provides common CRUD operations against a single Supabase table.
/// Subclasses must specify [tableName], [fromJson], and [toSupabaseJson].
abstract class BaseRemoteSource<T> {
  /// The Supabase client instance. Protected for subclass access.
  final SupabaseClient client;

  const BaseRemoteSource(this.client);

  /// The Supabase table name (e.g. 'birds').
  String get tableName;

  /// Deserializes a JSON map into a domain model.
  T fromJson(Map<String, dynamic> json);

  /// Serializes a domain model into a Supabase-compatible JSON map.
  Map<String, dynamic> toSupabaseJson(T model);

  /// Threshold in milliseconds above which a query is considered slow.
  /// Set to 1000ms for mobile network tolerance (cellular latency baseline).
  static const _slowQueryThresholdMs = 1000;

  /// Reference to the Supabase table.
  SupabaseQueryBuilder get table => client.from(tableName);

  /// Threshold in milliseconds above which a query is near the server
  /// statement_timeout (120s) and should be treated as critical.
  static const _nearTimeoutThresholdMs = 60000;

  /// Executes [query] and logs a warning when it exceeds [_slowQueryThresholdMs].
  /// Logs a critical error when approaching the server statement_timeout (120s).
  Future<R> _timed<R>(String operation, Future<R> Function() query) async {
    final sw = Stopwatch()..start();
    try {
      return await query();
    } finally {
      sw.stop();
      final elapsed = sw.elapsedMilliseconds;
      if (elapsed > _nearTimeoutThresholdMs) {
        AppLogger.error(
          '[$tableName] Near-timeout query: $operation took ${elapsed}ms '
          '(server limit: 120s)',
        );
      } else if (elapsed > _slowQueryThresholdMs) {
        AppLogger.warning(
          '[$tableName] Slow query: $operation took ${elapsed}ms',
        );
      }
    }
  }

  /// Fetches all non-deleted records for a user.
  Future<List<T>> fetchAll(String userId) async {
    try {
      final response = await _timed(
        'fetchAll',
        () => table
            .select()
            .eq(SupabaseConstants.colUserId, userId)
            .eq(SupabaseConstants.colIsDeleted, false)
            .order(SupabaseConstants.colCreatedAt),
      );
      return response.map((json) => fromJson(json)).toList();
    } catch (e, st) {
      throw handleError(e, st);
    }
  }

  /// Fetches a single record by id, scoped to the user for security.
  Future<T?> fetchById(String id, {required String userId}) async {
    try {
      final response = await _timed(
        'fetchById',
        () => table
            .select()
            .eq('id', id)
            .eq(SupabaseConstants.colUserId, userId)
            .maybeSingle(),
      );
      return response != null ? fromJson(response) : null;
    } catch (e, st) {
      throw handleError(e, st);
    }
  }

  /// Maximum records per incremental pull to prevent memory exhaustion.
  static const _maxIncrementalPullSize = 5000;

  /// Maximum pagination iterations to prevent infinite loops.
  static const _maxPullIterations = 20;

  /// Fetches records updated since [since] for a user.
  ///
  /// Paginates automatically when results exceed [_maxIncrementalPullSize]
  /// (5000 records per batch). Uses deterministic keyset pagination on
  /// `updated_at` and `id` to fetch all changes since the last sync, up to
  /// [_maxPullIterations] batches (100k records total) as a safety guard.
  ///
  /// Note: `is_deleted` filter is intentionally omitted so that cross-device
  /// soft-deletes propagate during incremental sync. The [since] timestamp
  /// limits results to records changed after the last successful pull, so
  /// deleted records are only fetched once — when their `is_deleted` flag
  /// changes and `updated_at` advances. Full reconciliation (null [since])
  /// uses [fetchAll] which filters `is_deleted = false`, keeping that path
  /// fast even for users with many historical deletions.
  Future<List<T>> fetchUpdatedSince(String userId, DateTime since) async {
    final allResults = <T>[];
    var cursorUpdatedAt = since.toIso8601String();
    String? cursorId;

    for (var i = 0; i < _maxPullIterations; i++) {
      try {
        var query = table.select().eq(SupabaseConstants.colUserId, userId);

        if (cursorId == null) {
          query = query.gt(SupabaseConstants.colUpdatedAt, cursorUpdatedAt);
        } else {
          query = query.or(
            '${SupabaseConstants.colUpdatedAt}.gt.$cursorUpdatedAt,'
            'and(${SupabaseConstants.colUpdatedAt}.eq.$cursorUpdatedAt,'
            '${SupabaseConstants.colId}.gt.$cursorId)',
          );
        }

        final batch = await _timed(
          'fetchUpdatedSince${i > 0 ? '(page ${i + 1})' : ''}',
          () => query
              .order(SupabaseConstants.colUpdatedAt)
              .order(SupabaseConstants.colId)
              .limit(_maxIncrementalPullSize),
        );
        final models = batch.map((json) => fromJson(json)).toList();
        allResults.addAll(models);

        if (batch.length < _maxIncrementalPullSize) break;

        // Advance the compound cursor to the last record in the sorted page.
        final lastUpdatedAt =
            batch.last[SupabaseConstants.colUpdatedAt] as String;
        final lastId = batch.last[SupabaseConstants.colId] as String?;
        if (lastId == null) break;
        cursorUpdatedAt = lastUpdatedAt;
        cursorId = lastId;

        if (i > 0) {
          AppLogger.info(
            '[$tableName] Pull pagination: page ${i + 1}, ${allResults.length} records so far',
          );
        }
      } catch (e, st) {
        throw handleError(e, st);
      }
    }

    if (allResults.length >= _maxPullIterations * _maxIncrementalPullSize) {
      AppLogger.warning(
        '[$tableName] Pull pagination hit max iterations '
        '($_maxPullIterations). ${allResults.length} records fetched. '
        'Consider full reconciliation.',
      );
    }

    return allResults;
  }

  /// Upserts a single record to the remote table.
  Future<void> upsert(T model) async {
    try {
      await _timed('upsert', () => table.upsert(toSupabaseJson(model)));
    } catch (e, st) {
      throw handleError(e, st);
    }
  }

  /// Upserts multiple records to the remote table.
  Future<void> upsertAll(List<T> models) async {
    if (models.isEmpty) return;
    try {
      await _timed(
        'upsertAll(${models.length})',
        () => table.upsert(models.map(toSupabaseJson).toList()),
      );
    } catch (e, st) {
      throw handleError(e, st);
    }
  }

  /// Fetches all non-deleted records for a user using cursor-based pagination.
  ///
  /// Useful for large datasets (500+ records) to avoid response size limits.
  /// Uses `created_at` cursor instead of OFFSET for stable performance at scale.
  Future<List<T>> fetchAllPaginated(String userId, {int pageSize = 500}) async {
    try {
      final results = <T>[];
      String? cursor;
      var page = 0;
      while (true) {
        var query = table
            .select()
            .eq(SupabaseConstants.colUserId, userId)
            .eq(SupabaseConstants.colIsDeleted, false);
        if (cursor != null) {
          query = query.gt(SupabaseConstants.colCreatedAt, cursor);
        }
        final response = await _timed(
          'fetchAllPaginated(page=$page)',
          () => query.order(SupabaseConstants.colCreatedAt).limit(pageSize),
        );
        if (response.isEmpty) break;
        results.addAll(response.map((json) => fromJson(json)));
        if (response.length < pageSize) break;
        cursor = response.last[SupabaseConstants.colCreatedAt] as String?;
        if (cursor == null) break;
        page++;
      }
      return results;
    } catch (e, st) {
      throw handleError(e, st);
    }
  }

  /// Permanently deletes a record by id from the remote table.
  Future<void> deleteById(String id, {required String userId}) async {
    try {
      await _timed('deleteById', () async {
        await table
            .delete()
            .eq('id', id)
            .eq(SupabaseConstants.colUserId, userId);
      });
    } catch (e, st) {
      throw handleError(e, st);
    }
  }

  /// Sanitizes database error messages to prevent leaking internal details
  /// (SQL syntax, RLS policy names, table structure) to the UI layer.
  ///
  /// Pure function — no side effects. Callers are responsible for adding
  /// Sentry breadcrumbs when sanitization occurs.
  static String _sanitizeErrorMessage(String message) {
    // PostgreSQL-specific patterns that reveal internal schema details.
    // Use precise patterns (e.g. trailing quote in 'relation "') to avoid
    // false positives on generic words like "column" or "relation".
    // 'PGRES' targets libpq internal error codes (e.g. PGRES_FATAL_ERROR).
    const sensitivePatterns = [
      'syntax error',
      'violates row-level security',
      'violates check constraint',
      'violates foreign key constraint',
      'violates unique constraint',
      'violates not-null constraint',
      'relation "',
      'column "',
      'permission denied for',
      'PGRES', // libpq internal error codes (e.g. PGRES_FATAL_ERROR)
      'pg_catalog',
    ];
    final lower = message.toLowerCase();
    for (final pattern in sensitivePatterns) {
      if (lower.contains(pattern.toLowerCase())) {
        return 'Database operation failed';
      }
    }
    return message;
  }

  /// Converts Supabase/network errors into [AppException] subtypes.
  ///
  /// Error messages are sanitized before being wrapped in [AppException]
  /// to prevent database internals from leaking to the UI layer.
  /// The original error is preserved in [AppException.originalError] for
  /// logging and Sentry reporting.
  AppException handleError(dynamic error, StackTrace stackTrace) =>
      handleErrorForTag(tableName, error, stackTrace);

  /// Static variant of [handleError] for use by remote sources that don't
  /// extend [BaseRemoteSource] (e.g. community, messaging).
  static AppException handleErrorForTag(
    String tag,
    dynamic error,
    StackTrace stackTrace,
  ) {
    AppLogger.error('[$tag] Remote error', error, stackTrace);

    if (error is PostgrestException) {
      final sanitized = _sanitizeErrorMessage(error.message);
      if (sanitized != error.message) {
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Sanitized DB error',
            category: 'security',
            level: SentryLevel.warning,
          ),
        );
      }

      final code = error.code ?? '';

      // Auth/permission errors
      if (code == 'PGRST301' || code == '42501') {
        return AuthException(sanitized, code: code, originalError: error);
      }

      // Constraint violations → validation errors
      if (code.startsWith('23')) {
        return ValidationException(sanitized, code: code, originalError: error);
      }

      return NetworkException(sanitized, code: code, originalError: error);
    }

    if (error is SocketException) {
      return const NetworkException('No internet connection');
    }

    if (error is AppException) return error;

    final errorStr = error.toString();
    final sanitized = _sanitizeErrorMessage(errorStr);
    if (sanitized != errorStr) {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Sanitized DB error',
          category: 'security',
          level: SentryLevel.warning,
        ),
      );
    }
    return NetworkException(sanitized, originalError: error);
  }
}

/// Variant of [BaseRemoteSource] for tables without `is_deleted` column.
///
/// Used by Incubation and GrowthMeasurement which lack soft-delete support.
abstract class BaseRemoteSourceNoSoftDelete<T> extends BaseRemoteSource<T> {
  const BaseRemoteSourceNoSoftDelete(super.client);

  @override
  Future<List<T>> fetchAll(String userId) async {
    try {
      final response = await _timed(
        'fetchAll',
        () => table
            .select()
            .eq(SupabaseConstants.colUserId, userId)
            .order(SupabaseConstants.colCreatedAt),
      );
      return response.map((json) => fromJson(json)).toList();
    } catch (e, st) {
      throw handleError(e, st);
    }
  }

  /// No `is_deleted` column on these tables, so no soft-delete filtering
  /// applies. The parent [fetchUpdatedSince] already omits `is_deleted`
  /// filtering, so the inherited paginated implementation works as-is.
}
