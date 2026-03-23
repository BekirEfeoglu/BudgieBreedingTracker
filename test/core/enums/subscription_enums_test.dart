import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart';

void main() {
  group('SubscriptionStatus', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in SubscriptionStatus.values) {
        expect(SubscriptionStatus.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(
        SubscriptionStatus.fromJson('invalid'),
        SubscriptionStatus.unknown,
      );
      expect(SubscriptionStatus.fromJson(''), SubscriptionStatus.unknown);
      expect(SubscriptionStatus.fromJson('pro'), SubscriptionStatus.unknown);
    });

    test('has expected value count', () {
      expect(SubscriptionStatus.values.length, 4);
    });
  });

  group('BackupFrequency', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in BackupFrequency.values) {
        expect(BackupFrequency.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(BackupFrequency.fromJson('invalid'), BackupFrequency.unknown);
      expect(BackupFrequency.fromJson(''), BackupFrequency.unknown);
      expect(BackupFrequency.fromJson('hourly'), BackupFrequency.unknown);
    });

    test('has expected value count', () {
      expect(BackupFrequency.values.length, 5);
    });
  });

  group('GracePeriodStatus', () {
    test('toJson returns name', () {
      expect(GracePeriodStatus.active.toJson(), 'active');
      expect(GracePeriodStatus.gracePeriod.toJson(), 'gracePeriod');
      expect(GracePeriodStatus.unknown.toJson(), 'unknown');
    });

    test('fromJson parses valid values', () {
      expect(GracePeriodStatus.fromJson('active'), GracePeriodStatus.active);
      expect(GracePeriodStatus.fromJson('gracePeriod'), GracePeriodStatus.gracePeriod);
      expect(GracePeriodStatus.fromJson('expired'), GracePeriodStatus.expired);
      expect(GracePeriodStatus.fromJson('free'), GracePeriodStatus.free);
    });

    test('fromJson returns unknown for invalid value', () {
      expect(GracePeriodStatus.fromJson('invalid'), GracePeriodStatus.unknown);
      expect(GracePeriodStatus.fromJson(''), GracePeriodStatus.unknown);
    });

    test('toJson/fromJson round-trip for all values', () {
      for (final value in GracePeriodStatus.values) {
        expect(GracePeriodStatus.fromJson(value.toJson()), value);
      }
    });

    test('has expected value count', () {
      expect(GracePeriodStatus.values.length, 5);
    });
  });
}
