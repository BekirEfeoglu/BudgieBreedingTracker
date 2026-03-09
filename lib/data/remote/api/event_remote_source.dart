import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/models/supabase_extensions.dart';
import 'package:budgie_breeding_tracker/data/remote/api/base_remote_source.dart';

/// Remote data source for [Event] records in Supabase.
class EventRemoteSource extends BaseRemoteSource<Event> {
  const EventRemoteSource(super.client);

  @override
  String get tableName => SupabaseConstants.eventsTable;

  @override
  Event fromJson(Map<String, dynamic> json) => Event.fromJson(json);

  @override
  Map<String, dynamic> toSupabaseJson(Event model) => model.toSupabase();

  /// Fetches events within a date range for a user.
  Future<List<Event>> fetchByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final response = await table
        .select()
        .eq('user_id', userId)
        .gte('event_date', start.toIso8601String())
        .lte('event_date', end.toIso8601String())
        .eq('is_deleted', false)
        .order('event_date');
    return response.map((json) => fromJson(json)).toList();
  }

  /// Fetches events for a specific bird.
  Future<List<Event>> fetchByBird(String userId, String birdId) async {
    final response = await table
        .select()
        .eq('user_id', userId)
        .eq('bird_id', birdId)
        .eq('is_deleted', false)
        .order('event_date', ascending: false);
    return response.map((json) => fromJson(json)).toList();
  }
}
