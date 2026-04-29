import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../storage/storage_utils.dart';

class MarketplaceListingRemoteSource {
  final SupabaseClient _client;

  MarketplaceListingRemoteSource(this._client);

  static const _selectColumns =
      'id, user_id, listing_type, title, description, price, currency, '
      'bird_id, species, mutation, gender, age, image_urls, city, status, '
      'view_count, message_count, is_verified_breeder, is_deleted, '
      'needs_review, username, avatar_url, created_at, updated_at';
  static const _maxMarketplaceImages = 3;
  static const _allowedImageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'heic',
  };

  static String _sanitizePathComponent(String value) {
    if (!RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(value)) {
      throw ArgumentError('Invalid path component');
    }
    return value;
  }

  Future<List<Map<String, dynamic>>> fetchListings({
    int limit = 20,
    DateTime? before,
    String? city,
    String? listingType,
    String? gender,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      // Start with a FilterBuilder so all filters can be chained before limit()
      var query = _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .select(_selectColumns)
          .eq(SupabaseConstants.colIsDeleted, false)
          .eq(SupabaseConstants.colStatus, 'active');

      if (before != null) {
        query = query.lt(
          SupabaseConstants.colCreatedAt,
          before.toIso8601String(),
        );
      }
      if (city != null && city.isNotEmpty) {
        query = query.eq(SupabaseConstants.colCity, city);
      }
      if (listingType != null && listingType.isNotEmpty) {
        query = query.eq(SupabaseConstants.colListingType, listingType);
      }
      if (gender != null && gender.isNotEmpty) {
        query = query.eq(SupabaseConstants.colGender, gender);
      }
      if (minPrice != null) {
        query = query.gte(SupabaseConstants.colPrice, minPrice);
      }
      if (maxPrice != null) {
        query = query.lte(SupabaseConstants.colPrice, maxPrice);
      }

      final response = await query
          .order(SupabaseConstants.colCreatedAt, ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchById(
    String id, {
    String? currentUserId,
  }) async {
    try {
      final response = await _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .select(_selectColumns)
          .eq(SupabaseConstants.colId, id)
          .eq(SupabaseConstants.colIsDeleted, false)
          .maybeSingle();

      if (response == null) return null;
      final isActive = response[SupabaseConstants.colStatus] == 'active';
      final isOwner =
          currentUserId != null &&
          response[SupabaseConstants.colUserId] == currentUserId;
      if (!isActive && !isOwner) return null;

      return response;
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  /// Batch-fetches listings by id. Preserves caller's order regardless of
  /// how the server returns rows. Returns an empty list for [ids] empty.
  Future<List<Map<String, dynamic>>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final response = await _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .select(_selectColumns)
          .inFilter(SupabaseConstants.colId, ids)
          .eq(SupabaseConstants.colIsDeleted, false)
          .eq(SupabaseConstants.colStatus, 'active');
      final rows = List<Map<String, dynamic>>.from(response);
      final byId = {
        for (final row in rows) row[SupabaseConstants.colId] as String: row,
      };
      return [
        for (final id in ids)
          if (byId[id] != null) byId[id]!,
      ];
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchByUser(String userId) async {
    try {
      final response = await _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .select(_selectColumns)
          .eq(SupabaseConstants.colUserId, userId)
          .eq(SupabaseConstants.colIsDeleted, false)
          .order(SupabaseConstants.colCreatedAt, ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> insert(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .insert(data)
          .select(_selectColumns)
          .single();
      return response;
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data, {
    required String userId,
  }) async {
    try {
      final response = await _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .update(data)
          .eq(SupabaseConstants.colId, id)
          .eq(SupabaseConstants.colUserId, userId)
          .select(_selectColumns)
          .single();
      return response;
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<void> softDelete(String id, {required String userId}) async {
    try {
      await _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .update({SupabaseConstants.colIsDeleted: true})
          .eq(SupabaseConstants.colId, id)
          .eq(SupabaseConstants.colUserId, userId);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<void> updateStatus(
    String id,
    String status, {
    required String userId,
  }) async {
    try {
      await _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .update({SupabaseConstants.colStatus: status})
          .eq(SupabaseConstants.colId, id)
          .eq(SupabaseConstants.colUserId, userId);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<void> incrementViewCount(String id) async {
    try {
      // Use a simple select+update pattern (no RPC function required)
      final current = await _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .select('view_count')
          .eq(SupabaseConstants.colId, id)
          .maybeSingle();
      if (current != null) {
        final newCount = (current['view_count'] as int? ?? 0) + 1;
        await _client
            .from(SupabaseConstants.marketplaceListingsTable)
            .update({'view_count': newCount})
            .eq(SupabaseConstants.colId, id);
      }
    } catch (e) {
      AppLogger.warning('View count increment failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> search(
    String query, {
    int limit = 20,
  }) async {
    try {
      final sanitized = query
          .replaceAll(RegExp(r'[\x00-\x1f]'), '')
          .replaceAll('\\', '\\\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_')
          .replaceAll(',', '')
          .replaceAll('.', '')
          .replaceAll('(', '')
          .replaceAll(')', '')
          .replaceAll("'", '')
          .replaceAll('"', '')
          .replaceAll('`', '')
          .replaceAll(';', '')
          .trim();
      if (sanitized.isEmpty) return [];

      final response = await _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .select(_selectColumns)
          .eq(SupabaseConstants.colIsDeleted, false)
          .eq(SupabaseConstants.colStatus, 'active')
          .or('title.ilike.%$sanitized%,description.ilike.%$sanitized%')
          .order(SupabaseConstants.colCreatedAt, ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  /// Uploads listing images to Supabase Storage and returns public URLs.
  ///
  /// Images stored under marketplace-images/{userId}/{listingId}/ path.
  Future<List<String>> uploadImages({
    required String userId,
    required String listingId,
    required List<String> localPaths,
  }) async {
    _sanitizePathComponent(userId);
    _sanitizePathComponent(listingId);
    if (localPaths.length > _maxMarketplaceImages) {
      throw ArgumentError('Too many marketplace images');
    }

    final urls = <String>[];
    for (var i = 0; i < localPaths.length; i++) {
      try {
        final file = File(localPaths[i]);
        final ext = StorageUtils.safeExtension(file.path);
        if (ext == null || !_allowedImageExtensions.contains(ext)) {
          throw const StorageException('Marketplace image type is not allowed');
        }

        final bytes = await file.readAsBytes();
        if (bytes.length > AppConstants.maxUploadSizeBytes) {
          throw const StorageException('File size exceeds 10 MB limit');
        }
        if (!StorageUtils.validateMagicBytes(bytes, ext)) {
          throw StorageException('File content does not match .$ext format');
        }

        final storagePath = 'marketplace-images/$userId/$listingId/$i.$ext';
        final fileApi = _client.storage.from(
          SupabaseConstants.marketplacePhotosBucket,
        );
        await fileApi.uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: StorageUtils.getMimeType(file.path),
            upsert: true,
          ),
        );
        final url = fileApi.getPublicUrl(storagePath);
        urls.add(url);
      } catch (e, st) {
        AppLogger.error('marketplace', e, st);
        rethrow;
      }
    }
    return urls;
  }

  /// Deletes all images for a listing from Supabase Storage.
  Future<void> deleteImages({
    required String userId,
    required String listingId,
  }) async {
    try {
      final prefix = 'marketplace-images/$userId/$listingId/';
      final files = await _client.storage
          .from(SupabaseConstants.marketplacePhotosBucket)
          .list(path: prefix);
      if (files.isNotEmpty) {
        final paths = files.map((f) => '$prefix${f.name}').toList();
        await _client.storage
            .from(SupabaseConstants.marketplacePhotosBucket)
            .remove(paths);
      }
    } catch (e) {
      AppLogger.warning('marketplace: Failed to delete images: $e');
    }
  }
}
