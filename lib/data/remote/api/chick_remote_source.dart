import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/supabase_extensions.dart';
import 'package:budgie_breeding_tracker/data/remote/api/base_remote_source.dart';

/// Remote data source for [Chick] records in Supabase.
class ChickRemoteSource extends BaseRemoteSource<Chick> {
  const ChickRemoteSource(super.client);

  @override
  String get tableName => SupabaseConstants.chicksTable;

  @override
  Chick fromJson(Map<String, dynamic> json) => Chick.fromJson(json);

  @override
  Map<String, dynamic> toSupabaseJson(Chick model) => model.toSupabase();

  /// Fetches chicks by clutch id.
  Future<List<Chick>> fetchByClutch(String userId, String clutchId) async {
    final response = await table
        .select()
        .eq('user_id', userId)
        .eq('clutch_id', clutchId)
        .eq('is_deleted', false)
        .order('hatch_date');
    return response.map((json) => fromJson(json)).toList();
  }
}
