import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';
import 'package:budgie_breeding_tracker/data/models/supabase_extensions.dart';
import 'package:budgie_breeding_tracker/data/remote/api/base_remote_source.dart';

class PhotoRemoteSource extends BaseRemoteSourceNoSoftDelete<Photo> {
  const PhotoRemoteSource(super.client);

  @override
  String get tableName => SupabaseConstants.photosTable;

  @override
  Photo fromJson(Map<String, dynamic> json) => Photo.fromJson(json);

  @override
  Map<String, dynamic> toSupabaseJson(Photo model) => model.toSupabase();

  Future<List<Photo>> fetchByEntity(String userId, String entityId) async {
    final response = await table
        .select()
        .eq('user_id', userId)
        .eq('entity_id', entityId)
        .order('created_at');
    return response.map((json) => fromJson(json)).toList();
  }
}
