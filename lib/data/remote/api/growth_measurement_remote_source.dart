import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';
import 'package:budgie_breeding_tracker/data/models/supabase_extensions.dart';
import 'package:budgie_breeding_tracker/data/remote/api/base_remote_source.dart';

/// Remote data source for [GrowthMeasurement] records in Supabase.
///
/// GrowthMeasurement has no `is_deleted` column, so uses
/// [BaseRemoteSourceNoSoftDelete].
class GrowthMeasurementRemoteSource
    extends BaseRemoteSourceNoSoftDelete<GrowthMeasurement> {
  const GrowthMeasurementRemoteSource(super.client);

  @override
  String get tableName => SupabaseConstants.growthMeasurementsTable;

  @override
  GrowthMeasurement fromJson(Map<String, dynamic> json) =>
      GrowthMeasurement.fromJson(json);

  @override
  Map<String, dynamic> toSupabaseJson(GrowthMeasurement model) =>
      model.toSupabase();

  /// Fetches growth measurements for a specific chick.
  Future<List<GrowthMeasurement>> fetchByChick(
    String userId,
    String chickId,
  ) async {
    final response = await table
        .select()
        .eq('user_id', userId)
        .eq('chick_id', chickId)
        .order('measurement_date', ascending: false);
    return response.map((json) => fromJson(json)).toList();
  }
}
