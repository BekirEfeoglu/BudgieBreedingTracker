import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/notification_settings_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';

void main() {
  group('NotificationSettingsRowMapper.toModel()', () {
    test('maps all fields correctly', () {
      const row = NotificationSettingsRow(
        id: 'ns1',
        userId: 'u1',
        language: 'en',
        soundEnabled: false,
        vibrationEnabled: true,
        eggTurningEnabled: true,
        temperatureAlertEnabled: false,
        humidityAlertEnabled: true,
        feedingReminderEnabled: false,
        incubationReminderEnabled: true,
        healthCheckEnabled: true,
        bandingEnabled: true,
        temperatureMin: 36.5,
        temperatureMax: 38.5,
        humidityMin: 50.0,
        humidityMax: 70.0,
        eggTurningIntervalMinutes: 360,
        feedingReminderIntervalMinutes: 720,
        temperatureCheckIntervalMinutes: 45,
        cleanupDaysOld: 30,
      );
      final model = row.toModel();

      expect(model.id, 'ns1');
      expect(model.userId, 'u1');
      expect(model.language, 'en');
      expect(model.soundEnabled, false);
      expect(model.vibrationEnabled, true);
      expect(model.eggTurningEnabled, true);
      expect(model.temperatureAlertEnabled, false);
      expect(model.temperatureMin, 36.5);
      expect(model.temperatureMax, 38.5);
      expect(model.humidityMin, 50.0);
      expect(model.humidityMax, 70.0);
      expect(model.eggTurningIntervalMinutes, 360);
      expect(model.feedingReminderIntervalMinutes, 720);
      expect(model.temperatureCheckIntervalMinutes, 45);
    });
  });

  group('NotificationSettingsModelMapper.toCompanion()', () {
    test('wraps all fields in Value', () {
      const model = NotificationSettings(
        id: 'ns1',
        userId: 'u1',
        language: 'de',
        soundEnabled: false,
        temperatureMin: 37.0,
        temperatureMax: 38.0,
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'ns1');
      expect(companion.userId.value, 'u1');
      expect(companion.language.value, 'de');
      expect(companion.soundEnabled.value, false);
      expect(companion.temperatureMin.value, 37.0);
      expect(companion.temperatureMax.value, 38.0);
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      const model = NotificationSettings(id: 'ns1', userId: 'u1');
      final companion = model.toCompanion();

      expect(
        companion.updatedAt.value!.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });
  });
}
