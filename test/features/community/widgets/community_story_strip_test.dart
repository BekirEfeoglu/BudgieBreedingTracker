@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_story_strip.dart';

void main() {
  Widget wrap(Widget child) {
    final router = GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(
          path: '/test',
          builder: (_, __) => Scaffold(body: child),
        ),
        GoRoute(
          path: '/community/user/:userId',
          builder: (_, __) => const Scaffold(body: Text('user_posts')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  group('CommunityStoryStrip', () {
    final now = DateTime.now();

    testWidgets('renders create button and story avatars', (tester) async {
      final stories = [
        StoryPreview(
          userId: 'u1',
          username: 'Ali',
          avatarUrl: null,
          hasFreshPhoto: false,
          lastPostAt: now.subtract(const Duration(hours: 2)),
        ),
        StoryPreview(
          userId: 'u2',
          username: 'Veli',
          avatarUrl: null,
          hasFreshPhoto: true,
          lastPostAt: now.subtract(const Duration(minutes: 30)),
        ),
      ];

      await tester.pumpWidget(
        wrap(CommunityStoryStrip(stories: stories, onCreatePost: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.stories_title')), findsOneWidget);
      expect(find.byIcon(LucideIcons.plus), findsOneWidget);
      expect(find.text(l10n('community.create_post')), findsOneWidget);
      expect(find.text('Ali'), findsOneWidget);
      expect(find.text('Veli'), findsOneWidget);
    });

    testWidgets('renders nothing when stories list is empty', (tester) async {
      await tester.pumpWidget(
        wrap(CommunityStoryStrip(stories: const [], onCreatePost: () {})),
      );
      await tester.pumpAndSettle();

      // Empty strip is hidden entirely
      expect(find.byType(CommunityStoryStrip), findsOneWidget);
      expect(find.byIcon(LucideIcons.plus), findsNothing);
    });

    testWidgets('shows initial letters for avatars without URL', (
      tester,
    ) async {
      final stories = [
        StoryPreview(
          userId: 'u1',
          username: 'Kemal',
          avatarUrl: null,
          hasFreshPhoto: false,
          lastPostAt: now.subtract(const Duration(hours: 1)),
        ),
      ];

      await tester.pumpWidget(
        wrap(CommunityStoryStrip(stories: stories, onCreatePost: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('K'), findsOneWidget);
    });
  });

  group('CommunityStoryStrip.fromPosts', () {
    test('returns unique users up to 10 from last 24 hours', () {
      final now = DateTime.now();
      final posts = List.generate(
        15,
        (i) => CommunityPost(
          id: 'p$i',
          userId: 'u${i % 12}',
          username: 'User${i % 12}',
          createdAt: now.subtract(Duration(hours: i)),
        ),
      );

      final stories = CommunityStoryStrip.fromPosts(posts);

      expect(stories.length, 10);
      final userIds = stories.map((s) => s.userId).toSet();
      expect(userIds.length, 10);
    });

    test('excludes posts older than 24 hours', () {
      final now = DateTime.now();
      final posts = [
        CommunityPost(
          id: 'p1',
          userId: 'u1',
          username: 'Recent',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        CommunityPost(
          id: 'p2',
          userId: 'u2',
          username: 'Old',
          createdAt: now.subtract(const Duration(hours: 25)),
        ),
      ];

      final stories = CommunityStoryStrip.fromPosts(posts);

      expect(stories.length, 1);
      expect(stories.first.username, 'Recent');
    });

    test('counts multiple posts per user', () {
      final now = DateTime.now();
      final posts = [
        CommunityPost(
          id: 'p1',
          userId: 'u1',
          username: 'Prolific',
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        CommunityPost(
          id: 'p2',
          userId: 'u1',
          username: 'Prolific',
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
        CommunityPost(
          id: 'p3',
          userId: 'u1',
          username: 'Prolific',
          createdAt: now.subtract(const Duration(hours: 5)),
        ),
        CommunityPost(
          id: 'p4',
          userId: 'u2',
          username: 'SinglePost',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
      ];

      final stories = CommunityStoryStrip.fromPosts(posts);

      expect(stories.length, 2);
      final prolific = stories.firstWhere((s) => s.userId == 'u1');
      final single = stories.firstWhere((s) => s.userId == 'u2');
      expect(prolific.postCount, 3);
      expect(single.postCount, 1);
    });
  });
}
