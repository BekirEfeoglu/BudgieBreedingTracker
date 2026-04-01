import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/remote/storage/storage_utils.dart';

void main() {
  group('StorageUtils.safeExtension', () {
    test('returns lowercase extension when filename has a dot', () {
      expect(StorageUtils.safeExtension('photo.JPEG'), 'jpeg');
    });

    test('falls back to jpg when filename has no dot', () {
      expect(StorageUtils.safeExtension('photo'), 'jpg');
    });

    test('falls back to jpg when filename ends with a dot', () {
      expect(StorageUtils.safeExtension('photo.'), 'jpg');
    });
  });

  group('StorageUtils.validateMagicBytes', () {
    test('accepts jpeg signature', () {
      expect(
        StorageUtils.validateMagicBytes([0xFF, 0xD8, 0xFF, 0x00], 'jpg'),
        isTrue,
      );
    });

    test('accepts png signature', () {
      expect(
        StorageUtils.validateMagicBytes([0x89, 0x50, 0x4E, 0x47], 'png'),
        isTrue,
      );
    });

    test('accepts gif signature', () {
      expect(
        StorageUtils.validateMagicBytes([0x47, 0x49, 0x46, 0x38], 'gif'),
        isTrue,
      );
    });

    test('accepts webp signature', () {
      expect(
        StorageUtils.validateMagicBytes([
          0x52,
          0x49,
          0x46,
          0x46,
          0x00,
          0x00,
          0x00,
          0x00,
          0x57,
          0x45,
          0x42,
          0x50,
        ], 'webp'),
        isTrue,
      );
    });

    test('accepts heic signature with known brand', () {
      expect(
        StorageUtils.validateMagicBytes([
          0x00,
          0x00,
          0x00,
          0x18,
          0x66,
          0x74,
          0x79,
          0x70,
          0x68,
          0x65,
          0x69,
          0x63,
        ], 'heic'),
        isTrue,
      );
    });

    test('rejects bytes shorter than minimum header length', () {
      expect(
        StorageUtils.validateMagicBytes([0xFF, 0xD8, 0xFF], 'jpg'),
        isFalse,
      );
    });

    test('rejects invalid signature for claimed extension', () {
      expect(
        StorageUtils.validateMagicBytes([0x89, 0x50, 0x4E, 0x47], 'jpg'),
        isFalse,
      );
    });

    test('rejects unknown extension', () {
      expect(
        StorageUtils.validateMagicBytes([0xFF, 0xD8, 0xFF, 0x00], 'bmp'),
        isFalse,
      );
    });

    test('rejects heic when brand is not allowed', () {
      expect(
        StorageUtils.validateMagicBytes([
          0x00,
          0x00,
          0x00,
          0x18,
          0x66,
          0x74,
          0x79,
          0x70,
          0x61,
          0x76,
          0x69,
          0x66,
        ], 'heic'),
        isFalse,
      );
    });
  });

  group('StorageUtils.getMimeType', () {
    test('maps supported extensions to image mime types', () {
      expect(StorageUtils.getMimeType('bird.jpg'), 'image/jpeg');
      expect(StorageUtils.getMimeType('bird.png'), 'image/png');
      expect(StorageUtils.getMimeType('bird.gif'), 'image/gif');
      expect(StorageUtils.getMimeType('bird.webp'), 'image/webp');
      expect(StorageUtils.getMimeType('bird.heic'), 'image/heic');
    });

    test('returns binary mime type for unsupported extension', () {
      expect(StorageUtils.getMimeType('bird.bmp'), 'application/octet-stream');
    });

    test('uses jpg fallback when extension is missing', () {
      expect(StorageUtils.getMimeType('bird'), 'image/jpeg');
    });
  });
}
