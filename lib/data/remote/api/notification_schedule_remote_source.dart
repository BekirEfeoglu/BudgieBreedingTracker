import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/models/notification_schedule_model.dart';
import 'package:budgie_breeding_tracker/data/models/supabase_extensions.dart';
import 'package:budgie_breeding_tracker/data/remote/api/base_remote_source.dart';

/// Remote data source for [NotificationSchedule] records in Supabase.
///
/// Uses [BaseRemoteSourceNoSoftDelete] since this table has no `is_deleted` column.
class NotificationScheduleRemoteSource
    extends BaseRemoteSourceNoSoftDelete<NotificationSchedule> {
  const NotificationScheduleRemoteSource(super.client);

  @override
  String get tableName => SupabaseConstants.notificationSchedulesTable;

  @override
  NotificationSchedule fromJson(Map<String, dynamic> json) =>
      NotificationSchedule.fromJson(json);

  @override
  Map<String, dynamic> toSupabaseJson(NotificationSchedule model) =>
      model.toSupabase();

  /// Fetches pending (unprocessed, active) schedules for a user.
  Future<List<NotificationSchedule>> fetchPending(String userId) async {
    final response = await table
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .isFilter('processed_at', null)
        .order('scheduled_at');
    return response.map((json) => fromJson(json)).toList();
  }
}
