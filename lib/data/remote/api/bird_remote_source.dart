import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/supabase_extensions.dart';
import 'package:budgie_breeding_tracker/data/remote/api/base_remote_source.dart';

/// Remote data source for [Bird] records in Supabase.
class BirdRemoteSource extends BaseRemoteSource<Bird> {
  const BirdRemoteSource(super.client);

  @override
  String get tableName => SupabaseConstants.birdsTable;

  @override
  Bird fromJson(Map<String, dynamic> json) => Bird.fromJson(json);

  @override
  Map<String, dynamic> toSupabaseJson(Bird model) => model.toSupabase();

  /// Fetches birds filtered by gender for a user.
  Future<List<Bird>> fetchByGender(String userId, String gender) async {
    try {
      final response = await table
          .select()
          .eq(SupabaseConstants.colUserId, userId)
          .eq(SupabaseConstants.colGender, gender)
          .eq(SupabaseConstants.colIsDeleted, false)
          .order(SupabaseConstants.colName);
      return response.map((json) => fromJson(json)).toList();
    } catch (e, st) {
      throw handleError(e, st);
    }
  }
}
