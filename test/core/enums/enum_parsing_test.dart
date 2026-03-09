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

void main() {
  group('Bird enums', () {
    test('BirdGender toJson/fromJson supports all values', () {
      for (final value in BirdGender.values) {
        expect(BirdGender.fromJson(value.toJson()), value);
      }
    });

    test('BirdStatus parses valid values and falls back to unknown', () {
      expect(BirdStatus.fromJson('alive'), BirdStatus.alive);
      expect(BirdStatus.fromJson('dead'), BirdStatus.dead);
      expect(BirdStatus.fromJson('sold'), BirdStatus.sold);
      expect(BirdStatus.fromJson('invalid'), BirdStatus.unknown);
    });

    test('Species parses all supported aliases', () {
      expect(Species.fromJson('budgie'), Species.budgie);
      expect(Species.fromJson('muhabbet'), Species.budgie);
      expect(Species.fromJson('canary'), Species.canary);
      expect(Species.fromJson('kanarya'), Species.canary);
      expect(Species.fromJson('finch'), Species.finch);
      expect(Species.fromJson('ispinoz'), Species.finch);
      expect(Species.fromJson('other'), Species.other);
      expect(Species.fromJson('invalid'), Species.unknown);
    });

    test('BirdColor parses all values and falls back to unknown', () {
      for (final value in BirdColor.values) {
        expect(BirdColor.fromJson(value.toJson()), value);
      }
      expect(BirdColor.fromJson('invalid'), BirdColor.unknown);
    });
  });

  group('Breeding and incubation enums', () {
    test('EggStatus toJson/fromJson supports all 9 values', () {
      expect(EggStatus.values.length, 9);
      for (final value in EggStatus.values) {
        expect(EggStatus.fromJson(value.toJson()), value);
      }
    });

    test('BreedingStatus falls back to unknown on invalid input', () {
      expect(BreedingStatus.fromJson('active'), BreedingStatus.active);
      expect(BreedingStatus.fromJson('ongoing'), BreedingStatus.ongoing);
      expect(BreedingStatus.fromJson('completed'), BreedingStatus.completed);
      expect(BreedingStatus.fromJson('cancelled'), BreedingStatus.cancelled);
      expect(BreedingStatus.fromJson('invalid'), BreedingStatus.unknown);
    });

    test('IncubationStatus falls back to unknown on invalid input', () {
      expect(IncubationStatus.fromJson('active'), IncubationStatus.active);
      expect(
        IncubationStatus.fromJson('completed'),
        IncubationStatus.completed,
      );
      expect(
        IncubationStatus.fromJson('cancelled'),
        IncubationStatus.cancelled,
      );
      expect(IncubationStatus.fromJson('invalid'), IncubationStatus.unknown);
    });
  });

  group('Chick enums', () {
    test('ChickHealthStatus toJson/fromJson supports all values', () {
      expect(ChickHealthStatus.values.length, 4);
      for (final value in ChickHealthStatus.values) {
        expect(ChickHealthStatus.fromJson(value.toJson()), value);
      }
    });

    test(
      'DevelopmentStage toJson/fromJson supports all values and fallback',
      () {
        expect(DevelopmentStage.values.length, greaterThanOrEqualTo(4));
        for (final value in DevelopmentStage.values) {
          expect(DevelopmentStage.fromJson(value.toJson()), value);
        }
        expect(DevelopmentStage.fromJson('invalid'), DevelopmentStage.unknown);
      },
    );
  });

  group('Notification enums', () {
    test('NotificationType parses valid values and falls back', () {
      for (final value in NotificationType.values) {
        expect(NotificationType.fromJson(value.toJson()), value);
      }
      expect(NotificationType.fromJson('invalid'), NotificationType.unknown);
    });

    test('NotificationPriority parses valid values and falls back', () {
      for (final value in NotificationPriority.values) {
        expect(NotificationPriority.fromJson(value.toJson()), value);
      }
      expect(
        NotificationPriority.fromJson('invalid'),
        NotificationPriority.unknown,
      );
    });
  });

  group('Event enums', () {
    test('EventType parses valid values and falls back', () {
      for (final value in EventType.values) {
        expect(EventType.fromJson(value.toJson()), value);
      }
      expect(EventType.fromJson('invalid'), EventType.unknown);
    });

    test('EventStatus parses valid values and falls back', () {
      for (final value in EventStatus.values) {
        expect(EventStatus.fromJson(value.toJson()), value);
      }
      expect(EventStatus.fromJson('invalid'), EventStatus.unknown);
    });
  });

  group('Photo, reminder and subscription enums', () {
    test('PhotoEntityType parses valid values and falls back', () {
      for (final value in PhotoEntityType.values) {
        expect(PhotoEntityType.fromJson(value.toJson()), value);
      }
      expect(PhotoEntityType.fromJson('invalid'), PhotoEntityType.unknown);
    });

    test('ReminderType parses valid values and falls back', () {
      for (final value in ReminderType.values) {
        expect(ReminderType.fromJson(value.toJson()), value);
      }
      expect(ReminderType.fromJson('invalid'), ReminderType.unknown);
    });

    test(
      'SubscriptionStatus and BackupFrequency parse valid values and fallback',
      () {
        for (final value in SubscriptionStatus.values) {
          expect(SubscriptionStatus.fromJson(value.toJson()), value);
        }
        for (final value in BackupFrequency.values) {
          expect(BackupFrequency.fromJson(value.toJson()), value);
        }
        expect(
          SubscriptionStatus.fromJson('invalid'),
          SubscriptionStatus.unknown,
        );
        expect(BackupFrequency.fromJson('invalid'), BackupFrequency.unknown);
      },
    );
  });
}
