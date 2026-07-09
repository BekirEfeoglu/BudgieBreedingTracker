import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_post_cache.dart';

void main() {
  late DateTime currentTime;
  late CommunityPostCache cache;

  CommunityPost createPost(String id) => CommunityPost(
    id: id,
    userId: 'user-1',
    content: 'Test post $id',
    postType: CommunityPostType.general,
  );

  setUp(() {
    currentTime = DateTime(2025, 6, 1, 12, 0);
    cache = CommunityPostCache.withClock(
      () => currentTime,
      ttl: const Duration(minutes: 5),
    );
  });

  group('Feed cache', () {
    test('getFeed returns null for missing key', () {
      expect(cache.getFeed('page-1'), isNull);
    });

    test('putFeed then getFeed returns cached data', () {
      final posts = [createPost('p1'), createPost('p2')];
      cache.putFeed('page-1', posts);

      final result = cache.getFeed('page-1');
      expect(result, isNotNull);
      expect(result, hasLength(2));
      expect(result!.first.id, 'p1');
    });

    test('getFeed returns null after TTL expires', () {
      final posts = [createPost('p1')];
      cache.putFeed('page-1', posts);

      // Advance time past TTL
      currentTime = currentTime.add(const Duration(minutes: 6));

      expect(cache.getFeed('page-1'), isNull);
    });

    test('getFeed returns data before TTL expires', () {
      final posts = [createPost('p1')];
      cache.putFeed('page-1', posts);

      // Advance time but still within TTL
      currentTime = currentTime.add(const Duration(minutes: 4));

      expect(cache.getFeed('page-1'), isNotNull);
    });

    test('different keys are independent', () {
      cache.putFeed('page-1', [createPost('p1')]);
      cache.putFeed('page-2', [createPost('p2')]);

      expect(cache.getFeed('page-1')!.first.id, 'p1');
      expect(cache.getFeed('page-2')!.first.id, 'p2');
    });
  });

  group('Post cache', () {
    test('getPost returns null for missing id', () {
      expect(cache.getPost('unknown'), isNull);
    });

    test('putPost then getPost returns cached post', () {
      final post = createPost('p1');
      cache.putPost(post);

      final result = cache.getPost('p1');
      expect(result, isNotNull);
      expect(result!.id, 'p1');
    });

    test('getPost returns null after TTL expires', () {
      cache.putPost(createPost('p1'));

      currentTime = currentTime.add(const Duration(minutes: 6));

      expect(cache.getPost('p1'), isNull);
    });

    test('getPost returns data before TTL expires', () {
      cache.putPost(createPost('p1'));

      currentTime = currentTime.add(const Duration(minutes: 4));

      expect(cache.getPost('p1'), isNotNull);
    });
  });

  group('Invalidation', () {
    test('invalidateAll clears both feed and post caches', () {
      cache.putFeed('page-1', [createPost('p1')]);
      cache.putPost(createPost('p2'));

      cache.invalidateAll();

      expect(cache.getFeed('page-1'), isNull);
      expect(cache.getPost('p2'), isNull);
    });

    test('invalidatePost removes specific post and clears feed cache', () {
      cache.putPost(createPost('p1'));
      cache.putPost(createPost('p2'));
      cache.putFeed('page-1', [createPost('p1'), createPost('p2')]);

      cache.invalidatePost('p1');

      expect(cache.getPost('p1'), isNull);
      expect(cache.getPost('p2'), isNotNull);
      // Feed cache should also be cleared
      expect(cache.getFeed('page-1'), isNull);
    });
  });

  group('Edge cases', () {
    test('putFeed with empty list', () {
      cache.putFeed('empty', []);
      expect(cache.getFeed('empty'), isNotNull);
      expect(cache.getFeed('empty'), isEmpty);
    });

    test('overwriting existing feed entry', () {
      cache.putFeed('page-1', [createPost('p1')]);
      cache.putFeed('page-1', [createPost('p2')]);

      expect(cache.getFeed('page-1')!.first.id, 'p2');
    });

    test('overwriting existing post entry', () {
      cache.putPost(createPost('p1'));
      const updated = CommunityPost(
        id: 'p1',
        userId: 'user-1',
        content: 'Updated content',
      );
      cache.putPost(updated);

      expect(cache.getPost('p1')!.content, 'Updated content');
    });

    test('exact TTL boundary returns null (>= comparison)', () {
      cache.putFeed('page-1', [createPost('p1')]);

      // Advance exactly to TTL
      currentTime = currentTime.add(const Duration(minutes: 5));

      expect(cache.getFeed('page-1'), isNull);
    });
  });
}
