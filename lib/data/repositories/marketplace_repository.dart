import 'dart:async';

import '../models/marketplace_listing_model.dart';
import '../remote/api/marketplace_listing_remote_source.dart';
import '../remote/api/marketplace_favorite_remote_source.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/storage_url_normalizer.dart';

/// Online-first: cross-user public listings. No local Drift mirror by design.
///
/// Repository for marketplace listings.
///
/// Custom implementation (not extending [BaseRepository]) because marketplace
/// is online-first with no Drift mirror — listings cross user boundaries
/// (any user can browse all listings) and use server-side search/filtering.
class MarketplaceRepository {
  final MarketplaceListingRemoteSource _listingSource;
  final MarketplaceFavoriteRemoteSource _favoriteSource;

  const MarketplaceRepository({
    required MarketplaceListingRemoteSource listingSource,
    required MarketplaceFavoriteRemoteSource favoriteSource,
  }) : _listingSource = listingSource,
       _favoriteSource = favoriteSource;

  Future<List<MarketplaceListing>> getListings({
    required String currentUserId,
    int limit = 20,
    DateTime? before,
    String? city,
    String? listingType,
    String? gender,
    double? minPrice,
    double? maxPrice,
  }) async {
    final rows = await _listingSource.fetchListings(
      limit: limit,
      before: before,
      city: city,
      listingType: listingType,
      gender: gender,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
    return _enrichListings(rows, currentUserId);
  }

  Future<MarketplaceListing?> getById({
    required String id,
    required String currentUserId,
  }) async {
    final row = await _listingSource.fetchById(
      id,
      currentUserId: currentUserId,
    );
    if (row == null) return null;
    final enriched = await _enrichListings([row], currentUserId);
    return enriched.firstOrNull;
  }

  Future<List<MarketplaceListing>> getByUser({
    required String userId,
    required String currentUserId,
  }) async {
    final rows = await _listingSource.fetchByUser(userId);
    return _enrichListings(rows, currentUserId);
  }

  Future<MarketplaceListing> create(Map<String, dynamic> data) async {
    final row = await _listingSource.insert(data);
    return _listingFromRow(row);
  }

  Future<MarketplaceListing> updateListing(
    String id,
    Map<String, dynamic> data, {
    required String userId,
  }) async {
    final row = await _listingSource.update(id, data, userId: userId);
    return _listingFromRow(row);
  }

  Future<void> delete(String id, {required String userId}) async {
    await _listingSource.softDelete(id, userId: userId);
    // Fire-and-forget storage cleanup. Without this, every soft-deleted
    // listing leaks its images into the public bucket forever (audit
    // C2). `deleteImages` already swallows its own errors — wrap in
    // unawaited so the caller's UX flow doesn't block on slow storage.
    unawaited(_listingSource.deleteImages(userId: userId, listingId: id));
  }

  Future<void> updateStatus(
    String id,
    String status, {
    required String userId,
  }) async {
    await _listingSource.updateStatus(id, status, userId: userId);
  }

  Future<void> incrementViewCount(String id) async {
    await _listingSource.incrementViewCount(id);
  }

  Future<void> toggleFavorite({
    required String userId,
    required String listingId,
    required bool isFavorited,
  }) async {
    if (isFavorited) {
      await _favoriteSource.removeFavorite(userId, listingId);
    } else {
      await _favoriteSource.addFavorite(userId, listingId);
    }
  }

  Future<List<MarketplaceListing>> getFavorites({
    required String currentUserId,
  }) async {
    final favoritedIds = await _favoriteSource.fetchFavoritedListingIds(
      currentUserId,
    );
    if (favoritedIds.isEmpty) return [];

    final rows = await _listingSource.fetchByIds(favoritedIds);
    return rows
        .map((row) => _listingFromRow(row, isFavoritedByMe: true))
        .toList();
  }

  Future<List<MarketplaceListing>> search({
    required String query,
    required String currentUserId,
    int limit = 20,
  }) async {
    final rows = await _listingSource.search(query, limit: limit);
    return _enrichListings(rows, currentUserId);
  }

  Future<List<String>> uploadImages({
    required String userId,
    required String listingId,
    required List<String> localPaths,
  }) async {
    return _listingSource.uploadImages(
      userId: userId,
      listingId: listingId,
      localPaths: localPaths,
    );
  }

  Future<List<MarketplaceListing>> _enrichListings(
    List<Map<String, dynamic>> rows,
    String currentUserId,
  ) async {
    if (rows.isEmpty) return [];

    List<String> favoritedIds = [];
    try {
      favoritedIds = await _favoriteSource.fetchFavoritedListingIds(
        currentUserId,
      );
    } catch (e) {
      AppLogger.warning('marketplace: Failed to fetch favorites: $e');
    }

    return rows.map((row) {
      final listing = _listingFromRow(row);
      return listing.copyWith(
        isFavoritedByMe: favoritedIds.contains(listing.id),
      );
    }).toList();
  }

  MarketplaceListing _listingFromRow(
    Map<String, dynamic> row, {
    bool? isFavoritedByMe,
  }) {
    final normalized = {
      ...row,
      'avatar_url': StorageUrlNormalizer.normalizePublicObjectUrl(
        row['avatar_url']?.toString(),
      ),
      'image_urls': StorageUrlNormalizer.normalizePublicObjectUrls(
        _asStringList(row['image_urls']),
      ),
    };
    final listing = MarketplaceListing.fromJson(normalized);
    return isFavoritedByMe == null
        ? listing
        : listing.copyWith(isFavoritedByMe: isFavoritedByMe);
  }
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim())
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}
