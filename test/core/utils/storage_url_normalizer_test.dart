import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/utils/storage_url_normalizer.dart';

void main() {
  group('StorageUrlNormalizer.normalizePublicObjectUrl', () {
    test('converts signed public image URL to stable public URL', () {
      const signed =
          'https://project.supabase.co/storage/v1/object/sign/'
          'avatars/user-1/avatar.jpg?token=abc';

      expect(
        StorageUrlNormalizer.normalizePublicObjectUrl(signed),
        'https://project.supabase.co/storage/v1/object/public/'
        'avatars/user-1/avatar.jpg',
      );
    });

    test('keeps signed URL for private photo bucket unchanged', () {
      const signed =
          'https://project.supabase.co/storage/v1/object/sign/'
          'bird-photos/user-1/bird-1/photo.jpg?token=abc';

      expect(StorageUrlNormalizer.normalizePublicObjectUrl(signed), signed);
    });

    test('keeps public URL unchanged', () {
      const publicUrl =
          'https://project.supabase.co/storage/v1/object/public/'
          'avatars/user-1/avatar.jpg';

      expect(
        StorageUrlNormalizer.normalizePublicObjectUrl(publicUrl),
        publicUrl,
      );
    });

    test('keeps signed URL for non-public bucket unchanged', () {
      const privateUrl =
          'https://project.supabase.co/storage/v1/object/sign/'
          'backups/user-1/export.zip?token=abc';

      expect(
        StorageUrlNormalizer.normalizePublicObjectUrl(privateUrl),
        privateUrl,
      );
    });

    test('keeps non-storage URL unchanged', () {
      const url = 'https://example.com/image.jpg';

      expect(StorageUrlNormalizer.normalizePublicObjectUrl(url), url);
    });

    test('normalizes URL list', () {
      const urls = [
        'https://project.supabase.co/storage/v1/object/sign/'
            'avatars/user-1/avatar.jpg?token=abc',
        'https://example.com/other.jpg',
      ];

      expect(StorageUrlNormalizer.normalizePublicObjectUrls(urls), [
        'https://project.supabase.co/storage/v1/object/public/'
            'avatars/user-1/avatar.jpg',
        'https://example.com/other.jpg',
      ]);
    });
  });

  group('StorageUrlNormalizer.extractObjectPath', () {
    test('extracts bucket and path from signed URL', () {
      const url =
          'https://project.supabase.co/storage/v1/object/sign/'
          'bird-photos/user-1/bird-1/photo.jpg?token=abc';

      final path = StorageUrlNormalizer.extractObjectPath(url);

      expect(path?.bucket, 'bird-photos');
      expect(path?.path, 'user-1/bird-1/photo.jpg');
    });

    test('extracts bucket and path from public URL', () {
      const url =
          'https://project.supabase.co/storage/v1/object/public/'
          'egg-photos/user-1/egg-1/photo.jpg';

      final path = StorageUrlNormalizer.extractObjectPath(url);

      expect(path?.bucket, 'egg-photos');
      expect(path?.path, 'user-1/egg-1/photo.jpg');
    });
  });
}
