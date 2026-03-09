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
}
