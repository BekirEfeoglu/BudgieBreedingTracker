import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/data/models/supabase_extensions.dart';
import 'package:budgie_breeding_tracker/data/remote/api/base_remote_source.dart';

/// Remote data source for [Profile] records in Supabase.
///
/// Profile has no `is_deleted` column. The profile id equals the
/// authenticated user's uid, so fetch-by-id is the primary access pattern.
class ProfileRemoteSource extends BaseRemoteSourceNoSoftDelete<Profile> {
  const ProfileRemoteSource(super.client);

  @override
  String get tableName => SupabaseConstants.profilesTable;

  @override
  Profile fromJson(Map<String, dynamic> json) => Profile.fromJson(json);

  @override
  Map<String, dynamic> toSupabaseJson(Profile model) => model.toSupabase();

  /// Fetches are not user-scoped; profile id = userId.
  @override
  Future<List<Profile>> fetchAll(String userId) async {
    final profile = await fetchById(userId, userId: userId);
    return profile != null ? [profile] : [];
  }

  /// Profile id = userId, so we validate that id == userId for safety.
  /// Even though RLS enforces this server-side, client-side check
  /// prevents accidental misuse and provides defense-in-depth.
  @override
  Future<Profile?> fetchById(String id, {required String userId}) async {
    if (id != userId) {
      throw ArgumentError('Profile ID must match authenticated user ID');
    }
    try {
      final response = await table
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response != null ? fromJson(response) : null;
    } catch (e, st) {
      throw handleError(e, st);
    }
  }
}
