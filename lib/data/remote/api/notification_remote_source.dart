import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/data/models/supabase_extensions.dart';
import 'package:budgie_breeding_tracker/data/remote/api/base_remote_source.dart';

/// Remote data source for [AppNotification] records in Supabase.
///
/// Also handles [NotificationSettings] via the separate settings table.
class NotificationRemoteSource extends BaseRemoteSource<AppNotification> {
  const NotificationRemoteSource(super.client);

  @override
  String get tableName => SupabaseConstants.notificationsTable;

  @override
  AppNotification fromJson(Map<String, dynamic> json) =>
      AppNotification.fromJson(json);

  @override
  Map<String, dynamic> toSupabaseJson(AppNotification model) =>
      model.toSupabase();

  /// Hard cap on notifications returned by a single fetch. Users who have
  /// accumulated more than this will see only the most recent; older
  /// notifications remain in the DB but require server-side cleanup.
  static const _fetchAllLimit = 500;

  /// Fetches the most recent [_fetchAllLimit] notifications (no `is_deleted`
  /// filter — notifications use hard-delete).
  @override
  Future<List<AppNotification>> fetchAll(String userId) async {
    try {
      final response = await table
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(_fetchAllLimit);
      return response.map((json) => fromJson(json)).toList();
    } catch (e, st) {
      throw handleError(e, st);
    }
  }

  /// Fetches unread notifications for a user.
  Future<List<AppNotification>> fetchUnread(String userId) async {
    try {
      final response = await table
          .select()
          .eq('user_id', userId)
          .eq('read', false)
          .order('created_at', ascending: false);
      return response.map((json) => fromJson(json)).toList();
    } catch (e, st) {
      throw handleError(e, st);
    }
  }

  /// Fetches notification settings for a user.
  Future<NotificationSettings?> fetchSettings(String userId) async {
    try {
      final response = await client
          .from(SupabaseConstants.notificationSettingsTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response != null ? NotificationSettings.fromJson(response) : null;
    } catch (e, st) {
      throw handleError(e, st);
    }
  }

  /// Upserts notification settings.
  ///
  /// NotificationSettings is primarily local-only but settings are
  /// synced to Supabase for cross-device consistency.
  Future<void> upsertSettings(NotificationSettings settings) async {
    try {
      final json = settings.toJson();
      json.remove('created_at');
      json.remove('updated_at');
      await client
          .from(SupabaseConstants.notificationSettingsTable)
          .upsert(json);
    } catch (e, st) {
      throw handleError(e, st);
    }
  }
}
