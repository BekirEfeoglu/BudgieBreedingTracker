import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';

class MarketplaceFavoriteRemoteSource {
  final SupabaseClient _client;

  MarketplaceFavoriteRemoteSource(this._client);

  Future<List<String>> fetchFavoritedListingIds(String userId) async {
    try {
      final response = await _client
          .from(SupabaseConstants.marketplaceFavoritesTable)
          .select('listing_id')
          .eq('user_id', userId);
      return List<String>.from(
        (response as List).map((r) => r['listing_id'] as String),
      );
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<void> addFavorite(String userId, String listingId) async {
    try {
      await _client
          .from(SupabaseConstants.marketplaceFavoritesTable)
          .upsert(
            {'user_id': userId, 'listing_id': listingId},
            onConflict: 'user_id,listing_id',
            ignoreDuplicates: true,
          );
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }

  Future<void> removeFavorite(String userId, String listingId) async {
    try {
      await _client
          .from(SupabaseConstants.marketplaceFavoritesTable)
          .delete()
          .eq('user_id', userId)
          .eq('listing_id', listingId);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      rethrow;
    }
  }
}
