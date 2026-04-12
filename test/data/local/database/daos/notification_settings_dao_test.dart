import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/notification_settings_dao.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';

void main() {
  late AppDatabase db;
  late NotificationSettingsDao dao;

  const userId = 'user-1';
  const otherId = 'user-2';

  NotificationSettings makeEntry({
    String id = 'ns-1',
    String user = userId,
    String language = 'tr',
    bool soundEnabled = true,
    bool vibrationEnabled = true,
  }) {
    return NotificationSettings(
      id: id,
      userId: user,
      language: language,
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.notificationSettingsDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('watchByUser', () {
    test('returns settings for the user', () async {
      await dao.upsert(makeEntry(id: 'ns-1', user: userId));

      final result = await dao.watchByUser(userId).first;
      expect(result, isNotNull);
      expect(result!.id, equals('ns-1'));
      expect(result.language, equals('tr'));
    });

    test('returns null when no settings exist for the user', () async {
      final result = await dao.watchByUser(userId).first;
      expect(result, isNull);
    });

    test('does not return settings for a different userId', () async {
      await dao.upsert(makeEntry(id: 'ns-1', user: otherId));

      final result = await dao.watchByUser(userId).first;
      expect(result, isNull);
    });

    test('returns updated settings after upsert', () async {
      await dao.upsert(makeEntry(id: 'ns-1', language: 'tr'));

      final initial = await dao.watchByUser(userId).first;
      expect(initial!.language, equals('tr'));

      await dao.upsert(makeEntry(id: 'ns-1', language: 'en'));

      final updated = await dao.watchByUser(userId).first;
      expect(updated!.language, equals('en'));
    });
  });

  group('getByUser', () {
    test('returns settings for the user', () async {
      await dao.upsert(makeEntry(id: 'ns-1', user: userId));

      final result = await dao.getByUser(userId);
      expect(result, isNotNull);
      expect(result!.id, equals('ns-1'));
      expect(result.soundEnabled, isTrue);
      expect(result.vibrationEnabled, isTrue);
    });

    test('returns null when no settings exist for the user', () async {
      final result = await dao.getByUser(userId);
      expect(result, isNull);
    });

    test('does not return settings for a different userId', () async {
      await dao.upsert(makeEntry(id: 'ns-1', user: otherId));

      final result = await dao.getByUser(userId);
      expect(result, isNull);
    });
  });

  group('upsert', () {
    test('inserts new settings', () async {
      await dao.upsert(makeEntry(id: 'ns-1'));

      final result = await dao.getByUser(userId);
      expect(result, isNotNull);
      expect(result!.language, equals('tr'));
    });

    test('updates existing settings on conflict', () async {
      await dao.upsert(makeEntry(id: 'ns-1', language: 'tr'));
      await dao.upsert(makeEntry(id: 'ns-1', language: 'en'));

      final result = await dao.getByUser(userId);
      expect(result, isNotNull);
      expect(result!.language, equals('en'));
    });

    test('updates soundEnabled field', () async {
      await dao.upsert(makeEntry(id: 'ns-1', soundEnabled: true));
      await dao.upsert(makeEntry(id: 'ns-1', soundEnabled: false));

      final result = await dao.getByUser(userId);
      expect(result!.soundEnabled, isFalse);
    });

    test('updates vibrationEnabled field', () async {
      await dao.upsert(makeEntry(id: 'ns-1', vibrationEnabled: true));
      await dao.upsert(makeEntry(id: 'ns-1', vibrationEnabled: false));

      final result = await dao.getByUser(userId);
      expect(result!.vibrationEnabled, isFalse);
    });

    test('handles multiple users independently', () async {
      await dao.upsert(makeEntry(id: 'ns-1', user: userId, language: 'tr'));
      await dao.upsert(makeEntry(id: 'ns-2', user: otherId, language: 'de'));

      final user1 = await dao.getByUser(userId);
      final user2 = await dao.getByUser(otherId);

      expect(user1!.language, equals('tr'));
      expect(user2!.language, equals('de'));
    });
  });

  group('hardDelete', () {
    test('permanently removes the settings', () async {
      await dao.upsert(makeEntry(id: 'ns-1'));

      await dao.hardDelete('ns-1');

      final result = await dao.getByUser(userId);
      expect(result, isNull);
    });

    test('does not affect other users settings', () async {
      await dao.upsert(makeEntry(id: 'ns-1', user: userId));
      await dao.upsert(makeEntry(id: 'ns-2', user: otherId));

      await dao.hardDelete('ns-1');

      final userResult = await dao.getByUser(userId);
      expect(userResult, isNull);

      final otherResult = await dao.getByUser(otherId);
      expect(otherResult, isNotNull);
    });

    test('is a no-op when settings do not exist', () async {
      await dao.hardDelete('non-existent');

      final result = await dao.getByUser(userId);
      expect(result, isNull);
    });
  });
}
