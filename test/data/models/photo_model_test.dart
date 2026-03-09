import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/photo_enums.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';

Photo _buildPhoto({
  String id = 'photo-1',
  String userId = 'user-1',
  PhotoEntityType entityType = PhotoEntityType.bird,
  String entityId = 'bird-1',
  String fileName = 'bird.jpg',
  String? filePath,
  int? fileSize,
  String? mimeType,
  bool isPrimary = false,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Photo(
    id: id,
    userId: userId,
    entityType: entityType,
    entityId: entityId,
    fileName: fileName,
    filePath: filePath,
    fileSize: fileSize,
    mimeType: mimeType,
    isPrimary: isPrimary,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

void main() {
  group('Photo model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final photo = _buildPhoto(
          id: 'photo-42',
          userId: 'user-42',
          entityType: PhotoEntityType.chick,
          entityId: 'chick-1',
          fileName: 'chick.png',
          filePath: '/tmp/chick.png',
          fileSize: 1024,
          mimeType: 'image/png',
          isPrimary: true,
          createdAt: DateTime(2024, 2, 1, 8, 0),
          updatedAt: DateTime(2024, 2, 1, 9, 0),
        );

        final restored = Photo.fromJson(photo.toJson());
        expect(restored, photo);
      });

      test('defaults are applied for omitted optional fields', () {
        final photo = Photo.fromJson({
          'id': 'photo-1',
          'user_id': 'user-1',
          'entity_type': 'bird',
          'entity_id': 'bird-1',
          'file_name': 'bird.jpg',
        });

        expect(photo.isPrimary, isFalse);
        expect(photo.filePath, isNull);
        expect(photo.fileSize, isNull);
      });

      test('falls back to bird entity type for unknown enum value', () {
        final photo = Photo.fromJson({
          'id': 'photo-1',
          'user_id': 'user-1',
          'entity_type': 'not-a-type',
          'entity_id': 'x',
          'file_name': 'x.jpg',
        });

        expect(photo.entityType, PhotoEntityType.bird);
      });
    });

    group('copyWith', () {
      test('updates selected fields', () {
        final photo = _buildPhoto(fileName: 'old.jpg', isPrimary: false);
        final updated = photo.copyWith(fileName: 'new.jpg', isPrimary: true);

        expect(updated.fileName, 'new.jpg');
        expect(updated.isPrimary, isTrue);
        expect(updated.id, photo.id);
        expect(updated.userId, photo.userId);
      });
    });
  });
}
