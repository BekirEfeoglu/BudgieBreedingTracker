import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/data/remote/storage/storage_url_resolver.dart';

import '../../../helpers/mocks.dart';

class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

class MockStorageFileApi extends Mock implements StorageFileApi {}

void main() {
  late MockSupabaseClient client;
  late MockSupabaseStorageClient storage;
  late MockStorageFileApi fileApi;
  late DateTime now;
  late StorageUrlResolver resolver;

  setUp(() {
    client = MockSupabaseClient();
    storage = MockSupabaseStorageClient();
    fileApi = MockStorageFileApi();
    now = DateTime(2026, 5, 6, 12);

    when(() => client.storage).thenReturn(storage);
    when(() => storage.from(any())).thenReturn(fileApi);
    when(
      () => fileApi.createSignedUrl(any(), any()),
    ).thenAnswer((_) async => 'https://project.supabase.co/fresh-signed-url');

    resolver = StorageUrlResolver(client, now: () => now);
  });

  group('StorageUrlResolver.resolve', () {
    test('keeps non-storage URL unchanged', () async {
      const url = 'https://example.com/photo.jpg';

      await expectLater(resolver.resolve(url), completion(url));
      verifyNever(() => fileApi.createSignedUrl(any(), any()));
    });

    test('keeps public bucket URL public', () async {
      const url =
          'https://project.supabase.co/storage/v1/object/sign/'
          'avatars/user-1/avatar.jpg?token=old';

      await expectLater(
        resolver.resolve(url),
        completion(
          'https://project.supabase.co/storage/v1/object/public/'
          'avatars/user-1/avatar.jpg',
        ),
      );
      verifyNever(() => fileApi.createSignedUrl(any(), any()));
    });

    test('creates fresh signed URL for private signed bucket URL', () async {
      const url =
          'https://project.supabase.co/storage/v1/object/sign/'
          'bird-photos/user-1/bird-1/photo.jpg?token=old';

      await expectLater(
        resolver.resolve(url),
        completion('https://project.supabase.co/fresh-signed-url'),
      );
      verify(() => storage.from('bird-photos')).called(greaterThanOrEqualTo(1));
      verify(
        () => fileApi.createSignedUrl(
          'user-1/bird-1/photo.jpg',
          StorageUrlResolver.signedUrlExpirySeconds,
        ),
      ).called(1);
    });

    test('creates fresh signed URL for private public bucket URL', () async {
      const url =
          'https://project.supabase.co/storage/v1/object/public/'
          'egg-photos/user-1/egg-1/photo.jpg';

      await expectLater(
        resolver.resolve(url),
        completion('https://project.supabase.co/fresh-signed-url'),
      );
      verify(
        () => fileApi.createSignedUrl(
          'user-1/egg-1/photo.jpg',
          StorageUrlResolver.signedUrlExpirySeconds,
        ),
      ).called(1);
    });

    test('caches fresh signed URL by storage path', () async {
      const url =
          'https://project.supabase.co/storage/v1/object/sign/'
          'chick-photos/user-1/chick-1/photo.jpg?token=old';

      await resolver.resolve(url);
      await resolver.resolve(url);

      verify(() => fileApi.createSignedUrl(any(), any())).called(1);
    });
  });
}
