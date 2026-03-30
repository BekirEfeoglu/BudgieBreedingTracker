import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
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
        commentsForPostProvider('post-1').overrideWith((ref) async => []),
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
  });
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
