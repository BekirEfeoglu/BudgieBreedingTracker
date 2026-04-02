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
    testWidgets('renders create button and story avatars', (tester) async {
      final stories = [
        const StoryPreview(
          userId: 'u1',
          username: 'Ali',
          avatarUrl: null,
          hasFreshPhoto: false,
        ),
        const StoryPreview(
          userId: 'u2',
          username: 'Veli',
          avatarUrl: null,
          hasFreshPhoto: true,
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

    testWidgets('renders empty strip with only create button', (tester) async {
      await tester.pumpWidget(
        wrap(CommunityStoryStrip(stories: const [], onCreatePost: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.plus), findsOneWidget);
    });

    testWidgets('shows initial letters for avatars without URL', (
      tester,
    ) async {
      final stories = [
        const StoryPreview(
          userId: 'u1',
          username: 'Kemal',
          avatarUrl: null,
          hasFreshPhoto: false,
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
    test('returns unique users up to 10', () {
      final posts = List.generate(
        15,
        (i) => CommunityPost(
          id: 'p$i',
          userId: 'u${i % 12}',
          username: 'User${i % 12}',
        ),
      );

      final stories = CommunityStoryStrip.fromPosts(posts);

      expect(stories.length, 10);
      final userIds = stories.map((s) => s.userId).toSet();
      expect(userIds.length, 10);
    });
  });
}
