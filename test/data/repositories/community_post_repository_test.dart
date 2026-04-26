@Tags(['community'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/remote/api/community_post_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_social_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_service.dart';
import 'package:budgie_breeding_tracker/data/repositories/community_post_repository.dart';

class MockCommunityPostRemoteSource extends Mock
    implements CommunityPostRemoteSource {}

class MockCommunitySocialRemoteSource extends Mock
    implements CommunitySocialRemoteSource {}

class MockStorageService extends Mock implements StorageService {}

Map<String, dynamic> _makePostRow({
  required String id,
  String userId = 'u1',
  String content = 'Test content',
  String username = 'TestUser',
  int likeCount = 0,
  int commentCount = 0,
  String postType = 'general',
  String? title,
}) => {
  'id': id,
  'user_id': userId,
  'content': content,
  'username': username,
  'avatar_url': null,
  'like_count': likeCount,
  'comment_count': commentCount,
  'post_type': postType,
  'is_deleted': false,
  'created_at': '2026-03-15T10:00:00Z',
  if (title != null) 'title': title,
};

void main() {
  late MockCommunityPostRemoteSource postSource;
  late MockCommunitySocialRemoteSource socialSource;
  late CommunityPostRepository repository;

  setUp(() {
    postSource = MockCommunityPostRemoteSource();
    socialSource = MockCommunitySocialRemoteSource();

    repository = CommunityPostRepository(
      postSource: postSource,
      socialSource: socialSource,
    );
  });

  void stubSocialEmpty() {
    when(
      () => socialSource.fetchPostSocialState(any(), any()),
    ).thenAnswer((_) async => (liked: <String>{}, bookmarked: <String>{}));
  }

  group('getFeed', () {
    test('returns enriched posts with social state', () async {
      when(() => postSource.fetchFeed(limit: 20, before: null)).thenAnswer(
        (_) async => [
          _makePostRow(id: 'p1', likeCount: 5, commentCount: 2),
          _makePostRow(id: 'p2', likeCount: 1),
        ],
      );

      when(
        () => socialSource.fetchPostSocialState('u1', ['p1', 'p2']),
      ).thenAnswer((_) async => (liked: {'p1'}, bookmarked: {'p2'}));

      final posts = await repository.getFeed(currentUserId: 'u1');

      expect(posts, hasLength(2));
      expect(posts[0].id, 'p1');
      expect(posts[0].likeCount, 5);
      expect(posts[0].commentCount, 2);
      expect(posts[0].isLikedByMe, isTrue);
      expect(posts[0].isBookmarkedByMe, isFalse);
      expect(posts[1].id, 'p2');
      expect(posts[1].isLikedByMe, isFalse);
      expect(posts[1].isBookmarkedByMe, isTrue);
    });

    test('parses schema image_urls from feed rows', () async {
      when(() => postSource.fetchFeed(limit: 20, before: null)).thenAnswer(
        (_) async => [
          _makePostRow(id: 'p1')
            ..['image_urls'] = [
              'https://example.com/1.jpg',
              'https://example.com/2.jpg',
            ],
        ],
      );
      stubSocialEmpty();

      final posts = await repository.getFeed(currentUserId: 'u1');

      expect(posts.single.imageUrls, [
        'https://example.com/1.jpg',
        'https://example.com/2.jpg',
      ]);
    });

    test('skips social enrichment for anonymous user', () async {
      when(
        () => postSource.fetchFeed(limit: 20, before: null),
      ).thenAnswer((_) async => [_makePostRow(id: 'p1')]);

      final posts = await repository.getFeed(currentUserId: 'anonymous');

      expect(posts, hasLength(1));
      expect(posts[0].isLikedByMe, isFalse);
      expect(posts[0].isBookmarkedByMe, isFalse);
      verifyNever(() => socialSource.fetchPostSocialState(any(), any()));
    });

    test('returns empty list when no posts', () async {
      when(
        () => postSource.fetchFeed(limit: 20, before: null),
      ).thenAnswer((_) async => []);

      final posts = await repository.getFeed(currentUserId: 'u1');

      expect(posts, isEmpty);
    });

    test('handles social fetch failure gracefully', () async {
      when(
        () => postSource.fetchFeed(limit: 20, before: null),
      ).thenAnswer((_) async => [_makePostRow(id: 'p1')]);
      // The remote source swallows RPC errors and returns empty sets; the
      // repository should still render posts with neutral social state.
      when(
        () => socialSource.fetchPostSocialState(any(), any()),
      ).thenAnswer((_) async => (liked: <String>{}, bookmarked: <String>{}));

      final posts = await repository.getFeed(currentUserId: 'u1');

      expect(posts, hasLength(1));
      expect(posts[0].isLikedByMe, isFalse);
      expect(posts[0].isBookmarkedByMe, isFalse);
    });
  });

  group('getById', () {
    test('returns post when found', () async {
      when(
        () => postSource.fetchById('p1'),
      ).thenAnswer((_) async => _makePostRow(id: 'p1', title: 'Test Title'));
      stubSocialEmpty();

      final post = await repository.getById(postId: 'p1', currentUserId: 'u1');

      expect(post, isNotNull);
      expect(post!.id, 'p1');
      expect(post.title, 'Test Title');
    });

    test('returns null when not found', () async {
      when(() => postSource.fetchById('missing')).thenAnswer((_) async => null);

      final post = await repository.getById(
        postId: 'missing',
        currentUserId: 'u1',
      );

      expect(post, isNull);
    });
  });

  group('getByUser', () {
    test('fetches posts by target user', () async {
      when(() => postSource.fetchByUser('u2', limit: 50)).thenAnswer(
        (_) async => [
          _makePostRow(id: 'p1', userId: 'u2'),
          _makePostRow(id: 'p2', userId: 'u2'),
        ],
      );
      stubSocialEmpty();

      final posts = await repository.getByUser(
        targetUserId: 'u2',
        currentUserId: 'u1',
      );

      expect(posts, hasLength(2));
      verify(() => postSource.fetchByUser('u2', limit: 50)).called(1);
    });
  });

  group('getBookmarked', () {
    test('returns empty for anonymous user', () async {
      final posts = await repository.getBookmarked(currentUserId: 'anonymous');

      expect(posts, isEmpty);
      verifyNever(() => socialSource.fetchAllBookmarkedPostIds(any()));
    });

    test('returns empty when no bookmarks', () async {
      when(
        () => socialSource.fetchAllBookmarkedPostIds('u1'),
      ).thenAnswer((_) async => []);

      final posts = await repository.getBookmarked(currentUserId: 'u1');

      expect(posts, isEmpty);
    });

    test('fetches and sorts bookmarked posts by date descending', () async {
      when(
        () => socialSource.fetchAllBookmarkedPostIds('u1'),
      ).thenAnswer((_) async => ['p1', 'p2']);
      when(() => postSource.fetchByIds(['p1', 'p2'])).thenAnswer(
        (_) async => [
          _makePostRow(id: 'p1')..['created_at'] = '2026-03-14T10:00:00Z',
          _makePostRow(id: 'p2')..['created_at'] = '2026-03-15T10:00:00Z',
        ],
      );
      when(
        () => socialSource.fetchPostSocialState('u1', any()),
      ).thenAnswer((_) async => (liked: <String>{}, bookmarked: {'p1', 'p2'}));

      final posts = await repository.getBookmarked(currentUserId: 'u1');

      expect(posts, hasLength(2));
      expect(posts[0].id, 'p2');
      expect(posts[1].id, 'p1');
    });
  });

  group('create', () {
    test('delegates to postSource.insert', () async {
      when(() => postSource.insert(any())).thenAnswer((_) async {});

      final data = {'id': 'p1', 'content': 'New post'};
      await repository.create(data);

      verify(() => postSource.insert(data)).called(1);
    });

    test('checkPostAllowed delegates to postSource', () async {
      when(
        () => postSource.checkPostAllowed('hash'),
      ).thenAnswer((_) async => {'allowed': true});

      final result = await repository.checkPostAllowed('hash');

      expect(result['allowed'], isTrue);
      verify(() => postSource.checkPostAllowed('hash')).called(1);
    });
  });

  group('storage cleanup', () {
    test('deleteUploadedPhoto deletes parsed community storage path', () async {
      final storage = MockStorageService();
      final repository = CommunityPostRepository(
        postSource: postSource,
        socialSource: socialSource,
        storageService: storage,
      );
      when(
        () => storage.deleteCommunityPhoto(
          storagePath: any(named: 'storagePath'),
        ),
      ).thenAnswer((_) async {});

      await repository.deleteUploadedPhoto(
        'https://project.supabase.co/storage/v1/object/sign/'
        'community-photos/user-1/post-1/photo.jpg?token=abc',
      );

      verify(
        () => storage.deleteCommunityPhoto(
          storagePath: 'user-1/post-1/photo.jpg',
        ),
      ).called(1);
    });

    test(
      'deleteUploadedPhoto ignores URLs outside the community bucket',
      () async {
        final storage = MockStorageService();
        final repository = CommunityPostRepository(
          postSource: postSource,
          socialSource: socialSource,
          storageService: storage,
        );

        await repository.deleteUploadedPhoto(
          'https://project.supabase.co/storage/v1/object/sign/'
          'bird-photos/user-1/bird-1/photo.jpg',
        );

        verifyNever(
          () => storage.deleteCommunityPhoto(
            storagePath: any(named: 'storagePath'),
          ),
        );
      },
    );
  });

  group('delete', () {
    test('delegates to postSource.softDelete', () async {
      when(() => postSource.softDelete(any(), any())).thenAnswer((_) async {});

      await repository.delete(postId: 'p1', userId: 'u1');

      verify(() => postSource.softDelete('p1', 'u1')).called(1);
    });
  });

  group('search', () {
    test('returns matching posts', () async {
      when(() => postSource.search('budgie', limit: 30)).thenAnswer(
        (_) async => [
          _makePostRow(id: 'p1', content: 'My budgie is beautiful'),
        ],
      );
      stubSocialEmpty();

      final posts = await repository.search(
        query: 'budgie',
        currentUserId: 'u1',
      );

      expect(posts, hasLength(1));
      expect(posts[0].content, 'My budgie is beautiful');
    });

    test('returns empty for no matches', () async {
      when(
        () => postSource.search('xyz123', limit: 30),
      ).thenAnswer((_) async => []);

      final posts = await repository.search(
        query: 'xyz123',
        currentUserId: 'u1',
      );

      expect(posts, isEmpty);
    });
  });

  group('post parsing', () {
    test('parses post type correctly', () async {
      when(() => postSource.fetchFeed(limit: 20, before: null)).thenAnswer(
        (_) async => [
          _makePostRow(id: 'p1', postType: 'question'),
          _makePostRow(id: 'p2', postType: 'invalid_type'),
        ],
      );
      stubSocialEmpty();

      final posts = await repository.getFeed(currentUserId: 'u1');

      expect(posts[0].postType.name, 'question');
      expect(posts[1].postType.name, 'unknown');
    });

    test('skips rows with missing required fields', () async {
      when(() => postSource.fetchFeed(limit: 20, before: null)).thenAnswer(
        (_) async => [
          {'id': 'p1'},
          _makePostRow(id: 'p2'),
        ],
      );
      stubSocialEmpty();

      final posts = await repository.getFeed(currentUserId: 'u1');

      expect(posts, hasLength(1));
      expect(posts[0].id, 'p2');
    });
  });
}
