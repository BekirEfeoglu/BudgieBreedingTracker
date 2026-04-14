import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';

class MarketplaceListingRemoteSource {
  final SupabaseClient _client;

  MarketplaceListingRemoteSource(this._client);

  static const _selectColumns =
      'id, user_id, listing_type, title, description, price, currency, '
      'bird_id, species, mutation, gender, age, image_urls, city, status, '
      'view_count, message_count, is_verified_breeder, is_deleted, '
      'needs_review, username, avatar_url, created_at, updated_at';

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
          .eq('is_deleted', false)
          .eq('status', 'active');

      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }
      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
      }
      if (listingType != null && listingType.isNotEmpty) {
        query = query.eq('listing_type', listingType);
      }
      if (gender != null && gender.isNotEmpty) {
        query = query.eq('gender', gender);
      }
      if (minPrice != null) {
        query = query.gte('price', minPrice);
      }
      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchById(String id) async {
    try {
      final response = await _client
          .from(SupabaseConstants.marketplaceListingsTable)
          .select(_selectColumns)
          .eq('id', id)
          .maybeSingle();
      return response;
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
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);
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
          .eq('id', id)
          .eq('user_id', userId)
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
          .update({'is_deleted': true})
          .eq('id', id)
          .eq('user_id', userId);
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
          .update({'status': status})
          .eq('id', id)
          .eq('user_id', userId);
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
          .eq('id', id)
          .maybeSingle();
      if (current != null) {
        final newCount = (current['view_count'] as int? ?? 0) + 1;
        await _client
            .from(SupabaseConstants.marketplaceListingsTable)
            .update({'view_count': newCount})
            .eq('id', id);
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
          .eq('is_deleted', false)
          .eq('status', 'active')
          .or('title.ilike.%$sanitized%,description.ilike.%$sanitized%')
          .order('created_at', ascending: false)
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
    final urls = <String>[];
    for (var i = 0; i < localPaths.length; i++) {
      try {
        final storagePath = 'marketplace-images/$userId/$listingId/$i.jpg';
        final file = File(localPaths[i]);
        await _client.storage.from(SupabaseConstants.marketplacePhotosBucket).upload(
              storagePath,
              file,
              fileOptions: const FileOptions(upsert: true),
            );
        final url = _client.storage.from(SupabaseConstants.marketplacePhotosBucket).getPublicUrl(storagePath);
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
      final files = await _client.storage.from(SupabaseConstants.marketplacePhotosBucket).list(path: prefix);
      if (files.isNotEmpty) {
        final paths = files.map((f) => '$prefix${f.name}').toList();
        await _client.storage.from(SupabaseConstants.marketplacePhotosBucket).remove(paths);
      }
    } catch (e) {
      AppLogger.warning('marketplace: Failed to delete images: $e');
    }
  }
}
