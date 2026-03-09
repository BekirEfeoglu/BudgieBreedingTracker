import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, SupabaseQueryBuilder, PostgrestException;
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

  /// Executes [query] and logs a warning when it exceeds [_slowQueryThresholdMs].
  Future<R> _timed<R>(String operation, Future<R> Function() query) async {
    final sw = Stopwatch()..start();
    try {
      return await query();
    } finally {
      sw.stop();
      if (sw.elapsedMilliseconds > _slowQueryThresholdMs) {
        AppLogger.warning(
          '[$tableName] Slow query: $operation took ${sw.elapsedMilliseconds}ms',
        );
      }
    }
  }

  /// Fetches all non-deleted records for a user.
  Future<List<T>> fetchAll(String userId) async {
    try {
      final response = await _timed('fetchAll', () => table
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('created_at'));
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
            .eq('user_id', userId)
            .maybeSingle(),
      );
      return response != null ? fromJson(response) : null;
    } catch (e, st) {
      throw handleError(e, st);
    }
  }

  /// Fetches records updated since [since] for a user.
  Future<List<T>> fetchUpdatedSince(
    String userId,
    DateTime since,
  ) async {
    try {
      final response = await _timed('fetchUpdatedSince', () => table
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .gte('updated_at', since.toIso8601String())
          .order('updated_at'));
      return response.map((json) => fromJson(json)).toList();
    } catch (e, st) {
      throw handleError(e, st);
    }
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
  Future<List<T>> fetchAllPaginated(
    String userId, {
    int pageSize = 500,
  }) async {
    try {
      final results = <T>[];
      String? cursor;
      var page = 0;
      while (true) {
        var query = table
            .select()
            .eq('user_id', userId)
            .eq('is_deleted', false);
        if (cursor != null) {
          query = query.gt('created_at', cursor);
        }
        final response = await _timed(
          'fetchAllPaginated(page=$page)',
          () => query.order('created_at').limit(pageSize),
        );
        if (response.isEmpty) break;
        results.addAll(response.map((json) => fromJson(json)));
        if (response.length < pageSize) break;
        cursor = response.last['created_at'] as String?;
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
        await table.delete().eq('id', id).eq('user_id', userId);
      });
    } catch (e, st) {
      throw handleError(e, st);
    }
  }

  /// Converts Supabase/network errors into [AppException] subtypes.
  AppException handleError(dynamic error, StackTrace stackTrace) {
    AppLogger.error('[$tableName] Remote error', error, stackTrace);

    if (error is PostgrestException) {
      return NetworkException(
        error.message,
        code: error.code,
        originalError: error,
      );
    }

    if (error is SocketException) {
      return const NetworkException('No internet connection');
    }

    if (error is AppException) return error;

    return NetworkException(
      error.toString(),
      originalError: error,
    );
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
      final response = await _timed('fetchAll', () => table
          .select()
          .eq('user_id', userId)
          .order('created_at'));
      return response.map((json) => fromJson(json)).toList();
    } catch (e, st) {
      throw handleError(e, st);
    }
  }

  @override
  Future<List<T>> fetchUpdatedSince(
    String userId,
    DateTime since,
  ) async {
    try {
      final response = await _timed('fetchUpdatedSince', () => table
          .select()
          .eq('user_id', userId)
          .gte('updated_at', since.toIso8601String())
          .order('updated_at'));
      return response.map((json) => fromJson(json)).toList();
    } catch (e, st) {
      throw handleError(e, st);
    }
  }
}
