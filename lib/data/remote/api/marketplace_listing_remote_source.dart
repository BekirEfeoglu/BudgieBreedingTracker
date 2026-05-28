import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart' as app_exc;
import '../../../core/utils/logger.dart';
import '../../../domain/services/moderation/image_safety_service.dart';
import '../storage/storage_utils.dart';
import 'base_remote_source.dart';

class MarketplaceListingRemoteSource {
  final SupabaseClient _client;
  final ImageSafetyService? _imageSafetyService;

  MarketplaceListingRemoteSource(
    this._client, {
    ImageSafetyService? imageSafetyService,
  }) : _imageSafetyService = imageSafetyService;

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
      throw BaseRemoteSource.handleErrorForTag('marketplace_listings', e, st);
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
      throw BaseRemoteSource.handleErrorForTag('marketplace_listings', e, st);
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
      throw BaseRemoteSource.handleErrorForTag('marketplace_listings', e, st);
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
      throw BaseRemoteSource.handleErrorForTag('marketplace_listings', e, st);
    }
  }

  Future<Map<String, dynamic>> insert(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .upsert(data, onConflict: SupabaseConstants.colId)
          .select(_selectColumns)
          .single();
      return response;
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag('marketplace_listings', e, st);
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
      throw BaseRemoteSource.handleErrorForTag('marketplace_listings', e, st);
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
      throw BaseRemoteSource.handleErrorForTag('marketplace_listings', e, st);
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
      throw BaseRemoteSource.handleErrorForTag('marketplace_listings', e, st);
    }
  }

  Future<void> incrementViewCount(String id) async {
    try {
      // Atomic increment via RPC. Previously this used a select-then-update
      // pattern which lost concurrent views (N viewers within the same
      // SELECT window only bumped the counter by 1). The RPC runs the
      // UPDATE in a single statement so concurrent viewers each count.
      await _client.rpc(
        'increment_marketplace_listing_view',
        params: {'p_id': id},
      );
    } catch (e, st) {
      // Best-effort: a failed increment doesn't break the detail view.
      // Capture stack so a chronic failure becomes traceable.
      AppLogger.error('MarketplaceListing.incrementViewCount', e, st);
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
      throw BaseRemoteSource.handleErrorForTag('marketplace_listings', e, st);
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

        // Image safety scan (App Store UGC guideline 1.2). Fail-closed: if
        // scanner unavailable or image flagged, reject the upload.
        final scanner = _imageSafetyService;
        if (scanner == null) {
          throw const StorageException('Image safety scanner unavailable');
        }
        final scan = await scanner.scanImage(
          bytes: bytes,
          mimeType: StorageUtils.getMimeType(file.path),
        );
        if (!scan.isSafe) {
          AppLogger.warning(
            'Marketplace image rejected by safety scan: '
            '${scan.rejectionReason}',
          );
          throw StorageException(
            'Image rejected: ${scan.rejectionReason ?? 'safety_scan_failed'}',
          );
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
        if (e is app_exc.AppException || e is StorageException) rethrow;
        AppLogger.error('marketplace_listings.uploadImages', e, st);
        // Preserve domain-typed exceptions above so callers can react
        // to specific rejection reasons (size, mime, safety-scan, …).
        // Everything else gets the error-mapping wrapper which
        // converts PostgrestException to typed AppException subtypes.
        throw BaseRemoteSource.handleErrorForTag(
          'marketplace_listings',
          e,
          st,
        );
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
    } catch (e, st) {
      // Best-effort cleanup — the listing soft-delete already succeeded.
      // Stack trace lets us see if orphans accumulate due to a recurring
      // bucket / network issue.
      AppLogger.error('MarketplaceListing.deleteImages', e, st);
    }
  }
}
