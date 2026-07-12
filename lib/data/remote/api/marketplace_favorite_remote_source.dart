import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import 'base_remote_source.dart';

class MarketplaceFavoriteRemoteSource {
  final SupabaseClient _client;

  MarketplaceFavoriteRemoteSource(this._client);

  Future<List<String>> fetchFavoritedListingIds(String userId) async {
    try {
      final response = await _client
          .from(SupabaseConstants.marketplaceFavoritesTable)
          .select(SupabaseConstants.colListingId)
          .eq(SupabaseConstants.colUserId, userId);
      return List<String>.from(
        (response as List).map((r) => r['listing_id'] as String),
      );
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag('marketplace_favorites', e, st);
    }
  }

  Future<void> addFavorite(String userId, String listingId) async {
    try {
      await _client
          .from(SupabaseConstants.marketplaceFavoritesTable)
          .upsert(
            {
              SupabaseConstants.colUserId: userId,
              SupabaseConstants.colListingId: listingId,
            },
            onConflict: 'user_id,listing_id',
            ignoreDuplicates: true,
          );
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag('marketplace_favorites', e, st);
    }
  }

  Future<void> removeFavorite(String userId, String listingId) async {
    try {
      await _client
          .from(SupabaseConstants.marketplaceFavoritesTable)
          .delete()
          .eq(SupabaseConstants.colUserId, userId)
          .eq(SupabaseConstants.colListingId, listingId);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag('marketplace_favorites', e, st);
    }
  }
}
