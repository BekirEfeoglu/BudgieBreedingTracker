import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/profiles_dao.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';

void main() {
  late AppDatabase db;
  late ProfilesDao dao;

  const userId = 'user-1';
  const otherId = 'user-2';

  Profile makeEntry({
    String id = 'user-1',
    String email = 'test@test.com',
    String? fullName = 'Test User',
    String? avatarUrl,
    String? role,
  }) {
    return Profile(
      id: id,
      email: email,
      fullName: fullName,
      avatarUrl: avatarUrl,
      role: role,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.profilesDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('watchProfile', () {
    test('returns the profile when it exists', () async {
      await dao.upsert(makeEntry(id: userId));

      final result = await dao.watchProfile(userId).first;
      expect(result, isNotNull);
      expect(result!.id, equals(userId));
      expect(result.email, equals('test@test.com'));
      expect(result.fullName, equals('Test User'));
    });

    test('returns null when profile does not exist', () async {
      final result = await dao.watchProfile('non-existent').first;
      expect(result, isNull);
    });

    test('does not return a different user profile', () async {
      await dao.upsert(makeEntry(id: otherId, email: 'other@test.com'));

      final result = await dao.watchProfile(userId).first;
      expect(result, isNull);
    });

    test('reflects updates after upsert', () async {
      await dao.upsert(makeEntry(id: userId, fullName: 'Original'));

      final first = await dao.watchProfile(userId).first;
      expect(first!.fullName, equals('Original'));

      await dao.upsert(makeEntry(id: userId, fullName: 'Updated'));

      final updated = await dao.watchProfile(userId).first;
      expect(updated!.fullName, equals('Updated'));
    });
  });

  group('getById', () {
    test('returns the profile when it exists', () async {
      await dao.upsert(makeEntry(id: userId));

      final result = await dao.getById(userId);
      expect(result, isNotNull);
      expect(result!.id, equals(userId));
      expect(result.email, equals('test@test.com'));
    });

    test('returns null when profile does not exist', () async {
      final result = await dao.getById('non-existent');
      expect(result, isNull);
    });

    test('returns correct profile among multiple', () async {
      await dao.upsert(makeEntry(id: userId, email: 'user1@test.com'));
      await dao.upsert(makeEntry(id: otherId, email: 'user2@test.com'));

      final result = await dao.getById(userId);
      expect(result, isNotNull);
      expect(result!.email, equals('user1@test.com'));
    });
  });

  group('upsert', () {
    test('inserts a new profile', () async {
      await dao.upsert(makeEntry(id: userId));

      final result = await dao.getById(userId);
      expect(result, isNotNull);
      expect(result!.id, equals(userId));
    });

    test('updates an existing profile on conflict', () async {
      await dao.upsert(makeEntry(id: userId, fullName: 'Original'));
      await dao.upsert(makeEntry(id: userId, fullName: 'Updated'));

      final result = await dao.getById(userId);
      expect(result, isNotNull);
      expect(result!.fullName, equals('Updated'));
    });

    test('preserves other profiles when updating one', () async {
      await dao.upsert(makeEntry(id: userId, fullName: 'User 1'));
      await dao.upsert(makeEntry(id: otherId, fullName: 'User 2'));

      await dao.upsert(makeEntry(id: userId, fullName: 'User 1 Updated'));

      final user1 = await dao.getById(userId);
      final user2 = await dao.getById(otherId);
      expect(user1!.fullName, equals('User 1 Updated'));
      expect(user2!.fullName, equals('User 2'));
    });

    test('handles nullable fields correctly', () async {
      await dao.upsert(
        makeEntry(id: userId, fullName: null, avatarUrl: null, role: null),
      );

      final result = await dao.getById(userId);
      expect(result, isNotNull);
      expect(result!.fullName, isNull);
      expect(result.avatarUrl, isNull);
      expect(result.role, isNull);
    });

    test('updates nullable fields from null to value', () async {
      await dao.upsert(makeEntry(id: userId, avatarUrl: null));

      await dao.upsert(
        makeEntry(id: userId, avatarUrl: 'https://example.com/avatar.png'),
      );

      final result = await dao.getById(userId);
      expect(result!.avatarUrl, equals('https://example.com/avatar.png'));
    });
  });

  group('hardDelete', () {
    test('permanently removes the profile', () async {
      await dao.upsert(makeEntry(id: userId));

      await dao.hardDelete(userId);

      final result = await dao.getById(userId);
      expect(result, isNull);
    });

    test('does not affect other profiles', () async {
      await dao.upsert(makeEntry(id: userId));
      await dao.upsert(makeEntry(id: otherId, email: 'other@test.com'));

      await dao.hardDelete(userId);

      final deleted = await dao.getById(userId);
      final remaining = await dao.getById(otherId);
      expect(deleted, isNull);
      expect(remaining, isNotNull);
      expect(remaining!.id, equals(otherId));
    });

    test('is a no-op when profile does not exist', () async {
      final deletedCount = await dao.hardDelete('non-existent');
      expect(deletedCount, equals(0));
    });

    test('returns 1 when profile is deleted', () async {
      await dao.upsert(makeEntry(id: userId));

      final deletedCount = await dao.hardDelete(userId);
      expect(deletedCount, equals(1));
    });
  });
}
