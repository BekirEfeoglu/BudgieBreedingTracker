import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/models/supabase_extensions.dart';
import 'package:budgie_breeding_tracker/data/remote/api/base_remote_source.dart';

/// Remote data source for [Incubation] records in Supabase.
///
/// Incubation has no `is_deleted` column, so uses [BaseRemoteSourceNoSoftDelete].
class IncubationRemoteSource extends BaseRemoteSourceNoSoftDelete<Incubation> {
  const IncubationRemoteSource(super.client);

  @override
  String get tableName => SupabaseConstants.incubationsTable;

  @override
  Incubation fromJson(Map<String, dynamic> json) => Incubation.fromJson(json);

  @override
  Map<String, dynamic> toSupabaseJson(Incubation model) => model.toSupabase();

  /// Fetches active incubations for a user.
  Future<List<Incubation>> fetchActive(String userId) async {
    final response = await table
        .select()
        .eq('user_id', userId)
        .eq('status', 'active')
        .order('start_date');
    return response.map((json) => fromJson(json)).toList();
  }

  /// Fetches incubations by breeding pair id.
  Future<List<Incubation>> fetchByBreedingPair(
    String userId,
    String pairId,
  ) async {
    final response = await table
        .select()
        .eq('user_id', userId)
        .eq('breeding_pair_id', pairId)
        .order('start_date');
    return response.map((json) => fromJson(json)).toList();
  }
}
