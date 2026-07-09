import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_post_providers.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockCommunityPostRepository mockRepo;

  setUp(() {
    mockRepo = MockCommunityPostRepository();
  });

  group('PostEditNotifier', () {
    test('editPost updates feed state and returns null on success', () async {
      when(
        () => mockRepo.update(
          postId: any(named: 'postId'),
          content: any(named: 'content'),
        ),
      ).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          communityPostRepositoryProvider.overrideWithValue(mockRepo),
          communityFeedProvider.overrideWith(
            () => _TestFeedNotifier([_makePost('post-1', content: 'eski')]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final errorKey = await container
          .read(postEditProvider.notifier)
          .editPost('post-1', 'yeni icerik');

      expect(errorKey, isNull);
      verify(
        () => mockRepo.update(postId: 'post-1', content: 'yeni icerik'),
      ).called(1);

      final updated = container
          .read(communityFeedProvider)
          .posts
          .firstWhere((p) => p.id == 'post-1');
      expect(updated.content, 'yeni icerik');
      expect(updated.isEdited, isTrue);
    });

    test(
      'editPost returns generic error key and leaves feed intact on failure',
      () async {
        when(
          () => mockRepo.update(
            postId: any(named: 'postId'),
            content: any(named: 'content'),
          ),
        ).thenThrow(Exception('some other failure'));

        final container = ProviderContainer(
          overrides: [
            communityPostRepositoryProvider.overrideWithValue(mockRepo),
            communityFeedProvider.overrideWith(
              () => _TestFeedNotifier([_makePost('post-1', content: 'eski')]),
            ),
          ],
        );
        addTearDown(container.dispose);

        final errorKey = await container
            .read(postEditProvider.notifier)
            .editPost('post-1', 'x');

        expect(errorKey, 'community.edit_error');

        final unchanged = container
            .read(communityFeedProvider)
            .posts
            .firstWhere((p) => p.id == 'post-1');
        expect(unchanged.content, 'eski');
        expect(unchanged.isEdited, isFalse);
      },
    );

    test(
      'editPost returns edit_window_expired key when repo throws that error',
      () async {
        when(
          () => mockRepo.update(
            postId: any(named: 'postId'),
            content: any(named: 'content'),
          ),
        ).thenThrow(Exception('edit_window_expired'));

        final container = ProviderContainer(
          overrides: [
            communityPostRepositoryProvider.overrideWithValue(mockRepo),
            communityFeedProvider.overrideWith(
              () => _TestFeedNotifier([_makePost('post-1', content: 'eski')]),
            ),
          ],
        );
        addTearDown(container.dispose);

        final errorKey = await container
            .read(postEditProvider.notifier)
            .editPost('post-1', 'x');

        expect(errorKey, 'community.edit_window_expired');

        final unchanged = container
            .read(communityFeedProvider)
            .posts
            .firstWhere((p) => p.id == 'post-1');
        expect(unchanged.content, 'eski');
        expect(unchanged.isEdited, isFalse);
      },
    );
  });

  group('CommunityFeedNotifier.applyPostEdit', () {
    test('rewrites content and editedAt for the matching post', () {
      final container = ProviderContainer(
        overrides: [
          communityPostRepositoryProvider.overrideWithValue(mockRepo),
          communityFeedProvider.overrideWith(
            () => _TestFeedNotifier([
              _makePost('post-1', content: 'eski'),
              _makePost('post-2', content: 'digeri'),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(communityFeedProvider.notifier);
      notifier.applyPostEdit('post-1', 'guncel', DateTime.utc(2026, 7, 3));

      final posts = container.read(communityFeedProvider).posts;
      final edited = posts.firstWhere((p) => p.id == 'post-1');
      final untouched = posts.firstWhere((p) => p.id == 'post-2');

      expect(edited.content, 'guncel');
      expect(edited.editedAt, DateTime.utc(2026, 7, 3));
      expect(edited.isEdited, isTrue);
      expect(untouched.content, 'digeri');
      expect(untouched.editedAt, isNull);
    });
  });
}

CommunityPost _makePost(
  String id, {
  String content = 'content',
  DateTime? createdAt,
}) {
  return CommunityPost(
    id: id,
    userId: 'u1',
    username: 'user',
    content: content,
    createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
  );
}

/// Test notifier that skips Supabase calls and just sets initial posts.
/// Mirrors `_TestFeedNotifier` in community_feed_providers_test.dart.
class _TestFeedNotifier extends CommunityFeedNotifier {
  final List<CommunityPost> _initialPosts;

  _TestFeedNotifier(this._initialPosts);

  @override
  FeedState build() =>
      FeedState(posts: _initialPosts, isLoading: false, hasMore: false);
}
