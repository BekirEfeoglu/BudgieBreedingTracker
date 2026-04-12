import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/user_preference_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/user_preference_model.dart';

void main() {
  group('UserPreferenceRowMapper.toModel()', () {
    test('maps all fields correctly', () {
      final row = UserPreferenceRow(
        id: 'up1',
        userId: 'u1',
        theme: 'dark',
        language: 'en',
        notificationsEnabled: false,
        compactView: true,
        emailNotifications: false,
        pushNotifications: true,
        customSettings: '{"key":"value"}',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );
      final model = row.toModel();

      expect(model.id, 'up1');
      expect(model.userId, 'u1');
      expect(model.theme, 'dark');
      expect(model.language, 'en');
      expect(model.notificationsEnabled, false);
      expect(model.compactView, true);
      expect(model.emailNotifications, false);
      expect(model.pushNotifications, true);
      expect(model.customSettings, '{"key":"value"}');
    });

    test('handles null customSettings', () {
      const row = UserPreferenceRow(
        id: 'up2',
        userId: 'u1',
        theme: 'system',
        language: 'tr',
        notificationsEnabled: true,
        compactView: false,
        emailNotifications: true,
        pushNotifications: true,
        customSettings: null,
      );
      final model = row.toModel();

      expect(model.customSettings, isNull);
    });
  });

  group('UserPreferenceModelMapper.toCompanion()', () {
    test('wraps all fields in Value', () {
      const model = UserPreference(
        id: 'up1',
        userId: 'u1',
        theme: 'light',
        language: 'de',
        notificationsEnabled: true,
        compactView: true,
        emailNotifications: false,
        pushNotifications: false,
        customSettings: '{}',
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'up1');
      expect(companion.userId.value, 'u1');
      expect(companion.theme.value, 'light');
      expect(companion.language.value, 'de');
      expect(companion.notificationsEnabled.value, true);
      expect(companion.compactView.value, true);
      expect(companion.emailNotifications.value, false);
      expect(companion.pushNotifications.value, false);
      expect(companion.customSettings.value, '{}');
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      const model = UserPreference(id: 'up1', userId: 'u1');
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
