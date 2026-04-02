import '../models/marketplace_listing_model.dart';
import '../remote/api/marketplace_listing_remote_source.dart';
import '../remote/api/marketplace_favorite_remote_source.dart';
import '../../core/utils/logger.dart';

class MarketplaceRepository {
  final MarketplaceListingRemoteSource _listingSource;
  final MarketplaceFavoriteRemoteSource _favoriteSource;

  const MarketplaceRepository({
    required MarketplaceListingRemoteSource listingSource,
    required MarketplaceFavoriteRemoteSource favoriteSource,
  })  : _listingSource = listingSource,
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
    final row = await _listingSource.fetchById(id);
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
    return MarketplaceListing.fromJson(row);
  }

  Future<MarketplaceListing> updateListing(
    String id,
    Map<String, dynamic> data,
  ) async {
    final row = await _listingSource.update(id, data);
    return MarketplaceListing.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _listingSource.softDelete(id);
  }

  Future<void> updateStatus(String id, String status) async {
    await _listingSource.updateStatus(id, status);
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

  Future<List<MarketplaceListing>> search({
    required String query,
    required String currentUserId,
    int limit = 20,
  }) async {
    final rows = await _listingSource.search(query, limit: limit);
    return _enrichListings(rows, currentUserId);
  }

  Future<List<MarketplaceListing>> _enrichListings(
    List<Map<String, dynamic>> rows,
    String currentUserId,
  ) async {
    if (rows.isEmpty) return [];

    List<String> favoritedIds = [];
    try {
      favoritedIds =
          await _favoriteSource.fetchFavoritedListingIds(currentUserId);
    } catch (e) {
      AppLogger.warning('marketplace: Failed to fetch favorites: $e');
    }

    return rows.map((row) {
      final listing = MarketplaceListing.fromJson(row);
      return listing.copyWith(
        isFavoritedByMe: favoritedIds.contains(listing.id),
      );
    }).toList();
  }
}
