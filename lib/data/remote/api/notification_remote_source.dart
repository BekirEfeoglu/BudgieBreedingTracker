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

  /// Fetches all non-deleted notifications (no `is_deleted` filter for
  /// notifications — they use hard-delete).
  @override
  Future<List<AppNotification>> fetchAll(String userId) async {
    try {
      final response = await table
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return response.map((json) => fromJson(json)).toList();
    } catch (e, st) {
      throw handleError(e, st);
    }
  }

  /// Fetches notifications updated since [since] without `is_deleted` filter.
  ///
  /// Notifications table uses hard-delete, so filtering by `is_deleted`
  /// would fail on projects where the column is absent.
  @override
  Future<List<AppNotification>> fetchUpdatedSince(
    String userId,
    DateTime since,
  ) async {
    try {
      final response = await table
          .select()
          .eq('user_id', userId)
          .gte('updated_at', since.toIso8601String())
          .order('updated_at');
      return response.map((json) => fromJson(json)).toList();
    } catch (e, st) {
      throw handleError(e, st);
    }
  }

  /// Fetches unread notifications for a user.
  Future<List<AppNotification>> fetchUnread(String userId) async {
    final response = await table
        .select()
        .eq('user_id', userId)
        .eq('read', false)
        .order('created_at', ascending: false);
    return response.map((json) => fromJson(json)).toList();
  }

  /// Fetches notification settings for a user.
  Future<NotificationSettings?> fetchSettings(String userId) async {
    final response = await client
        .from(SupabaseConstants.notificationSettingsTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return response != null ? NotificationSettings.fromJson(response) : null;
  }

  /// Upserts notification settings.
  ///
  /// NotificationSettings is primarily local-only but settings are
  /// synced to Supabase for cross-device consistency.
  Future<void> upsertSettings(NotificationSettings settings) async {
    final json = settings.toJson();
    json.remove('created_at');
    json.remove('updated_at');
    await client
        .from(SupabaseConstants.notificationSettingsTable)
        .upsert(json);
  }
}
