import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';
import 'package:budgie_breeding_tracker/data/models/supabase_extensions.dart';
import 'package:budgie_breeding_tracker/data/remote/api/base_remote_source.dart';

class PhotoRemoteSource extends BaseRemoteSourceNoSoftDelete<Photo> {
  const PhotoRemoteSource(super.client);

  @override
  String get tableName => SupabaseConstants.photosTable;

  @override
  Photo fromJson(Map<String, dynamic> json) {
    final mapped = {...json};
    if (mapped.containsKey('url') && !mapped.containsKey('file_name')) {
      mapped['file_name'] = mapped.remove('url');
    }
    if (mapped.containsKey('thumbnail_url') &&
        !mapped.containsKey('file_path')) {
      mapped['file_path'] = mapped.remove('thumbnail_url');
    }
    return Photo.fromJson(mapped);
  }

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
