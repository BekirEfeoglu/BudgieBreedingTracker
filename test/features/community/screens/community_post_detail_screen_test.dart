@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_comment_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_post_providers.dart';
import 'package:budgie_breeding_tracker/features/community/screens/community_post_detail_screen.dart';

void main() {
  GoRouter buildRouter(Widget child) {
    return GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(path: '/test', builder: (_, __) => child),
        GoRoute(
          path: '/community/user/:userId',
          builder: (_, __) => const Scaffold(body: Text('user_posts')),
        ),
      ],
    );
  }

  ProviderScope buildScope(Widget child) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('me'),
        communityPostByIdProvider('post-1').overrideWith((ref) async => null),
        commentListProvider('post-1').overrideWith(
          () => _FakeCommentListNotifier(),
        ),
        commentFormProvider.overrideWith(() => _FakeCommentFormNotifier()),
      ],
      child: MaterialApp.router(routerConfig: buildRouter(child)),
    );
  }

  group('CommunityPostDetailScreen', () {
    testWidgets('shows app bar with detail title', (tester) async {
      await tester.pumpWidget(
        buildScope(const CommunityPostDetailScreen(postId: 'post-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.post_detail')), findsOneWidget);
    });

    testWidgets('shows post not found when post is null', (tester) async {
      await tester.pumpWidget(
        buildScope(const CommunityPostDetailScreen(postId: 'post-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.post_not_found')), findsOneWidget);
    });

    testWidgets('shows comments header', (tester) async {
      await tester.pumpWidget(
        buildScope(const CommunityPostDetailScreen(postId: 'post-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.comments')), findsOneWidget);
    });

    testWidgets('shows no comments text when empty', (tester) async {
      await tester.pumpWidget(
        buildScope(const CommunityPostDetailScreen(postId: 'post-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.no_comments')), findsOneWidget);
    });

    testWidgets('has comment input at bottom', (tester) async {
      await tester.pumpWidget(
        buildScope(const CommunityPostDetailScreen(postId: 'post-1')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders guide article header for guide posts', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('me'),
            communityPostByIdProvider('post-1').overrideWith(
              (ref) async => CommunityPost(
                id: 'post-1',
                userId: 'u1',
                username: 'Guide Author',
                title: 'Guide Title',
                content: '# Baslik Bir\nDetayli guide body\n## Baslik Iki',
                postType: CommunityPostType.guide,
                createdAt: DateTime(2026, 4, 14),
              ),
            ),
            commentListProvider('post-1').overrideWith(
              () => _FakeCommentListNotifier(),
            ),
            commentFormProvider.overrideWith(() => _FakeCommentFormNotifier()),
          ],
          child: MaterialApp.router(
            routerConfig: buildRouter(
              const CommunityPostDetailScreen(postId: 'post-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(l10n('community.guide_detail_kicker').toUpperCase()),
        findsOneWidget,
      );
      expect(find.text('Guide Title'), findsWidgets);
      expect(find.text(l10n('community.guide_outline_title')), findsOneWidget);
      expect(find.text('Baslik Bir'), findsWidgets);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n('community.guide_discussion_title')),
        findsOneWidget,
      );
    });
  });
}

class _FakeCommentListNotifier extends CommentListNotifier {
  _FakeCommentListNotifier() : super('post-1');

  @override
  CommentListState build() => const CommentListState();

  @override
  Future<void> fetchInitial() async {}

  @override
  Future<void> fetchMore() async {}
}

class _FakeCommentFormNotifier extends CommentFormNotifier {
  @override
  CommentFormState build() => const CommentFormState();

  @override
  Future<void> addComment({
    required String postId,
    required String content,
  }) async {}
}
