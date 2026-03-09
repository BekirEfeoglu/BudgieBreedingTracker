import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_post_providers.dart';
import 'package:budgie_breeding_tracker/features/community/screens/community_bookmarks_screen.dart';

void main() {
  GoRouter buildRouter(Widget child) {
    return GoRouter(
      initialLocation: '/bookmarks',
      routes: [
        GoRoute(path: '/bookmarks', builder: (_, __) => child),
        GoRoute(
          path: '/community/post/:postId',
          builder: (_, __) => const Scaffold(body: Text('post_detail')),
        ),
      ],
    );
  }

  group('CommunityBookmarksScreen', () {
    testWidgets('shows app bar with bookmarks title', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          bookmarkedPostsProvider.overrideWith(
            (ref) async => <CommunityPost>[],
          ),
        ],
        child: MaterialApp.router(
          routerConfig: buildRouter(const CommunityBookmarksScreen()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('community.bookmarks'), findsOneWidget);
    });

    testWidgets('shows empty state when no bookmarks', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          bookmarkedPostsProvider.overrideWith(
            (ref) async => <CommunityPost>[],
          ),
        ],
        child: MaterialApp.router(
          routerConfig: buildRouter(const CommunityBookmarksScreen()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('community.no_bookmarks'), findsOneWidget);
      expect(find.text('community.no_bookmarks_hint'), findsOneWidget);
    });
  });
}
