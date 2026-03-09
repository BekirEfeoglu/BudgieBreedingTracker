import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/photo_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/photo_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';

void main() {
  group('PhotoRowMapper.toModel()', () {
    test('maps all fields correctly', () {
      final row = PhotoRow(
        id: 'p1',
        userId: 'u1',
        entityType: PhotoEntityType.bird,
        entityId: 'b1',
        fileName: 'bird_photo.jpg',
        filePath: '/photos/bird_photo.jpg',
        fileSize: 2048,
        mimeType: 'image/jpeg',
        isPrimary: true,
        createdAt: DateTime(2024, 5, 1),
        updatedAt: DateTime(2024, 5, 2),
      );
      final model = row.toModel();

      expect(model.id, 'p1');
      expect(model.userId, 'u1');
      expect(model.entityType, PhotoEntityType.bird);
      expect(model.entityId, 'b1');
      expect(model.fileName, 'bird_photo.jpg');
      expect(model.filePath, '/photos/bird_photo.jpg');
      expect(model.fileSize, 2048);
      expect(model.mimeType, 'image/jpeg');
      expect(model.isPrimary, true);
    });

    test('handles null optional fields', () {
      const row = PhotoRow(
        id: 'p2',
        userId: 'u1',
        entityType: PhotoEntityType.egg,
        entityId: 'e1',
        fileName: 'egg.png',
        filePath: null,
        fileSize: null,
        mimeType: null,
        isPrimary: false,
      );
      final model = row.toModel();

      expect(model.filePath, isNull);
      expect(model.fileSize, isNull);
      expect(model.mimeType, isNull);
      expect(model.isPrimary, false);
    });
  });

  group('PhotoModelMapper.toCompanion()', () {
    test('wraps all fields in Value', () {
      const model = Photo(
        id: 'p1',
        userId: 'u1',
        entityType: PhotoEntityType.chick,
        entityId: 'c1',
        fileName: 'chick.png',
        filePath: '/photos/chick.png',
        fileSize: 1024,
        mimeType: 'image/png',
        isPrimary: true,
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'p1');
      expect(companion.userId.value, 'u1');
      expect(companion.entityType.value, PhotoEntityType.chick);
      expect(companion.entityId.value, 'c1');
      expect(companion.fileName.value, 'chick.png');
      expect(companion.filePath.value, '/photos/chick.png');
      expect(companion.fileSize.value, 1024);
      expect(companion.mimeType.value, 'image/png');
      expect(companion.isPrimary.value, true);
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      const model = Photo(
        id: 'p1',
        userId: 'u1',
        entityType: PhotoEntityType.bird,
        entityId: 'b1',
        fileName: 'test.jpg',
      );
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
