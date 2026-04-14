@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        currentUserIdProvider.overrideWithValue('me'),
        communityFeedProvider.overrideWith(
          () => _FakeFeedNotifier(posts: posts ?? const []),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: buildRouter(const CommunitySearchScreen()),
      ),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

      expect(find.text(l10n('community.search_hint')), findsOneWidget);

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

      expect(find.text(l10n('community.popular_tags')), findsOneWidget);
      expect(find.text(l10n('community.suggested_users')), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    });

    testWidgets('shows tabs when query entered', (tester) async {
      await tester.pumpWidget(buildScope());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'budgie');
      await tester.pump();

      expect(find.text(l10n('community.search_posts')), findsOneWidget);
      expect(find.text(l10n('community.search_users')), findsOneWidget);
      expect(find.text(l10n('community.search_tags')), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    });

    testWidgets('TabBar is always in widget tree (no layout shift)', (tester) async {
      await tester.pumpWidget(buildScope());
      await tester.pump();

      // TabBar should be present in the widget tree even without a query
      expect(find.byType(TabBar), findsOneWidget);
      // AnimatedOpacity wrapping the TabBar should have opacity 0 (invisible but present)
      final tabBarFinder = find.byType(TabBar);
      final animatedOpacityFinder = find.ancestor(
        of: tabBarFinder,
        matching: find.byType(AnimatedOpacity),
      );
      expect(animatedOpacityFinder, findsOneWidget);
      final opacity = tester.widget<AnimatedOpacity>(animatedOpacityFinder);
      expect(opacity.opacity, 0.0);

      // After typing a query the TabBar's AnimatedOpacity should become 1.0
      await tester.enterText(find.byType(TextField), 'budgie');
      await tester.pump();

      final opacityAfter = tester.widget<AnimatedOpacity>(animatedOpacityFinder);
      expect(opacityAfter.opacity, 1.0);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    });
  });

  group('CommunitySearchScreen recent searches', () {
    testWidgets('does not show recent searches section when history is empty',
        (tester) async {
      await tester.pumpWidget(buildScope());
      await tester.pump();

      expect(find.text(l10n('community.recent_searches')), findsNothing);
      expect(find.text(l10n('community.clear_search_history')), findsNothing);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    });

    testWidgets('shows recent searches section when history has items',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'community_search_history': ['budgie', 'muhabbet'],
      });

      await tester.pumpWidget(buildScope());
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.recent_searches')), findsOneWidget);
      expect(find.text(l10n('community.clear_search_history')), findsOneWidget);
      expect(find.text('budgie'), findsOneWidget);
      expect(find.text('muhabbet'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    });

    testWidgets('tapping clear history removes recent searches section',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'community_search_history': ['budgie'],
      });

      await tester.pumpWidget(buildScope());
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.recent_searches')), findsOneWidget);

      await tester.tap(find.text(l10n('community.clear_search_history')));
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.recent_searches')), findsNothing);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    });

    testWidgets('tapping history chip applies query', (tester) async {
      SharedPreferences.setMockInitialValues({
        'community_search_history': ['lutino'],
      });

      await tester.pumpWidget(buildScope());
      await tester.pumpAndSettle();

      await tester.tap(find.text('lutino'));
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, 'lutino');

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
