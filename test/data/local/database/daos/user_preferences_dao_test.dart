import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/user_preferences_dao.dart';
import 'package:budgie_breeding_tracker/data/models/user_preference_model.dart';

void main() {
  late AppDatabase db;
  late UserPreferencesDao dao;

  const userId = 'user-1';
  const otherId = 'user-2';

  UserPreference makeEntry({
    String id = 'pref-1',
    String user = userId,
    String theme = 'dark',
    String language = 'tr',
    bool notificationsEnabled = true,
    bool compactView = false,
    bool emailNotifications = true,
    bool pushNotifications = true,
    String? customSettings,
  }) {
    return UserPreference(
      id: id,
      userId: user,
      theme: theme,
      language: language,
      notificationsEnabled: notificationsEnabled,
      compactView: compactView,
      emailNotifications: emailNotifications,
      pushNotifications: pushNotifications,
      customSettings: customSettings,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.userPreferencesDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('watchByUser', () {
    test('returns preferences for the user', () async {
      await dao.upsert(makeEntry(id: 'pref-1', user: userId));

      final result = await dao.watchByUser(userId).first;
      expect(result, isNotNull);
      expect(result!.id, equals('pref-1'));
      expect(result.theme, equals('dark'));
      expect(result.language, equals('tr'));
    });

    test('returns null when no preferences exist for the user', () async {
      final result = await dao.watchByUser(userId).first;
      expect(result, isNull);
    });

    test('does not return preferences for a different userId', () async {
      await dao.upsert(makeEntry(id: 'pref-1', user: otherId));

      final result = await dao.watchByUser(userId).first;
      expect(result, isNull);
    });

    test('returns updated preferences after upsert', () async {
      await dao.upsert(makeEntry(id: 'pref-1', theme: 'dark'));

      final initial = await dao.watchByUser(userId).first;
      expect(initial!.theme, equals('dark'));

      await dao.upsert(makeEntry(id: 'pref-1', theme: 'light'));

      final updated = await dao.watchByUser(userId).first;
      expect(updated!.theme, equals('light'));
    });
  });

  group('getByUser', () {
    test('returns preferences for the user', () async {
      await dao.upsert(makeEntry(id: 'pref-1', user: userId));

      final result = await dao.getByUser(userId);
      expect(result, isNotNull);
      expect(result!.id, equals('pref-1'));
      expect(result.notificationsEnabled, isTrue);
      expect(result.compactView, isFalse);
    });

    test('returns null when no preferences exist for the user', () async {
      final result = await dao.getByUser(userId);
      expect(result, isNull);
    });

    test('does not return preferences for a different userId', () async {
      await dao.upsert(makeEntry(id: 'pref-1', user: otherId));

      final result = await dao.getByUser(userId);
      expect(result, isNull);
    });
  });

  group('upsert', () {
    test('inserts new preferences', () async {
      await dao.upsert(makeEntry(id: 'pref-1'));

      final result = await dao.getByUser(userId);
      expect(result, isNotNull);
      expect(result!.theme, equals('dark'));
      expect(result.language, equals('tr'));
    });

    test('updates existing preferences on conflict', () async {
      await dao.upsert(makeEntry(id: 'pref-1', theme: 'dark'));
      await dao.upsert(makeEntry(id: 'pref-1', theme: 'light'));

      final result = await dao.getByUser(userId);
      expect(result, isNotNull);
      expect(result!.theme, equals('light'));
    });

    test('updates language field', () async {
      await dao.upsert(makeEntry(id: 'pref-1', language: 'tr'));
      await dao.upsert(makeEntry(id: 'pref-1', language: 'en'));

      final result = await dao.getByUser(userId);
      expect(result!.language, equals('en'));
    });

    test('updates notificationsEnabled field', () async {
      await dao.upsert(makeEntry(id: 'pref-1', notificationsEnabled: true));
      await dao.upsert(makeEntry(id: 'pref-1', notificationsEnabled: false));

      final result = await dao.getByUser(userId);
      expect(result!.notificationsEnabled, isFalse);
    });

    test('updates compactView field', () async {
      await dao.upsert(makeEntry(id: 'pref-1', compactView: false));
      await dao.upsert(makeEntry(id: 'pref-1', compactView: true));

      final result = await dao.getByUser(userId);
      expect(result!.compactView, isTrue);
    });

    test('handles multiple users independently', () async {
      await dao.upsert(makeEntry(id: 'pref-1', user: userId, theme: 'dark'));
      await dao.upsert(makeEntry(id: 'pref-2', user: otherId, theme: 'light'));

      final user1 = await dao.getByUser(userId);
      final user2 = await dao.getByUser(otherId);

      expect(user1!.theme, equals('dark'));
      expect(user2!.theme, equals('light'));
    });

    test('handles nullable customSettings field', () async {
      await dao.upsert(makeEntry(id: 'pref-1', customSettings: null));

      final result = await dao.getByUser(userId);
      expect(result, isNotNull);
      expect(result!.customSettings, isNull);

      await dao.upsert(
        makeEntry(id: 'pref-1', customSettings: '{"key":"value"}'),
      );

      final updated = await dao.getByUser(userId);
      expect(updated!.customSettings, equals('{"key":"value"}'));
    });
  });

  group('hardDelete', () {
    test('permanently removes the preferences', () async {
      await dao.upsert(makeEntry(id: 'pref-1'));

      await dao.hardDelete('pref-1');

      final result = await dao.getByUser(userId);
      expect(result, isNull);
    });

    test('does not affect other users preferences', () async {
      await dao.upsert(makeEntry(id: 'pref-1', user: userId));
      await dao.upsert(makeEntry(id: 'pref-2', user: otherId));

      await dao.hardDelete('pref-1');

      final userResult = await dao.getByUser(userId);
      expect(userResult, isNull);

      final otherResult = await dao.getByUser(otherId);
      expect(otherResult, isNotNull);
    });

    test('is a no-op when preferences do not exist', () async {
      await dao.hardDelete('non-existent');

      final result = await dao.getByUser(userId);
      expect(result, isNull);
    });
  });
}
