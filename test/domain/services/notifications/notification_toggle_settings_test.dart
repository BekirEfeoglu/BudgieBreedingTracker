import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/notifications/notification_toggle_settings.dart';

void main() {
  group('NotificationToggleSettings', () {
    test('defaults all toggles to enabled', () {
      const settings = NotificationToggleSettings();

      expect(settings.soundEnabled, isTrue);
      expect(settings.vibrationEnabled, isTrue);
      expect(settings.eggTurning, isTrue);
      expect(settings.incubation, isTrue);
      expect(settings.chickCare, isTrue);
      expect(settings.healthCheck, isTrue);
      expect(settings.banding, isTrue);
      expect(settings.cleanupDaysOld, 30);
    });

    test('copyWith updates selected fields and keeps others', () {
      const initial = NotificationToggleSettings(
        soundEnabled: true,
        vibrationEnabled: true,
        eggTurning: true,
        incubation: true,
        chickCare: true,
        healthCheck: true,
      );

      final updated = initial.copyWith(
        soundEnabled: false,
        incubation: false,
        cleanupDaysOld: 7,
      );

      expect(updated.soundEnabled, isFalse);
      expect(updated.incubation, isFalse);
      expect(updated.cleanupDaysOld, 7);
      expect(updated.vibrationEnabled, isTrue);
      expect(updated.eggTurning, isTrue);
      expect(updated.chickCare, isTrue);
      expect(updated.healthCheck, isTrue);
    });

    test('copyWith applies explicit false values', () {
      const initial = NotificationToggleSettings(
        soundEnabled: true,
        vibrationEnabled: true,
        eggTurning: true,
        incubation: true,
        chickCare: true,
        healthCheck: true,
      );

      final updated = initial.copyWith(
        vibrationEnabled: false,
        eggTurning: false,
        chickCare: false,
        healthCheck: false,
      );

      expect(updated.vibrationEnabled, isFalse);
      expect(updated.eggTurning, isFalse);
      expect(updated.chickCare, isFalse);
      expect(updated.healthCheck, isFalse);
      expect(updated.soundEnabled, isTrue);
      expect(updated.incubation, isTrue);
    });

    test('allEnabled returns false when banding is disabled', () {
      const settings = NotificationToggleSettings(banding: false);

      expect(settings.allEnabled, isFalse);
    });

    test('allEnabled returns true when all categories are enabled', () {
      const settings = NotificationToggleSettings();

      expect(settings.allEnabled, isTrue);
    });
  });
}
