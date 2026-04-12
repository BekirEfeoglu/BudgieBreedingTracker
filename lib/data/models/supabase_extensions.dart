import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/nest_model.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';
import 'package:budgie_breeding_tracker/data/models/event_reminder_model.dart';
import 'package:budgie_breeding_tracker/data/models/notification_schedule_model.dart';

/// Strips server-managed timestamp fields before sending to Supabase.
Map<String, dynamic> _stripServerFields(Map<String, dynamic> json) {
  json.remove('created_at');
  json.remove('updated_at');
  return json;
}

/// Supabase JSON conversion extensions for all models.
extension BirdSupabase on Bird {
  Map<String, dynamic> toSupabase() => _stripServerFields(toJson());
}

extension EggSupabase on Egg {
  Map<String, dynamic> toSupabase() => _stripServerFields(toJson());
}

extension ChickSupabase on Chick {
  Map<String, dynamic> toSupabase() => _stripServerFields(toJson());
}

extension IncubationSupabase on Incubation {
  Map<String, dynamic> toSupabase() => _stripServerFields(toJson());
}

extension BreedingPairSupabase on BreedingPair {
  Map<String, dynamic> toSupabase() => _stripServerFields(toJson());
}

extension HealthRecordSupabase on HealthRecord {
  Map<String, dynamic> toSupabase() => _stripServerFields(toJson());
}

extension GrowthMeasurementSupabase on GrowthMeasurement {
  Map<String, dynamic> toSupabase() => _stripServerFields(toJson());
}

extension EventSupabase on Event {
  Map<String, dynamic> toSupabase() => _stripServerFields(toJson());
}

extension AppNotificationSupabase on AppNotification {
  Map<String, dynamic> toSupabase() => _stripServerFields(toJson());
}

extension ProfileSupabase on Profile {
  Map<String, dynamic> toSupabase() => _stripServerFields(toJson());
}

extension ClutchSupabase on Clutch {
  Map<String, dynamic> toSupabase() {
    final json = _stripServerFields(toJson());
    // Rename to match Supabase column
    if (json.containsKey('breeding_id')) {
      json['breeding_pair_id'] = json.remove('breeding_id');
    }
    // Strip local-only fields not in Supabase
    json
      ..remove('name')
      ..remove('incubation_id')
      ..remove('male_bird_id')
      ..remove('female_bird_id')
      ..remove('nest_id')
      ..remove('pair_date');
    return json;
  }
}

extension NestSupabase on Nest {
  Map<String, dynamic> toSupabase() => _stripServerFields(toJson());
}

extension PhotoSupabase on Photo {
  Map<String, dynamic> toSupabase() {
    final json = _stripServerFields(toJson());
    // Rename to match Supabase columns
    if (json.containsKey('file_name')) {
      json['url'] = json.remove('file_name');
    }
    if (json.containsKey('file_path')) {
      json['thumbnail_url'] = json.remove('file_path');
    }
    // Strip local-only fields
    json.remove('is_primary');
    return json;
  }
}

extension EventReminderSupabase on EventReminder {
  Map<String, dynamic> toSupabase() {
    final json = _stripServerFields(toJson());
    // Rename to match Supabase column
    if (json.containsKey('type')) {
      json['reminder_type'] = json.remove('type');
    }
    return json;
  }
}

extension NotificationScheduleSupabase on NotificationSchedule {
  Map<String, dynamic> toSupabase() {
    final json = _stripServerFields(toJson());
    // Rename to match Supabase columns
    if (json.containsKey('message')) {
      json['body'] = json.remove('message');
    }
    if (json.containsKey('interval_minutes')) {
      json['repeat_interval_minutes'] = json.remove('interval_minutes');
    }
    if (json.containsKey('related_entity_id')) {
      json['entity_id'] = json.remove('related_entity_id');
    }
    // Strip local-only fields
    json
      ..remove('is_recurring')
      ..remove('priority')
      ..remove('processed_at');
    return json;
  }
}

// Community models use custom serialization (not standard toJson)
// because they have fields populated from joins (username, avatarUrl, etc.)
// See CommunityPostRemoteSource for the serialization logic.
