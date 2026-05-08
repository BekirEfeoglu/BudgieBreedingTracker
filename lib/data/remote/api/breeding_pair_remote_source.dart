import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/supabase_extensions.dart';
import 'package:budgie_breeding_tracker/data/remote/api/base_remote_source.dart';

/// Remote data source for [BreedingPair] records in Supabase.
class BreedingPairRemoteSource extends BaseRemoteSource<BreedingPair> {
  const BreedingPairRemoteSource(super.client);

  @override
  String get tableName => SupabaseConstants.breedingPairsTable;

  @override
  BreedingPair fromJson(Map<String, dynamic> json) =>
      BreedingPair.fromJson(json);

  @override
  Map<String, dynamic> toSupabaseJson(BreedingPair model) => model.toSupabase();

  /// Fetches active breeding pairs for a user.
  Future<List<BreedingPair>> fetchActive(String userId) async {
    try {
      final response = await table
          .select()
          .eq(SupabaseConstants.colUserId, userId)
          .eq(SupabaseConstants.colStatus, 'active')
          .eq(SupabaseConstants.colIsDeleted, false)
          .order(SupabaseConstants.colPairingDate);
      return response.map((json) => fromJson(json)).toList();
    } catch (e, st) {
      throw handleError(e, st);
    }
  }

  /// Fetches breeding pairs that include a specific bird.
  Future<List<BreedingPair>> fetchByBird(String userId, String birdId) async {
    try {
      // Do NOT Uri.encodeComponent — PostgREST client handles encoding.
      final response = await table
          .select()
          .eq(SupabaseConstants.colUserId, userId)
          .or(
            '${SupabaseConstants.colMaleId}.eq.$birdId,'
            '${SupabaseConstants.colFemaleId}.eq.$birdId',
          )
          .eq(SupabaseConstants.colIsDeleted, false)
          .order(SupabaseConstants.colPairingDate);
      return response.map((json) => fromJson(json)).toList();
    } catch (e, st) {
      throw handleError(e, st);
    }
  }
}
