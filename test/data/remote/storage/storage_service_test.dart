import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_service.dart';

import '../../../helpers/mocks.dart';

class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

class MockStorageFileApi extends Mock implements StorageFileApi {}

class MockXFile extends Mock implements XFile {}

void main() {
  late MockSupabaseClient mockClient;
  late MockSupabaseStorageClient mockStorage;
  late MockStorageFileApi mockFileApi;
  late StorageService service;

  setUpAll(() {
    registerFallbackValue(const FileOptions());
    registerFallbackValue(<String>[]);
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockStorage = MockSupabaseStorageClient();
    mockFileApi = MockStorageFileApi();
    when(() => mockClient.storage).thenReturn(mockStorage);
    when(() => mockStorage.from(any())).thenReturn(mockFileApi);

    // Stub auth so that getAvatarUrl's currentUser check works
    final mockAuth = MockGoTrueClient();
    final mockUser = MockUser();
    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);

    service = StorageService(mockClient);
  });

  /// Returns magic-byte header matching [ext] so _validateMagicBytes passes.
  Uint8List magicBytesFor(String ext, int totalSize) {
    final data = Uint8List(totalSize);
    switch (ext) {
      case 'jpg' || 'jpeg':
        data[0] = 0xFF;
        data[1] = 0xD8;
        data[2] = 0xFF;
      case 'png':
        data[0] = 0x89;
        data[1] = 0x50;
        data[2] = 0x4E;
        data[3] = 0x47;
      case 'gif':
        data[0] = 0x47;
        data[1] = 0x49;
        data[2] = 0x46;
      case 'webp':
        data[0] = 0x52; // R
        data[1] = 0x49; // I
        data[2] = 0x46; // F
        data[3] = 0x46; // F
        data[8] = 0x57; // W
        data[9] = 0x45; // E
        data[10] = 0x42; // B
        data[11] = 0x50; // P
      case 'heic':
        data[4] = 0x66; // f
        data[5] = 0x74; // t
        data[6] = 0x79; // y
        data[7] = 0x70; // p
        data[8] = 0x68; // h
        data[9] = 0x65; // e
        data[10] = 0x69; // i
        data[11] = 0x63; // c
    }
    return data;
  }

  MockXFile makeXFile({String name = 'photo.jpg', int bytes = 100}) {
    final file = MockXFile();
    when(() => file.name).thenReturn(name);
    final ext = name.split('.').last.toLowerCase();
    final data = magicBytesFor(ext, bytes);
    when(() => file.readAsBytes()).thenAnswer((_) async => data);
    return file;
  }

  group('StorageService', () {
    // -----------------------------------------------------------------------
    group('uploadBirdPhoto', () {
      test('returns public URL on success', () async {
        final file = makeXFile();
        when(
          () => mockFileApi.uploadBinary(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((_) async => 'storage-key');
        when(
          () => mockFileApi.createSignedUrl(any(), any()),
        ).thenAnswer((_) async => 'https://cdn.example.com/photo.jpg');

        final url = await service.uploadBirdPhoto(
          userId: 'u1',
          birdId: 'b1',
          file: file,
        );

        expect(url, 'https://cdn.example.com/photo.jpg');
      });

      test('throws StorageException when file exceeds 10 MB', () async {
        final largeFile = makeXFile(bytes: AppConstants.maxUploadSizeBytes + 1);

        await expectLater(
          () => service.uploadBirdPhoto(
            userId: 'u1',
            birdId: 'b1',
            file: largeFile,
          ),
          throwsA(isA<StorageException>()),
        );
      });

      test('rethrows StorageException from uploadBinary', () async {
        final file = makeXFile();
        when(
          () => mockFileApi.uploadBinary(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenThrow(const StorageException('upload failed'));

        await expectLater(
          () => service.uploadBirdPhoto(userId: 'u1', birdId: 'b1', file: file),
          throwsA(isA<StorageException>()),
        );
      });

      test('uses bird-photos bucket', () async {
        final file = makeXFile();
        when(
          () => mockFileApi.uploadBinary(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((_) async => '');
        when(
          () => mockFileApi.createSignedUrl(any(), any()),
        ).thenAnswer((_) async => 'https://url');

        await service.uploadBirdPhoto(userId: 'u1', birdId: 'b1', file: file);

        verify(
          () => mockStorage.from(SupabaseConstants.birdPhotosBucket),
        ).called(greaterThanOrEqualTo(1));
      });

      test('constructs path with userId/birdId prefix', () async {
        final file = makeXFile(name: 'snap.jpg');
        String? capturedPath;
        when(
          () => mockFileApi.uploadBinary(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((invocation) async {
          capturedPath = invocation.positionalArguments.first as String;
          return '';
        });
        when(
          () => mockFileApi.createSignedUrl(any(), any()),
        ).thenAnswer((_) async => 'https://url');

        await service.uploadBirdPhoto(userId: 'u1', birdId: 'b1', file: file);

        expect(capturedPath, startsWith('u1/b1/'));
        expect(capturedPath, endsWith('.jpg'));
      });
    });

    // -----------------------------------------------------------------------
    group('uploadAvatar', () {
      test('returns public URL on success', () async {
        final file = makeXFile(name: 'avatar.png');
        when(
          () => mockFileApi.uploadBinary(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((_) async => '');
        when(
          () => mockFileApi.createSignedUrl(any(), any()),
        ).thenAnswer((_) async => 'https://cdn.example.com/u1/avatar.png');

        final url = await service.uploadAvatar(userId: 'u1', file: file);

        expect(url, 'https://cdn.example.com/u1/avatar.png');
      });

      test('uses avatars bucket', () async {
        final file = makeXFile(name: 'avatar.jpg');
        when(
          () => mockFileApi.uploadBinary(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((_) async => '');
        when(
          () => mockFileApi.createSignedUrl(any(), any()),
        ).thenAnswer((_) async => 'https://url');

        await service.uploadAvatar(userId: 'u1', file: file);

        verify(
          () => mockStorage.from(SupabaseConstants.avatarsBucket),
        ).called(greaterThanOrEqualTo(1));
      });

      test('constructs path as userId/avatar.ext', () async {
        final file = makeXFile(name: 'pic.heic');
        String? capturedPath;
        when(
          () => mockFileApi.uploadBinary(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((invocation) async {
          capturedPath = invocation.positionalArguments.first as String;
          return '';
        });
        when(
          () => mockFileApi.createSignedUrl(any(), any()),
        ).thenAnswer((_) async => 'https://url');

        await service.uploadAvatar(userId: 'u1', file: file);

        expect(capturedPath, 'u1/avatar.heic');
      });
    });

    // -----------------------------------------------------------------------
    group('deleteBirdPhoto', () {
      test('removes the given path from bird-photos bucket', () async {
        when(() => mockFileApi.remove(any())).thenAnswer((_) async => []);

        await service.deleteBirdPhoto(storagePath: 'u1/b1/photo.jpg');

        final captured = verify(
          () => mockFileApi.remove(captureAny()),
        ).captured;
        expect((captured.single as List<String>), contains('u1/b1/photo.jpg'));
      });

      test('rethrows StorageException on failure', () async {
        when(
          () => mockFileApi.remove(any()),
        ).thenThrow(const StorageException('not found'));

        await expectLater(
          () => service.deleteBirdPhoto(storagePath: 'u1/b1/photo.jpg'),
          throwsA(isA<StorageException>()),
        );
      });
    });

    // -----------------------------------------------------------------------
    group('deleteAvatar', () {
      test('removes listed avatar files', () async {
        final obj = FileObject.fromJson({'name': 'avatar.jpg', 'id': 'file-1'});
        when(
          () => mockFileApi.list(path: any(named: 'path')),
        ).thenAnswer((_) async => [obj]);
        when(() => mockFileApi.remove(any())).thenAnswer((_) async => []);

        await service.deleteAvatar(userId: 'u1');

        final captured = verify(
          () => mockFileApi.remove(captureAny()),
        ).captured;
        expect((captured.single as List<String>), contains('u1/avatar.jpg'));
      });

      test('does nothing when no avatar files exist', () async {
        when(
          () => mockFileApi.list(path: any(named: 'path')),
        ).thenAnswer((_) async => []);

        await service.deleteAvatar(userId: 'u1');

        verifyNever(() => mockFileApi.remove(any()));
      });

      test('rethrows StorageException from list', () async {
        when(
          () => mockFileApi.list(path: any(named: 'path')),
        ).thenThrow(const StorageException('list failed'));

        await expectLater(
          () => service.deleteAvatar(userId: 'u1'),
          throwsA(isA<StorageException>()),
        );
      });
    });

    // -----------------------------------------------------------------------
    group('listBirdPhotos', () {
      test('returns sorted public URLs (descending)', () async {
        final files = [
          FileObject.fromJson({'name': 'a.jpg', 'id': '1'}),
          FileObject.fromJson({'name': 'b.jpg', 'id': '2'}),
        ];
        when(
          () => mockFileApi.list(path: any(named: 'path')),
        ).thenAnswer((_) async => files);
        when(() => mockFileApi.createSignedUrls(any(), any())).thenAnswer(
          (_) async => [
            const SignedUrl(
              signedUrl: 'https://cdn.example.com/photo-1.jpg',
              path: 'u1/b1/a.jpg',
            ),
            const SignedUrl(
              signedUrl: 'https://cdn.example.com/photo-0.jpg',
              path: 'u1/b1/b.jpg',
            ),
          ],
        );

        final urls = await service.listBirdPhotos(userId: 'u1', birdId: 'b1');

        expect(urls, hasLength(2));
        // Sorted b.compareTo(a) → descending
        expect(urls.first.compareTo(urls.last), greaterThan(0));
      });

      test('returns empty list on StorageException', () async {
        when(
          () => mockFileApi.list(path: any(named: 'path')),
        ).thenThrow(const StorageException('list error'));

        final urls = await service.listBirdPhotos(userId: 'u1', birdId: 'b1');

        expect(urls, isEmpty);
      });

      test('returns empty list when folder is empty', () async {
        when(
          () => mockFileApi.list(path: any(named: 'path')),
        ).thenAnswer((_) async => []);
        when(
          () => mockFileApi.createSignedUrls(any(), any()),
        ).thenAnswer((_) async => []);

        final urls = await service.listBirdPhotos(userId: 'u1', birdId: 'b1');

        expect(urls, isEmpty);
      });
    });

    // -----------------------------------------------------------------------
    group('getAvatarUrl', () {
      test('returns URL when avatar exists', () async {
        final obj = FileObject.fromJson({'name': 'avatar.jpg', 'id': 'x'});
        when(
          () => mockFileApi.list(path: any(named: 'path')),
        ).thenAnswer((_) async => [obj]);
        when(
          () => mockFileApi.createSignedUrl(any(), any()),
        ).thenAnswer((_) async => 'https://cdn.example.com/u1/avatar.jpg');

        final url = await service.getAvatarUrl(userId: 'u1');

        expect(url, 'https://cdn.example.com/u1/avatar.jpg');
      });

      test('returns null when no avatar exists', () async {
        when(
          () => mockFileApi.list(path: any(named: 'path')),
        ).thenAnswer((_) async => []);

        final url = await service.getAvatarUrl(userId: 'u1');

        expect(url, isNull);
      });

      test('returns null on StorageException', () async {
        when(
          () => mockFileApi.list(path: any(named: 'path')),
        ).thenThrow(const StorageException('get failed'));

        final url = await service.getAvatarUrl(userId: 'u1');

        expect(url, isNull);
      });
    });

    // -----------------------------------------------------------------------
    group('file extension validation', () {
      test('rejects file with disallowed extension (.exe)', () async {
        final file = makeXFile(name: 'malware.exe');

        await expectLater(
          () => service.uploadBirdPhoto(userId: 'u1', birdId: 'b1', file: file),
          throwsA(
            isA<StorageException>().having(
              (e) => e.message,
              'message',
              contains('not allowed'),
            ),
          ),
        );
      });

      test('rejects file with disallowed extension (.sh)', () async {
        final file = makeXFile(name: 'script.sh');

        await expectLater(
          () => service.uploadAvatar(userId: 'u1', file: file),
          throwsA(isA<StorageException>()),
        );
      });

      test('rejects file with disallowed extension (.pdf)', () async {
        final file = makeXFile(name: 'document.pdf');

        await expectLater(
          () => service.uploadCommunityPhoto(
            userId: 'u1',
            postId: 'p1',
            file: file,
          ),
          throwsA(isA<StorageException>()),
        );
      });

      test('allows file with .jpg extension', () async {
        final file = makeXFile(name: 'photo.jpg');
        when(
          () => mockFileApi.uploadBinary(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((_) async => '');
        when(
          () => mockFileApi.createSignedUrl(any(), any()),
        ).thenAnswer((_) async => 'https://url');

        final url = await service.uploadBirdPhoto(
          userId: 'u1',
          birdId: 'b1',
          file: file,
        );

        expect(url, isNotEmpty);
      });

      test('allows file with .png extension', () async {
        final file = makeXFile(name: 'image.png');
        when(
          () => mockFileApi.uploadBinary(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((_) async => '');
        when(
          () => mockFileApi.createSignedUrl(any(), any()),
        ).thenAnswer((_) async => 'https://url');

        final url = await service.uploadAvatar(userId: 'u1', file: file);

        expect(url, isNotEmpty);
      });

      test('allows file with .webp extension', () async {
        final file = makeXFile(name: 'image.webp');
        when(
          () => mockFileApi.uploadBinary(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((_) async => '');
        when(
          () => mockFileApi.createSignedUrl(any(), any()),
        ).thenAnswer((_) async => 'https://url');

        final url = await service.uploadBirdPhoto(
          userId: 'u1',
          birdId: 'b1',
          file: file,
        );

        expect(url, isNotEmpty);
      });

      test('allows file with .heic extension', () async {
        final file = makeXFile(name: 'photo.heic');
        when(
          () => mockFileApi.uploadBinary(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((_) async => '');
        when(
          () => mockFileApi.createSignedUrl(any(), any()),
        ).thenAnswer((_) async => 'https://url');

        final url = await service.uploadAvatar(userId: 'u1', file: file);

        expect(url, isNotEmpty);
      });

      test('extension check is case insensitive', () async {
        final file = makeXFile(name: 'photo.JPG');
        when(
          () => mockFileApi.uploadBinary(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((_) async => '');
        when(
          () => mockFileApi.createSignedUrl(any(), any()),
        ).thenAnswer((_) async => 'https://url');

        final url = await service.uploadBirdPhoto(
          userId: 'u1',
          birdId: 'b1',
          file: file,
        );

        expect(url, isNotEmpty);
      });
    });

    // -----------------------------------------------------------------------
    group('deleteAllUserFiles', () {
      test('completes silently when all buckets are empty', () async {
        when(
          () => mockFileApi.list(path: any(named: 'path')),
        ).thenAnswer((_) async => []);

        await service.deleteAllUserFiles('u1');

        verifyNever(() => mockFileApi.remove(any()));
      });

      test('removes files found in the first bucket', () async {
        final fileObj = FileObject.fromJson({'name': 'photo.jpg', 'id': 'f1'});
        var callCount = 0;
        when(() => mockFileApi.list(path: any(named: 'path'))).thenAnswer((
          _,
        ) async {
          callCount++;
          return callCount == 1 ? [fileObj] : [];
        });
        when(() => mockFileApi.remove(any())).thenAnswer((_) async => []);

        await service.deleteAllUserFiles('u1');

        verify(() => mockFileApi.remove(any())).called(1);
      });

      test('swallows per-bucket errors and continues', () async {
        when(
          () => mockFileApi.list(path: any(named: 'path')),
        ).thenThrow(Exception('network error'));

        // Must not throw — errors are caught per bucket
        await service.deleteAllUserFiles('u1');
      });

      test('recurses into sub-folders (id == null → folder)', () async {
        // First list returns a folder item (id == null) then files inside it.
        final folder = FileObject.fromJson({'name': 'bird-1', 'id': null});
        final file = FileObject.fromJson({'name': 'snap.jpg', 'id': 'f99'});
        var callCount = 0;
        when(() => mockFileApi.list(path: any(named: 'path'))).thenAnswer((
          _,
        ) async {
          callCount++;
          if (callCount == 1) return [folder]; // top-level: folder
          if (callCount == 2) return [file]; // inside folder: file
          return [];
        });
        when(() => mockFileApi.remove(any())).thenAnswer((_) async => []);

        await service.deleteAllUserFiles('u1');

        verify(() => mockFileApi.remove(any())).called(1);
      });
    });
  });
}
