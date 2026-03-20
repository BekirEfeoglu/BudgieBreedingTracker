import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_creator_strip.dart';

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

  group('CommunityCreatorStrip', () {
    testWidgets('renders title and creator cards', (tester) async {
      final creators = [
        const CreatorHighlight(
          userId: 'u1',
          username: 'Ali',
          avatarUrl: null,
          postCount: 5,
          totalLikes: 20,
          totalComments: 10,
        ),
        const CreatorHighlight(
          userId: 'u2',
          username: 'Veli',
          avatarUrl: null,
          postCount: 3,
          totalLikes: 10,
          totalComments: 5,
        ),
      ];

      await tester.pumpWidget(wrap(CommunityCreatorStrip(creators: creators)));
      await tester.pumpAndSettle();

      expect(find.text('community.top_creators'), findsOneWidget);
      expect(find.text('Ali'), findsOneWidget);
      expect(find.text('Veli'), findsOneWidget);
    });

    testWidgets('renders empty list without crash', (tester) async {
      await tester.pumpWidget(wrap(const CommunityCreatorStrip(creators: [])));
      await tester.pumpAndSettle();

      expect(find.text('community.top_creators'), findsOneWidget);
    });
  });

  group('CommunityCreatorStrip.fromPosts', () {
    test('aggregates posts by user and returns top 6', () {
      final posts = [
        const CommunityPost(
          id: 'p1',
          userId: 'u1',
          username: 'Ali',
          likeCount: 10,
          commentCount: 5,
        ),
        const CommunityPost(
          id: 'p2',
          userId: 'u1',
          username: 'Ali',
          likeCount: 5,
          commentCount: 2,
        ),
        const CommunityPost(
          id: 'p3',
          userId: 'u2',
          username: 'Veli',
          likeCount: 20,
          commentCount: 1,
        ),
      ];

      final creators = CommunityCreatorStrip.fromPosts(posts);

      expect(creators.length, 2);
      // u1 has 2 posts, u2 has 1 post
      final u1 = creators.firstWhere((c) => c.userId == 'u1');
      expect(u1.postCount, 2);
      expect(u1.totalLikes, 15);
      expect(u1.totalComments, 7);
    });

    test('limits results to 6 creators', () {
      final posts = List.generate(
        10,
        (i) => CommunityPost(
          id: 'p$i',
          userId: 'u$i',
          username: 'User$i',
          likeCount: 10 - i,
        ),
      );

      final creators = CommunityCreatorStrip.fromPosts(posts);
      expect(creators.length, 6);
    });
  });

  group('CreatorHighlight', () {
    test('score is calculated correctly', () {
      const creator = CreatorHighlight(
        userId: 'u1',
        username: 'Ali',
        avatarUrl: null,
        postCount: 2,
        totalLikes: 10,
        totalComments: 5,
      );

      // score = likes(10) + comments(5) + posts*3(6) = 21
      expect(creator.score, 21);
    });

    test('copyWith updates fields', () {
      const creator = CreatorHighlight(
        userId: 'u1',
        username: 'Ali',
        avatarUrl: null,
        postCount: 1,
        totalLikes: 5,
        totalComments: 2,
      );

      final updated = creator.copyWith(postCount: 3, totalLikes: 15);
      expect(updated.postCount, 3);
      expect(updated.totalLikes, 15);
      expect(updated.totalComments, 2);
    });
  });
}
