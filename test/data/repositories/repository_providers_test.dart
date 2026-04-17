import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/birds_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/bird_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_comment_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_post_cache.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_post_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_social_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/remote_source_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

class _MockBirdsDao extends Mock implements BirdsDao {}

class _MockBirdRemoteSource extends Mock implements BirdRemoteSource {}

class _MockSyncMetadataDao extends Mock implements SyncMetadataDao {}

class _MockCommunityPostRemoteSource extends Mock
    implements CommunityPostRemoteSource {}

class _MockCommunityCommentRemoteSource extends Mock
    implements CommunityCommentRemoteSource {}

class _MockCommunitySocialRemoteSource extends Mock
    implements CommunitySocialRemoteSource {}

class _MockCommunityPostCache extends Mock implements CommunityPostCache {}

Bird _bird() => const Bird(
  id: 'bird-1',
  name: 'Kiwi',
  gender: BirdGender.male,
  userId: 'user-1',
);

void main() {
  setUpAll(() {
    registerFallbackValue(_bird());
  });

  group('repository providers', () {
    test(
      'birdRepositoryProvider uses overridden DAO for count lookups',
      () async {
        final birdsDao = _MockBirdsDao();
        final remoteSource = _MockBirdRemoteSource();
        final syncDao = _MockSyncMetadataDao();
        when(() => birdsDao.getCount('user-1')).thenAnswer((_) async => 7);

        final container = ProviderContainer(
          overrides: [
            birdsDaoProvider.overrideWithValue(birdsDao),
            birdRemoteSourceProvider.overrideWithValue(remoteSource),
            syncMetadataDaoProvider.overrideWithValue(syncDao),
          ],
        );
        addTearDown(container.dispose);

        final result = await container
            .read(birdRepositoryProvider)
            .getCount('user-1');

        expect(result, 7);
        verify(() => birdsDao.getCount('user-1')).called(1);
        verifyNever(() => remoteSource.upsert(any()));
      },
    );

    test(
      'birdRepositoryProvider uses overridden remote source and sync DAO for push',
      () async {
        final birdsDao = _MockBirdsDao();
        final remoteSource = _MockBirdRemoteSource();
        final syncDao = _MockSyncMetadataDao();
        when(() => remoteSource.upsert(any())).thenAnswer((_) async {});
        when(
          () => syncDao.deleteByRecord('birds', 'bird-1'),
        ).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            birdsDaoProvider.overrideWithValue(birdsDao),
            birdRemoteSourceProvider.overrideWithValue(remoteSource),
            syncMetadataDaoProvider.overrideWithValue(syncDao),
          ],
        );
        addTearDown(container.dispose);

        await container.read(birdRepositoryProvider).push(_bird());

        verify(() => remoteSource.upsert(any())).called(1);
        verify(() => syncDao.deleteByRecord('birds', 'bird-1')).called(1);
      },
    );

    test(
      'communityPostRepositoryProvider uses overridden sources and cache',
      () async {
        final postSource = _MockCommunityPostRemoteSource();
        final socialSource = _MockCommunitySocialRemoteSource();
        final cache = _MockCommunityPostCache();
        when(
          () => socialSource.fetchAllBookmarkedPostIds('user-1'),
        ).thenAnswer((_) async => ['post-1']);
        when(() => postSource.fetchByIds(['post-1'])).thenAnswer(
          (_) async => [
            {
              'id': 'post-1',
              'user_id': 'author-1',
              'username': 'author',
              'content': 'hello',
              'post_type': 'general',
              'created_at': '2026-01-01T00:00:00Z',
              'like_count': 0,
              'comment_count': 0,
            },
          ],
        );
        when(
          () => socialSource.fetchPostSocialState('user-1', ['post-1']),
        ).thenAnswer(
          (_) async => (liked: <String>{}, bookmarked: {'post-1'}),
        );

        final container = ProviderContainer(
          overrides: [
            communityPostRemoteSourceProvider.overrideWithValue(postSource),
            communitySocialRemoteSourceProvider.overrideWithValue(socialSource),
            communityPostCacheProvider.overrideWithValue(cache),
          ],
        );
        addTearDown(container.dispose);

        final result = await container
            .read(communityPostRepositoryProvider)
            .getBookmarked(currentUserId: 'user-1');

        expect(result, hasLength(1));
        expect(result.single.id, 'post-1');
        expect(result.single.isBookmarkedByMe, isTrue);
        verify(
          () => socialSource.fetchAllBookmarkedPostIds('user-1'),
        ).called(1);
        verify(() => postSource.fetchByIds(['post-1'])).called(1);
      },
    );

    test(
      'communitySocialRepositoryProvider uses overridden source for toggleBookmark',
      () async {
        final source = _MockCommunitySocialRemoteSource();
        when(
          () => source.isPostBookmarked('user-1', 'post-1'),
        ).thenAnswer((_) async => false);
        when(
          () => source.bookmarkPost('user-1', 'post-1'),
        ).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            communitySocialRemoteSourceProvider.overrideWithValue(source),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(communitySocialRepositoryProvider)
            .toggleBookmark(userId: 'user-1', postId: 'post-1');

        verify(() => source.isPostBookmarked('user-1', 'post-1')).called(1);
        verify(() => source.bookmarkPost('user-1', 'post-1')).called(1);
        verifyNever(() => source.unbookmarkPost(any(), any()));
      },
    );

    test(
      'communityCommentRepositoryProvider uses overridden sources',
      () async {
        final commentSource = _MockCommunityCommentRemoteSource();
        final socialSource = _MockCommunitySocialRemoteSource();
        when(() => commentSource.fetchByPost('post-1')).thenAnswer(
          (_) async => [
            {
              'id': 'comment-1',
              'post_id': 'post-1',
              'user_id': 'user-2',
              'username': 'commenter',
              'content': 'nice',
              'like_count': 2,
              'created_at': '2026-01-01T00:00:00Z',
            },
          ],
        );
        when(
          () => socialSource.fetchLikedCommentIds('user-1', ['comment-1']),
        ).thenAnswer((_) async => {'comment-1'});

        final container = ProviderContainer(
          overrides: [
            communityCommentRemoteSourceProvider.overrideWithValue(
              commentSource,
            ),
            communitySocialRemoteSourceProvider.overrideWithValue(socialSource),
          ],
        );
        addTearDown(container.dispose);

        final result = await container
            .read(communityCommentRepositoryProvider)
            .getByPost(postId: 'post-1', currentUserId: 'user-1');

        expect(result, hasLength(1));
        expect(result.single.id, 'comment-1');
        expect(result.single.isLikedByMe, isTrue);
        verify(() => commentSource.fetchByPost('post-1')).called(1);
        verify(
          () => socialSource.fetchLikedCommentIds('user-1', ['comment-1']),
        ).called(1);
      },
    );
  });
}
