import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/models/nest_model.dart';
import 'package:budgie_breeding_tracker/data/models/supabase_extensions.dart';
import 'package:budgie_breeding_tracker/data/remote/api/base_remote_source.dart';

class NestRemoteSource extends BaseRemoteSource<Nest> {
  const NestRemoteSource(super.client);

  @override
  String get tableName => SupabaseConstants.nestsTable;

  @override
  Nest fromJson(Map<String, dynamic> json) => Nest.fromJson(json);

  @override
  Map<String, dynamic> toSupabaseJson(Nest model) => model.toSupabase();

  Future<List<Nest>> fetchAvailable(String userId) async {
    final response = await table
        .select()
        .eq('user_id', userId)
        .eq('status', NestStatus.available.name)
        .eq('is_deleted', false)
        .order('name');
    return response.map((json) => fromJson(json)).toList();
  }
}
