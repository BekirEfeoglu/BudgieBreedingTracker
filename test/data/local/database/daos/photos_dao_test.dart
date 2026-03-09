import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/photos_dao.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';
import 'package:budgie_breeding_tracker/core/enums/photo_enums.dart';

void main() {
  late AppDatabase db;
  late PhotosDao dao;

  const userId = 'user-1';
  const otherId = 'user-2';

  Photo makeEntry({
    String id = 'photo-1',
    String user = userId,
    PhotoEntityType entityType = PhotoEntityType.bird,
    String entityId = 'bird-1',
    String fileName = 'bird_photo.jpg',
    String? filePath,
    int? fileSize,
    String? mimeType,
    bool isPrimary = false,
  }) {
    return Photo(
      id: id,
      userId: user,
      entityType: entityType,
      entityId: entityId,
      fileName: fileName,
      filePath: filePath,
      fileSize: fileSize,
      mimeType: mimeType,
      isPrimary: isPrimary,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.photosDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('watchAll', () {
    test('returns photos for the given userId', () async {
      await dao.insertItem(makeEntry(id: 'photo-1', user: userId));
      await dao.insertItem(makeEntry(id: 'photo-2', user: userId));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(2));
    });

    test('does not return photos for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'photo-1', user: userId));
      await dao.insertItem(makeEntry(id: 'photo-2', user: otherId));

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(1));
      expect(results.first.id, equals('photo-1'));
    });

    test('returns empty list when no photos exist', () async {
      final results = await dao.watchAll(userId).first;
      expect(results, isEmpty);
    });

    test('returns all photos without isDeleted filter', () async {
      await dao.insertItem(
        makeEntry(id: 'photo-1', entityType: PhotoEntityType.bird),
      );
      await dao.insertItem(
        makeEntry(id: 'photo-2', entityType: PhotoEntityType.chick),
      );
      await dao.insertItem(
        makeEntry(id: 'photo-3', entityType: PhotoEntityType.egg),
      );

      final results = await dao.watchAll(userId).first;
      expect(results.length, equals(3));
    });
  });

  group('watchByEntity', () {
    test('returns photos for the specific entity', () async {
      await dao.insertItem(makeEntry(id: 'photo-1', entityId: 'bird-1'));
      await dao.insertItem(makeEntry(id: 'photo-2', entityId: 'bird-1'));
      await dao.insertItem(makeEntry(id: 'photo-3', entityId: 'bird-2'));

      final results = await dao.watchByEntity('bird-1').first;
      expect(results.length, equals(2));
    });

    test('returns empty list when no photos exist for the entity', () async {
      await dao.insertItem(makeEntry(id: 'photo-1', entityId: 'bird-1'));

      final results = await dao.watchByEntity('bird-99').first;
      expect(results, isEmpty);
    });

    test('returns photos regardless of userId', () async {
      await dao.insertItem(
        makeEntry(id: 'photo-1', user: userId, entityId: 'bird-1'),
      );
      await dao.insertItem(
        makeEntry(id: 'photo-2', user: otherId, entityId: 'bird-1'),
      );

      final results = await dao.watchByEntity('bird-1').first;
      expect(results.length, equals(2));
    });
  });

  group('getAll', () {
    test('returns photos for the given userId', () async {
      await dao.insertItem(makeEntry(id: 'photo-1'));
      await dao.insertItem(makeEntry(id: 'photo-2'));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });

    test('does not return photos for a different userId', () async {
      await dao.insertItem(makeEntry(id: 'photo-1', user: userId));
      await dao.insertItem(makeEntry(id: 'photo-2', user: otherId));

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });

    test('returns empty list when no photos exist', () async {
      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('getById', () {
    test('returns the photo when it exists', () async {
      await dao.insertItem(makeEntry(id: 'photo-1'));

      final result = await dao.getById('photo-1');
      expect(result, isNotNull);
      expect(result!.id, equals('photo-1'));
      expect(result.userId, equals(userId));
      expect(result.fileName, equals('bird_photo.jpg'));
    });

    test('returns null when photo does not exist', () async {
      final result = await dao.getById('non-existent');
      expect(result, isNull);
    });
  });

  group('getByEntity', () {
    test('returns photos for the specific entity', () async {
      await dao.insertItem(makeEntry(id: 'photo-1', entityId: 'bird-1'));
      await dao.insertItem(makeEntry(id: 'photo-2', entityId: 'bird-1'));
      await dao.insertItem(makeEntry(id: 'photo-3', entityId: 'bird-2'));

      final results = await dao.getByEntity('bird-1');
      expect(results.length, equals(2));
    });

    test('returns empty list when no photos exist for the entity', () async {
      await dao.insertItem(makeEntry(id: 'photo-1', entityId: 'bird-1'));

      final results = await dao.getByEntity('bird-99');
      expect(results, isEmpty);
    });

    test('returns photos regardless of userId', () async {
      await dao.insertItem(
        makeEntry(id: 'photo-1', user: userId, entityId: 'bird-1'),
      );
      await dao.insertItem(
        makeEntry(id: 'photo-2', user: otherId, entityId: 'bird-1'),
      );

      final results = await dao.getByEntity('bird-1');
      expect(results.length, equals(2));
    });
  });

  group('getByEntityType', () {
    test('returns photos filtered by entity type', () async {
      await dao.insertItem(
        makeEntry(id: 'photo-1', entityType: PhotoEntityType.bird),
      );
      await dao.insertItem(
        makeEntry(id: 'photo-2', entityType: PhotoEntityType.chick),
      );
      await dao.insertItem(
        makeEntry(id: 'photo-3', entityType: PhotoEntityType.bird),
      );

      final results = await dao.getByEntityType(userId, PhotoEntityType.bird);
      expect(results.length, equals(2));
    });

    test('does not return photos for a different userId', () async {
      await dao.insertItem(
        makeEntry(
          id: 'photo-1',
          user: userId,
          entityType: PhotoEntityType.bird,
        ),
      );
      await dao.insertItem(
        makeEntry(
          id: 'photo-2',
          user: otherId,
          entityType: PhotoEntityType.bird,
        ),
      );

      final results = await dao.getByEntityType(userId, PhotoEntityType.bird);
      expect(results.length, equals(1));
      expect(results.first.id, equals('photo-1'));
    });

    test('returns empty list when no photos match the entity type', () async {
      await dao.insertItem(
        makeEntry(id: 'photo-1', entityType: PhotoEntityType.bird),
      );

      final results = await dao.getByEntityType(userId, PhotoEntityType.egg);
      expect(results, isEmpty);
    });

    test('filters correctly across all entity types', () async {
      await dao.insertItem(
        makeEntry(
          id: 'photo-1',
          entityType: PhotoEntityType.bird,
          entityId: 'bird-1',
        ),
      );
      await dao.insertItem(
        makeEntry(
          id: 'photo-2',
          entityType: PhotoEntityType.chick,
          entityId: 'chick-1',
        ),
      );
      await dao.insertItem(
        makeEntry(
          id: 'photo-3',
          entityType: PhotoEntityType.egg,
          entityId: 'egg-1',
        ),
      );
      await dao.insertItem(
        makeEntry(
          id: 'photo-4',
          entityType: PhotoEntityType.nest,
          entityId: 'nest-1',
        ),
      );

      final birds = await dao.getByEntityType(userId, PhotoEntityType.bird);
      final chicks = await dao.getByEntityType(userId, PhotoEntityType.chick);
      final eggs = await dao.getByEntityType(userId, PhotoEntityType.egg);
      final nests = await dao.getByEntityType(userId, PhotoEntityType.nest);

      expect(birds.length, equals(1));
      expect(chicks.length, equals(1));
      expect(eggs.length, equals(1));
      expect(nests.length, equals(1));
    });
  });

  group('insertItem', () {
    test('inserts a new photo', () async {
      await dao.insertItem(makeEntry(id: 'photo-1'));

      final result = await dao.getById('photo-1');
      expect(result, isNotNull);
      expect(result!.entityType, equals(PhotoEntityType.bird));
      expect(result.fileName, equals('bird_photo.jpg'));
    });

    test('upserts on conflict (updates existing)', () async {
      await dao.insertItem(makeEntry(id: 'photo-1', fileName: 'original.jpg'));
      await dao.insertItem(makeEntry(id: 'photo-1', fileName: 'updated.jpg'));

      final result = await dao.getById('photo-1');
      expect(result, isNotNull);
      expect(result!.fileName, equals('updated.jpg'));
    });

    test('stores all optional fields correctly', () async {
      await dao.insertItem(
        makeEntry(
          id: 'photo-1',
          filePath: '/photos/bird_1.jpg',
          fileSize: 1024000,
          mimeType: 'image/jpeg',
          isPrimary: true,
        ),
      );

      final result = await dao.getById('photo-1');
      expect(result, isNotNull);
      expect(result!.filePath, equals('/photos/bird_1.jpg'));
      expect(result.fileSize, equals(1024000));
      expect(result.mimeType, equals('image/jpeg'));
      expect(result.isPrimary, isTrue);
    });
  });

  group('insertAll', () {
    test('inserts multiple photos in batch', () async {
      final items = [
        makeEntry(id: 'photo-1'),
        makeEntry(id: 'photo-2'),
        makeEntry(id: 'photo-3'),
      ];
      await dao.insertAll(items);

      final results = await dao.getAll(userId);
      expect(results.length, equals(3));
    });

    test('handles empty list gracefully', () async {
      await dao.insertAll([]);

      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });

    test('upserts on conflict within batch', () async {
      await dao.insertItem(makeEntry(id: 'photo-1', fileName: 'original.jpg'));
      await dao.insertAll([
        makeEntry(id: 'photo-1', fileName: 'updated.jpg'),
        makeEntry(id: 'photo-2', fileName: 'new.jpg'),
      ]);

      final updated = await dao.getById('photo-1');
      expect(updated!.fileName, equals('updated.jpg'));

      final results = await dao.getAll(userId);
      expect(results.length, equals(2));
    });
  });

  group('hardDelete', () {
    test('permanently removes the photo', () async {
      await dao.insertItem(makeEntry(id: 'photo-1'));

      await dao.hardDelete('photo-1');

      final result = await dao.getById('photo-1');
      expect(result, isNull);
    });

    test('does not affect other photos', () async {
      await dao.insertItem(makeEntry(id: 'photo-1'));
      await dao.insertItem(makeEntry(id: 'photo-2'));

      await dao.hardDelete('photo-1');

      final remaining = await dao.getAll(userId);
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('photo-2'));
    });

    test('is a no-op when photo does not exist', () async {
      await dao.hardDelete('non-existent');

      final results = await dao.getAll(userId);
      expect(results, isEmpty);
    });
  });

  group('deleteByEntity', () {
    test('deletes all photos for the specified entity', () async {
      await dao.insertItem(makeEntry(id: 'photo-1', entityId: 'bird-1'));
      await dao.insertItem(makeEntry(id: 'photo-2', entityId: 'bird-1'));
      await dao.insertItem(makeEntry(id: 'photo-3', entityId: 'bird-2'));

      await dao.deleteByEntity('bird-1');

      final bird1Photos = await dao.getByEntity('bird-1');
      expect(bird1Photos, isEmpty);

      final bird2Photos = await dao.getByEntity('bird-2');
      expect(bird2Photos.length, equals(1));
    });

    test('does not affect photos of other entities', () async {
      await dao.insertItem(makeEntry(id: 'photo-1', entityId: 'bird-1'));
      await dao.insertItem(makeEntry(id: 'photo-2', entityId: 'chick-1'));

      await dao.deleteByEntity('bird-1');

      final remaining = await dao.getAll(userId);
      expect(remaining.length, equals(1));
      expect(remaining.first.entityId, equals('chick-1'));
    });

    test('is a no-op when no photos exist for the entity', () async {
      await dao.insertItem(makeEntry(id: 'photo-1', entityId: 'bird-1'));

      await dao.deleteByEntity('bird-99');

      final results = await dao.getAll(userId);
      expect(results.length, equals(1));
    });
  });
}
