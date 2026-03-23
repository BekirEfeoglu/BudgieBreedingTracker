import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/photo_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/reminder_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/converters/enum_converters.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';

void main() {
  group('EnumConverter generic', () {
    test('round-trips all BirdGender values', () {
      for (final value in BirdGender.values) {
        final sql = birdGenderConverter.toSql(value);
        final dart = birdGenderConverter.fromSql(sql);
        expect(dart, value);
      }
    });

    test('returns fallback for unknown SQL value', () {
      final result = birdGenderConverter.fromSql('nonexistent');
      expect(result, BirdGender.unknown);
    });

    test('toSql returns enum name', () {
      expect(birdGenderConverter.toSql(BirdGender.male), 'male');
      expect(birdGenderConverter.toSql(BirdGender.female), 'female');
      expect(birdGenderConverter.toSql(BirdGender.unknown), 'unknown');
    });
  });

  group('birdStatusConverter', () {
    test('round-trips all values', () {
      for (final value in BirdStatus.values) {
        final sql = birdStatusConverter.toSql(value);
        final dart = birdStatusConverter.fromSql(sql);
        expect(dart, value);
      }
    });

    test('returns fallback for unknown value', () {
      expect(birdStatusConverter.fromSql('extinct'), BirdStatus.unknown);
    });
  });

  group('speciesConverter', () {
    test('round-trips all Species values', () {
      for (final value in Species.values) {
        final sql = speciesConverter.toSql(value);
        final dart = speciesConverter.fromSql(sql);
        expect(dart, value);
      }
    });

    test('handles backward-compat aliases', () {
      expect(speciesConverter.fromSql('muhabbet'), Species.budgie);
      expect(speciesConverter.fromSql('kanarya'), Species.canary);
      expect(speciesConverter.fromSql('ispinoz'), Species.finch);
    });

    test('returns unknown for unrecognized species', () {
      expect(speciesConverter.fromSql('parrot'), Species.unknown);
    });

    test('toSql uses modern names', () {
      expect(speciesConverter.toSql(Species.budgie), 'budgie');
      expect(speciesConverter.toSql(Species.canary), 'canary');
      expect(speciesConverter.toSql(Species.finch), 'finch');
    });
  });

  group('birdColorConverter', () {
    test('round-trips all values', () {
      for (final value in BirdColor.values) {
        final sql = birdColorConverter.toSql(value);
        final dart = birdColorConverter.fromSql(sql);
        expect(dart, value);
      }
    });

    test('returns fallback for unknown value', () {
      expect(birdColorConverter.fromSql('rainbow'), BirdColor.unknown);
    });
  });

  group('eggStatusConverter', () {
    test('round-trips all values', () {
      for (final value in EggStatus.values) {
        final sql = eggStatusConverter.toSql(value);
        final dart = eggStatusConverter.fromSql(sql);
        expect(dart, value);
      }
    });

    test('returns fallback for unknown value', () {
      expect(eggStatusConverter.fromSql('cracked'), EggStatus.laid);
    });
  });

  group('breedingStatusConverter', () {
    test('round-trips all values', () {
      for (final value in BreedingStatus.values) {
        final sql = breedingStatusConverter.toSql(value);
        final dart = breedingStatusConverter.fromSql(sql);
        expect(dart, value);
      }
    });

    test('returns fallback for unknown value', () {
      expect(
        breedingStatusConverter.fromSql('paused'),
        BreedingStatus.active,
      );
    });
  });

  group('incubationStatusConverter', () {
    test('round-trips all values', () {
      for (final value in IncubationStatus.values) {
        final sql = incubationStatusConverter.toSql(value);
        final dart = incubationStatusConverter.fromSql(sql);
        expect(dart, value);
      }
    });

    test('returns fallback for unknown value', () {
      expect(
        incubationStatusConverter.fromSql('paused'),
        IncubationStatus.active,
      );
    });
  });

  group('nestStatusConverter', () {
    test('round-trips all values', () {
      for (final value in NestStatus.values) {
        final sql = nestStatusConverter.toSql(value);
        final dart = nestStatusConverter.fromSql(sql);
        expect(dart, value);
      }
    });

    test('returns fallback for unknown value', () {
      expect(nestStatusConverter.fromSql('destroyed'), NestStatus.available);
    });
  });

  group('chickHealthStatusConverter', () {
    test('round-trips all values', () {
      for (final value in ChickHealthStatus.values) {
        final sql = chickHealthStatusConverter.toSql(value);
        final dart = chickHealthStatusConverter.fromSql(sql);
        expect(dart, value);
      }
    });

    test('returns fallback for unknown value', () {
      expect(
        chickHealthStatusConverter.fromSql('recovering'),
        ChickHealthStatus.healthy,
      );
    });
  });

  group('eventTypeConverter', () {
    test('round-trips all values', () {
      for (final value in EventType.values) {
        final sql = eventTypeConverter.toSql(value);
        final dart = eventTypeConverter.fromSql(sql);
        expect(dart, value);
      }
    });

    test('returns fallback for unknown value', () {
      expect(eventTypeConverter.fromSql('swimming'), EventType.custom);
    });
  });

  group('eventStatusConverter', () {
    test('round-trips all values', () {
      for (final value in EventStatus.values) {
        final sql = eventStatusConverter.toSql(value);
        final dart = eventStatusConverter.fromSql(sql);
        expect(dart, value);
      }
    });

    test('returns fallback for unknown value', () {
      expect(eventStatusConverter.fromSql('archived'), EventStatus.active);
    });
  });

  group('notificationTypeConverter', () {
    test('round-trips all values', () {
      for (final value in NotificationType.values) {
        final sql = notificationTypeConverter.toSql(value);
        final dart = notificationTypeConverter.fromSql(sql);
        expect(dart, value);
      }
    });

    test('returns fallback for unknown value', () {
      expect(
        notificationTypeConverter.fromSql('sms'),
        NotificationType.custom,
      );
    });
  });

  group('notificationPriorityConverter', () {
    test('round-trips all values', () {
      for (final value in NotificationPriority.values) {
        final sql = notificationPriorityConverter.toSql(value);
        final dart = notificationPriorityConverter.fromSql(sql);
        expect(dart, value);
      }
    });

    test('returns fallback for unknown value', () {
      expect(
        notificationPriorityConverter.fromSql('extreme'),
        NotificationPriority.normal,
      );
    });
  });

  group('subscriptionStatusConverter', () {
    test('round-trips all values', () {
      for (final value in SubscriptionStatus.values) {
        final sql = subscriptionStatusConverter.toSql(value);
        final dart = subscriptionStatusConverter.fromSql(sql);
        expect(dart, value);
      }
    });

    test('returns fallback for unknown value', () {
      expect(
        subscriptionStatusConverter.fromSql('enterprise'),
        SubscriptionStatus.free,
      );
    });
  });

  group('healthRecordTypeConverter', () {
    test('round-trips all values', () {
      for (final value in HealthRecordType.values) {
        final sql = healthRecordTypeConverter.toSql(value);
        final dart = healthRecordTypeConverter.fromSql(sql);
        expect(dart, value);
      }
    });

    test('returns fallback for unknown value', () {
      expect(
        healthRecordTypeConverter.fromSql('surgery'),
        HealthRecordType.unknown,
      );
    });
  });

  group('photoEntityTypeConverter', () {
    test('round-trips all values', () {
      for (final value in PhotoEntityType.values) {
        final sql = photoEntityTypeConverter.toSql(value);
        final dart = photoEntityTypeConverter.fromSql(sql);
        expect(dart, value);
      }
    });

    test('returns fallback for unknown value', () {
      expect(
        photoEntityTypeConverter.fromSql('cage'),
        PhotoEntityType.bird,
      );
    });
  });

  group('reminderTypeConverter', () {
    test('round-trips all values', () {
      for (final value in ReminderType.values) {
        final sql = reminderTypeConverter.toSql(value);
        final dart = reminderTypeConverter.fromSql(sql);
        expect(dart, value);
      }
    });

    test('returns fallback for unknown value', () {
      expect(
        reminderTypeConverter.fromSql('sms'),
        ReminderType.notification,
      );
    });
  });

  group('syncStatusConverter', () {
    test('round-trips all values', () {
      for (final value in SyncStatus.values) {
        final sql = syncStatusConverter.toSql(value);
        final dart = syncStatusConverter.fromSql(sql);
        expect(dart, value);
      }
    });

    test('returns fallback for unknown value', () {
      expect(syncStatusConverter.fromSql('cancelled'), SyncStatus.pending);
    });
  });
}
