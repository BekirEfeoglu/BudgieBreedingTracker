import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';
import 'package:budgie_breeding_tracker/features/community/screens/community_search_screen.dart';

void main() {
  GoRouter buildRouter(Widget child) {
    return GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(path: '/search', builder: (_, __) => child),
        GoRoute(
          path: '/community/user/:userId',
          builder: (_, __) => const Scaffold(body: Text('user_posts')),
        ),
      ],
    );
  }

  ProviderScope buildScope({List<CommunityPost>? posts}) {
    return ProviderScope(
      overrides: [
        supabaseInitializedProvider.overrideWithValue(false),
        currentUserIdProvider.overrideWithValue('me'),
        communityFeedProvider
            .overrideWith(() => _FakeFeedNotifier(posts: posts ?? const [])),
      ],
      child: MaterialApp.router(
        routerConfig: buildRouter(const CommunitySearchScreen()),
      ),
    );
  }

  group('CommunitySearchScreen', () {
    testWidgets('shows search text field', (tester) async {
      await tester.pumpWidget(buildScope());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      // Verify autofocus property
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autofocus, isTrue);

      // Clean up widget tree before dispose to avoid ref usage in dispose
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    });

    testWidgets('shows search hint', (tester) async {
      await tester.pumpWidget(buildScope());
      await tester.pump();

      expect(find.text('community.search_hint'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    });

    testWidgets('shows suggestions when no query', (tester) async {
      final posts = [
        const CommunityPost(
          id: 'p1',
          userId: 'u1',
          username: 'Ali',
          tags: ['budgie'],
          likeCount: 5,
        ),
      ];

      await tester.pumpWidget(buildScope(posts: posts));
      await tester.pump();

      expect(find.text('community.popular_tags'), findsOneWidget);
      expect(find.text('community.suggested_users'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    });

    testWidgets('shows tabs when query entered', (tester) async {
      await tester.pumpWidget(buildScope());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'budgie');
      await tester.pump();

      expect(find.text('community.search_posts'), findsOneWidget);
      expect(find.text('community.search_users'), findsOneWidget);
      expect(find.text('community.search_tags'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    });
  });
}

class _FakeFeedNotifier extends CommunityFeedNotifier {
  final List<CommunityPost> _posts;

  _FakeFeedNotifier({List<CommunityPost>? posts}) : _posts = posts ?? const [];

  @override
  FeedState build() => FeedState(posts: _posts, isLoading: false);

  @override
  Future<void> fetchInitial() async {}

  @override
  Future<void> fetchMore() async {}
}
