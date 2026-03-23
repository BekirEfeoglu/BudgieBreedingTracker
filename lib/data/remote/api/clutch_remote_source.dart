import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/supabase_extensions.dart';
import 'package:budgie_breeding_tracker/data/remote/api/base_remote_source.dart';

class ClutchRemoteSource extends BaseRemoteSource<Clutch> {
  const ClutchRemoteSource(super.client);

  @override
  String get tableName => SupabaseConstants.clutchesTable;

  @override
  Clutch fromJson(Map<String, dynamic> json) {
    final mapped = {...json};
    if (mapped.containsKey('breeding_pair_id')) {
      mapped['breeding_id'] = mapped.remove('breeding_pair_id');
    }
    return Clutch.fromJson(mapped);
  }

  @override
  Map<String, dynamic> toSupabaseJson(Clutch model) => model.toSupabase();

  Future<List<Clutch>> fetchByBreeding(String userId, String breedingId) async {
    final response = await table
        .select()
        .eq('user_id', userId)
        .eq('breeding_pair_id', breedingId)
        .eq('is_deleted', false)
        .order('created_at');
    return response.map((json) => fromJson(json)).toList();
  }
}
