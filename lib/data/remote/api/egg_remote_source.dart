import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/supabase_extensions.dart';
import 'package:budgie_breeding_tracker/data/remote/api/base_remote_source.dart';

/// Remote data source for [Egg] records in Supabase.
class EggRemoteSource extends BaseRemoteSource<Egg> {
  const EggRemoteSource(super.client);

  @override
  String get tableName => SupabaseConstants.eggsTable;

  @override
  Egg fromJson(Map<String, dynamic> json) => Egg.fromJson(json);

  @override
  Map<String, dynamic> toSupabaseJson(Egg model) => model.toSupabase();

  /// Fetches eggs by clutch id.
  Future<List<Egg>> fetchByClutch(String userId, String clutchId) async {
    try {
      final response = await table
          .select()
          .eq('user_id', userId)
          .eq('clutch_id', clutchId)
          .eq('is_deleted', false)
          .order('egg_number');
      return response.map((json) => fromJson(json)).toList();
    } catch (e, st) {
      throw handleError(e, st);
    }
  }

  /// Fetches eggs by incubation id.
  Future<List<Egg>> fetchByIncubation(
    String userId,
    String incubationId,
  ) async {
    try {
      final response = await table
          .select()
          .eq('user_id', userId)
          .eq('incubation_id', incubationId)
          .eq('is_deleted', false)
          .order('egg_number');
      return response.map((json) => fromJson(json)).toList();
    } catch (e, st) {
      throw handleError(e, st);
    }
  }
}
