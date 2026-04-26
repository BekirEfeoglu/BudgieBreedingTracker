@Tags(['community'])
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/community_post_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/moderation/content_moderation_service.dart';
import 'package:budgie_breeding_tracker/domain/services/moderation/image_safety_service.dart';
import 'package:budgie_breeding_tracker/domain/services/moderation/moderation_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_create_providers.dart';

class MockCommunityPostRepository extends Mock
    implements CommunityPostRepository {}

class AllowedContentModerationService extends ContentModerationService {
  const AllowedContentModerationService();

  @override
  Future<ModerationResult> checkText(String text) async {
    return const ModerationResult.allowed();
  }
}

class SafeImageSafetyService extends ImageSafetyService {
  const SafeImageSafetyService();

  @override
  Future<ImageSafetyResult> scanImage({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    return const ImageSafetyResult.safe();
  }
}

class RejectingSecondImageSafetyService extends ImageSafetyService {
  int scanCount = 0;

  @override
  Future<ImageSafetyResult> scanImage({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    scanCount++;
    if (scanCount == 2) {
      return const ImageSafetyResult.unsafe('image_flagged');
    }
    return const ImageSafetyResult.safe();
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(XFile.fromData(Uint8List(0)));
  });

  group('CreatePostState', () {
    test('has sensible defaults', () {
      const state = CreatePostState();

      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith updates specified fields', () {
      const state = CreatePostState();

      final loading = state.copyWith(isLoading: true);
      expect(loading.isLoading, isTrue);
      expect(loading.error, isNull);
      expect(loading.isSuccess, isFalse);

      final errored = state.copyWith(error: 'Upload failed');
      expect(errored.error, 'Upload failed');

      final success = state.copyWith(isSuccess: true);
      expect(success.isSuccess, isTrue);
    });

    test('copyWith clears error on new attempt', () {
      final state = const CreatePostState().copyWith(error: 'failed');
      final retrying = state.copyWith(isLoading: true, error: null);

      expect(retrying.isLoading, isTrue);
      expect(retrying.error, isNull);
    });
  });

  group('CreatePostNotifier', () {
    test('reset returns to initial state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(createPostProvider);
      container.read(createPostProvider.notifier).reset();

      final state = container.read(createPostProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test(
      'creates image post with image_urls payload through repository',
      () async {
        final repo = MockCommunityPostRepository();
        when(
          () => repo.checkPostAllowed(any()),
        ).thenAnswer((_) async => {'allowed': true});
        when(
          () => repo.uploadPhoto(
            userId: any(named: 'userId'),
            postId: any(named: 'postId'),
            file: any(named: 'file'),
          ),
        ).thenAnswer((_) async => 'https://example.com/community.jpg');
        when(() => repo.create(any())).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            communityPostRepositoryProvider.overrideWithValue(repo),
            contentModerationServiceProvider.overrideWithValue(
              const AllowedContentModerationService(),
            ),
            imageSafetyServiceProvider.overrideWithValue(
              const SafeImageSafetyService(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(createPostProvider.notifier)
            .createPost(
              content: 'Photo post',
              postType: CommunityPostType.photo,
              images: [
                XFile.fromData(
                  Uint8List.fromList(const [1, 2, 3]),
                  name: 'photo.jpg',
                  mimeType: 'image/jpeg',
                ),
              ],
            );

        final captured =
            verify(() => repo.create(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(captured['image_urls'], ['https://example.com/community.jpg']);
        expect(captured.containsKey('image_url'), isFalse);
        expect(captured.containsKey('images'), isFalse);
        expect(container.read(createPostProvider).isSuccess, isTrue);
      },
    );

    test('scans every image before uploading any image', () async {
      final repo = MockCommunityPostRepository();
      final imageSafety = RejectingSecondImageSafetyService();
      when(
        () => repo.checkPostAllowed(any()),
      ).thenAnswer((_) async => {'allowed': true});

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          communityPostRepositoryProvider.overrideWithValue(repo),
          contentModerationServiceProvider.overrideWithValue(
            const AllowedContentModerationService(),
          ),
          imageSafetyServiceProvider.overrideWithValue(imageSafety),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(createPostProvider.notifier)
          .createPost(
            content: 'Photo post',
            postType: CommunityPostType.photo,
            images: [
              XFile.fromData(
                Uint8List.fromList(const [1, 2, 3]),
                name: 'photo-1.jpg',
                mimeType: 'image/jpeg',
              ),
              XFile.fromData(
                Uint8List.fromList(const [4, 5, 6]),
                name: 'photo-2.jpg',
                mimeType: 'image/jpeg',
              ),
            ],
          );

      expect(imageSafety.scanCount, 2);
      expect(container.read(createPostProvider).isSuccess, isFalse);
      expect(container.read(createPostProvider).error, isNotNull);
      verifyNever(
        () => repo.uploadPhoto(
          userId: any(named: 'userId'),
          postId: any(named: 'postId'),
          file: any(named: 'file'),
        ),
      );
      verifyNever(() => repo.create(any()));
    });

    test('cleans up uploaded images when post insert fails', () async {
      final repo = MockCommunityPostRepository();
      var uploadIndex = 0;
      when(
        () => repo.checkPostAllowed(any()),
      ).thenAnswer((_) async => {'allowed': true});
      when(
        () => repo.uploadPhoto(
          userId: any(named: 'userId'),
          postId: any(named: 'postId'),
          file: any(named: 'file'),
        ),
      ).thenAnswer((_) async {
        uploadIndex++;
        return 'https://example.com/community-$uploadIndex.jpg';
      });
      when(() => repo.create(any())).thenThrow(Exception('insert failed'));
      when(() => repo.deleteUploadedPhoto(any())).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          communityPostRepositoryProvider.overrideWithValue(repo),
          contentModerationServiceProvider.overrideWithValue(
            const AllowedContentModerationService(),
          ),
          imageSafetyServiceProvider.overrideWithValue(
            const SafeImageSafetyService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(createPostProvider.notifier)
          .createPost(
            content: 'Photo post',
            postType: CommunityPostType.photo,
            images: [
              XFile.fromData(
                Uint8List.fromList(const [1, 2, 3]),
                name: 'photo-1.jpg',
                mimeType: 'image/jpeg',
              ),
              XFile.fromData(
                Uint8List.fromList(const [4, 5, 6]),
                name: 'photo-2.jpg',
                mimeType: 'image/jpeg',
              ),
            ],
          );

      expect(container.read(createPostProvider).isSuccess, isFalse);
      verify(
        () => repo.deleteUploadedPhoto('https://example.com/community-1.jpg'),
      ).called(1);
      verify(
        () => repo.deleteUploadedPhoto('https://example.com/community-2.jpg'),
      ).called(1);
    });
  });
}
