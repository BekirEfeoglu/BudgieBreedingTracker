import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/models/supabase_extensions.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/remote/api/base_remote_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel, PostgresChangeEvent, PostgresChangeFilter, PostgresChangeFilterType;

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

  // IMPROVED: realtime subscription for cross-device event sync
  /// Subscribes to insert/update/delete changes on the events table for a user.
  /// Returns a [RealtimeChannel] that must be removed via [unsubscribe] on dispose.
  RealtimeChannel subscribeToEvents(
    String userId,
    void Function(Event event) onUpsert,
    void Function(String deletedId) onDelete,
  ) {
    final channel = client.channel('events:$userId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConstants.eventsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              onUpsert(fromJson(payload.newRecord));
            } catch (e, st) {
              AppLogger.error('events-realtime-insert', e, st);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: SupabaseConstants.eventsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              onUpsert(fromJson(payload.newRecord));
            } catch (e, st) {
              AppLogger.error('events-realtime-update', e, st);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: SupabaseConstants.eventsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final id = payload.oldRecord['id'] as String?;
              if (id != null) onDelete(id);
            } catch (e, st) {
              AppLogger.error('events-realtime-delete', e, st);
            }
          },
        )
        .subscribe((status, error) {
      if (error != null) {
        AppLogger.warning(
          '[events:$userId] Realtime status: $status, error: $error',
        );
      }
    });
    return channel;
  }

  /// Removes a realtime channel subscription.
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }
}
