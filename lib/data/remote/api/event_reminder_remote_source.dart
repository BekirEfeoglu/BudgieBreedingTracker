import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/models/event_reminder_model.dart';
import 'package:budgie_breeding_tracker/data/models/supabase_extensions.dart';
import 'package:budgie_breeding_tracker/data/remote/api/base_remote_source.dart';

/// Remote data source for [EventReminder] records in Supabase.
class EventReminderRemoteSource extends BaseRemoteSource<EventReminder> {
  const EventReminderRemoteSource(super.client);

  @override
  String get tableName => SupabaseConstants.eventRemindersTable;

  @override
  EventReminder fromJson(Map<String, dynamic> json) =>
      EventReminder.fromJson(json);

  @override
  Map<String, dynamic> toSupabaseJson(EventReminder model) =>
      model.toSupabase();

  /// Fetches reminders for a specific event.
  Future<List<EventReminder>> fetchByEvent(String userId, String eventId) async {
    final response = await table
        .select()
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .eq('is_deleted', false)
        .order('minutes_before');
    return response.map((json) => fromJson(json)).toList();
  }
}
