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
  NotificationSchedule fromJson(Map<String, dynamic> json) {
    final mapped = {...json};
    if (mapped.containsKey('body') && !mapped.containsKey('message')) {
      mapped['message'] = mapped.remove('body');
    }
    if (mapped.containsKey('repeat_interval_minutes') &&
        !mapped.containsKey('interval_minutes')) {
      mapped['interval_minutes'] = mapped.remove('repeat_interval_minutes');
    }
    if (mapped.containsKey('entity_id') &&
        !mapped.containsKey('related_entity_id')) {
      mapped['related_entity_id'] = mapped.remove('entity_id');
    }
    return NotificationSchedule.fromJson(mapped);
  }

  @override
  Map<String, dynamic> toSupabaseJson(NotificationSchedule model) =>
      model.toSupabase();

  /// Fetches pending (active) schedules for a user.
  Future<List<NotificationSchedule>> fetchPending(String userId) async {
    final response = await table
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('scheduled_at');
    return response.map((json) => fromJson(json)).toList();
  }
}
