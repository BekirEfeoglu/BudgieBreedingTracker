import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/models/supabase_extensions.dart';
import 'package:budgie_breeding_tracker/data/remote/api/base_remote_source.dart';

/// Remote data source for [HealthRecord] records in Supabase.
class HealthRecordRemoteSource extends BaseRemoteSource<HealthRecord> {
  const HealthRecordRemoteSource(super.client);

  @override
  String get tableName => SupabaseConstants.healthRecordsTable;

  @override
  HealthRecord fromJson(Map<String, dynamic> json) =>
      HealthRecord.fromJson(json);

  @override
  Map<String, dynamic> toSupabaseJson(HealthRecord model) =>
      model.toSupabase();

  /// Fetches health records for a specific bird.
  Future<List<HealthRecord>> fetchByBird(String userId, String birdId) async {
    final response = await table
        .select()
        .eq('user_id', userId)
        .eq('bird_id', birdId)
        .eq('is_deleted', false)
        .order('date', ascending: false);
    return response.map((json) => fromJson(json)).toList();
  }
}
