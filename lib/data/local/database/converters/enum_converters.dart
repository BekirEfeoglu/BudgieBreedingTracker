import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/photo_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/reminder_enums.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';

/// Generic type converter for storing enums as TEXT in SQLite.
class EnumConverter<T extends Enum> extends TypeConverter<T, String> {
  final List<T> values;
  final T fallback;

  const EnumConverter(this.values, this.fallback);

  @override
  T fromSql(String fromDb) {
    try {
      return values.byName(fromDb);
    } catch (_) {
      return fallback;
    }
  }

  @override
  String toSql(T value) => value.name;
}

// Bird enums
const birdGenderConverter = EnumConverter<BirdGender>(
  BirdGender.values,
  BirdGender.unknown,
);
const birdStatusConverter = EnumConverter<BirdStatus>(
  BirdStatus.values,
  BirdStatus.unknown,
);
const speciesConverter = _SpeciesConverter();

/// Custom converter for [Species] that handles backward-compat aliases
/// (muhabbet→budgie, kanarya→canary, ispinoz→finch).
class _SpeciesConverter extends TypeConverter<Species, String> {
  const _SpeciesConverter();

  @override
  Species fromSql(String fromDb) => Species.fromJson(fromDb);

  @override
  String toSql(Species value) => value.toJson();
}

const birdColorConverter = EnumConverter<BirdColor>(
  BirdColor.values,
  BirdColor.unknown,
);

// Egg enums
const eggStatusConverter = EnumConverter<EggStatus>(
  EggStatus.values,
  EggStatus.laid,
);

// Breeding enums
const breedingStatusConverter = EnumConverter<BreedingStatus>(
  BreedingStatus.values,
  BreedingStatus.active,
);
const incubationStatusConverter = EnumConverter<IncubationStatus>(
  IncubationStatus.values,
  IncubationStatus.active,
);
const nestStatusConverter = EnumConverter<NestStatus>(
  NestStatus.values,
  NestStatus.available,
);

// Chick enums
const chickHealthStatusConverter = EnumConverter<ChickHealthStatus>(
  ChickHealthStatus.values,
  ChickHealthStatus.healthy,
);

// Event enums
const eventTypeConverter = EnumConverter<EventType>(
  EventType.values,
  EventType.custom,
);
const eventStatusConverter = EnumConverter<EventStatus>(
  EventStatus.values,
  EventStatus.active,
);

// Notification enums
const notificationTypeConverter = EnumConverter<NotificationType>(
  NotificationType.values,
  NotificationType.custom,
);
const notificationPriorityConverter = EnumConverter<NotificationPriority>(
  NotificationPriority.values,
  NotificationPriority.normal,
);

// Subscription enums
const subscriptionStatusConverter = EnumConverter<SubscriptionStatus>(
  SubscriptionStatus.values,
  SubscriptionStatus.free,
);

// Health record enums
const healthRecordTypeConverter = EnumConverter<HealthRecordType>(
  HealthRecordType.values,
  HealthRecordType.unknown,
);

// Photo enums
const photoEntityTypeConverter = EnumConverter<PhotoEntityType>(
  PhotoEntityType.values,
  PhotoEntityType.bird,
);

// Reminder enums
const reminderTypeConverter = EnumConverter<ReminderType>(
  ReminderType.values,
  ReminderType.notification,
);

// Sync enums
const syncStatusConverter = EnumConverter<SyncStatus>(
  SyncStatus.values,
  SyncStatus.pending,
);

const conflictTypeConverter = EnumConverter<ConflictType>(
  ConflictType.values,
  ConflictType.unknown,
);
