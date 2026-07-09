import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/community_comment_model.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_comment_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';

CommunityComment _comment({String id = 'c1', DateTime? createdAt}) =>
    CommunityComment(
      id: id,
      postId: 'p1',
      userId: 'u1',
      content: 'Test comment',
      createdAt: createdAt ?? DateTime(2026, 4, 14),
    );

void main() {
  group('CommentFormState', () {
    test('has sensible defaults', () {
      const state = CommentFormState();

      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith updates specified fields', () {
      const state = CommentFormState();

      final loading = state.copyWith(isLoading: true);
      expect(loading.isLoading, isTrue);
      expect(loading.error, isNull);

      final errored = state.copyWith(error: 'failed');
      expect(errored.error, 'failed');
      expect(errored.isLoading, isFalse);

      final success = state.copyWith(isSuccess: true);
      expect(success.isSuccess, isTrue);
    });

    test('copyWith clears error when set to null', () {
      final state = const CommentFormState().copyWith(error: 'oops');
      expect(state.error, 'oops');

      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });
  });

  group('CommentFormNotifier', () {
    test('reset returns to initial state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Access to trigger build
      container.read(commentFormProvider);

      // Simulate state change
      container.read(commentFormProvider.notifier).reset();

      final state = container.read(commentFormProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });
  });

  group('CommentListState', () {
    test('has sensible defaults', () {
      const state = CommentListState();

      expect(state.comments, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isLoadingMore, isFalse);
      expect(state.hasMore, isTrue);
      expect(state.cursor, isNull);
      expect(state.error, isNull);
    });

    test('can hold comments', () {
      final comment = _comment();
      final state = CommentListState(comments: [comment]);

      expect(state.comments, hasLength(1));
      expect(state.comments.first.id, 'c1');
    });

    test('tracks cursor from last comment', () {
      final ts = DateTime(2026, 4, 14, 10);
      final state = CommentListState(
        comments: [_comment(createdAt: ts)],
        cursor: ts,
      );

      expect(state.cursor, ts);
    });

    test('error state preserves existing comments', () {
      final comment = _comment();
      final state = CommentListState(
        comments: [comment],
        hasMore: false,
        cursor: DateTime(2026),
        error: Exception('network error'),
      );

      expect(state.comments, hasLength(1));
      expect(state.error, isNotNull);
      expect(state.hasMore, isFalse);
    });
  });

  group('visibleCommentsProvider', () {
    final comments = [
      _comment(id: 'c1'),
      CommunityComment(
        id: 'c2',
        postId: 'p1',
        userId: 'blocked-user',
        content: 'Blocked comment',
        createdAt: DateTime(2026, 4, 14),
      ),
      CommunityComment(
        id: 'c3',
        postId: 'p1',
        userId: 'muted-user',
        content: 'Muted comment',
        createdAt: DateTime(2026, 4, 14),
      ),
    ];

    ProviderContainer createContainer({
      List<String> blocked = const [],
      List<String> muted = const [],
    }) {
      return ProviderContainer(
        overrides: [
          commentListProvider(
            'p1',
          ).overrideWith(() => _FakeCommentListNotifier(comments)),
          blockedUsersProvider.overrideWith(
            () => _FakeBlockedUsersNotifier(blocked),
          ),
          mutedUsersProvider.overrideWith(
            () => _FakeMutedUsersNotifier(muted),
          ),
        ],
      );
    }

    test('returns all comments when nothing is blocked or muted', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final visible = container.read(visibleCommentsProvider('p1'));
      expect(visible.map((c) => c.id), ['c1', 'c2', 'c3']);
    });

    test('filters out blocked authors', () {
      final container = createContainer(blocked: ['blocked-user']);
      addTearDown(container.dispose);

      final visible = container.read(visibleCommentsProvider('p1'));
      expect(visible.map((c) => c.id), ['c1', 'c3']);
    });

    test('filters out muted authors', () {
      final container = createContainer(muted: ['muted-user']);
      addTearDown(container.dispose);

      final visible = container.read(visibleCommentsProvider('p1'));
      expect(visible.map((c) => c.id), ['c1', 'c2']);
    });

    test('filters out both blocked and muted authors', () {
      final container = createContainer(
        blocked: ['blocked-user'],
        muted: ['muted-user'],
      );
      addTearDown(container.dispose);

      final visible = container.read(visibleCommentsProvider('p1'));
      expect(visible.map((c) => c.id), ['c1']);
    });
  });
}

class _FakeCommentListNotifier extends CommentListNotifier {
  _FakeCommentListNotifier(this._comments) : super('p1');

  final List<CommunityComment> _comments;

  @override
  CommentListState build() => CommentListState(comments: _comments);

  @override
  Future<void> fetchInitial() async {}

  @override
  Future<void> fetchMore() async {}
}

class _FakeBlockedUsersNotifier extends BlockedUsersNotifier {
  _FakeBlockedUsersNotifier(this._ids);

  final List<String> _ids;

  @override
  List<String> build() => _ids;
}

class _FakeMutedUsersNotifier extends MutedUsersNotifier {
  _FakeMutedUsersNotifier(this._ids);

  final List<String> _ids;

  @override
  List<String> build() => _ids;
}
