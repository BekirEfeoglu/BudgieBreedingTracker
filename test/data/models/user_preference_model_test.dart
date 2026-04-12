import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/models/user_preference_model.dart';

UserPreference _buildPreference({
  String id = 'pref-1',
  String userId = 'user-1',
  String theme = 'system',
  String language = 'tr',
  bool notificationsEnabled = true,
  bool compactView = false,
  bool emailNotifications = true,
  bool pushNotifications = true,
  String? customSettings,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return UserPreference(
    id: id,
    userId: userId,
    theme: theme,
    language: language,
    notificationsEnabled: notificationsEnabled,
    compactView: compactView,
    emailNotifications: emailNotifications,
    pushNotifications: pushNotifications,
    customSettings: customSettings,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

void main() {
  group('UserPreference model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final preference = _buildPreference(
          id: 'pref-42',
          userId: 'user-42',
          theme: 'dark',
          language: 'en',
          notificationsEnabled: false,
          compactView: true,
          emailNotifications: false,
          pushNotifications: true,
          customSettings: '{"fontScale":1.2}',
          createdAt: DateTime(2024, 1, 1, 8, 0),
          updatedAt: DateTime(2024, 1, 1, 9, 0),
        );

        final restored = UserPreference.fromJson(preference.toJson());
        expect(restored, preference);
      });

      test('applies default values', () {
        final preference = UserPreference.fromJson({
          'id': 'pref-1',
          'user_id': 'user-1',
        });

        expect(preference.theme, 'system');
        expect(preference.language, 'tr');
        expect(preference.notificationsEnabled, isTrue);
        expect(preference.compactView, isFalse);
        expect(preference.emailNotifications, isTrue);
        expect(preference.pushNotifications, isTrue);
      });
    });

    group('copyWith', () {
      test('updates selected fields', () {
        final preference = _buildPreference(theme: 'light', language: 'tr');
        final updated = preference.copyWith(theme: 'dark', language: 'de');

        expect(updated.theme, 'dark');
        expect(updated.language, 'de');
        expect(updated.id, preference.id);
        expect(updated.userId, preference.userId);
      });
    });
  });
}
