import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_hero_card.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  CommunityPost makePost({int likes = 0, int comments = 0}) {
    return CommunityPost(
      id: 'p-${likes}_$comments',
      userId: 'u1',
      likeCount: likes,
      commentCount: comments,
    );
  }

  group('CommunityHeroCard', () {
    testWidgets('renders without crashing with empty posts', (tester) async {
      await tester.pumpWidget(wrap(const CommunityHeroCard(posts: [])));
      await tester.pumpAndSettle();

      expect(find.text('community.title'), findsOneWidget);
      expect(find.text('community.content_label'), findsOneWidget);
    });

    testWidgets('shows aggregated stats', (tester) async {
      final posts = [
        makePost(likes: 5, comments: 2),
        makePost(likes: 3, comments: 1),
      ];
      await tester.pumpWidget(wrap(CommunityHeroCard(posts: posts)));
      await tester.pumpAndSettle();

      // Post count
      expect(find.text('2'), findsOneWidget);
      // Total likes
      expect(find.text('8'), findsOneWidget);
      // Total comments
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows stat icons', (tester) async {
      await tester.pumpWidget(wrap(const CommunityHeroCard(posts: [])));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.sparkles), findsOneWidget);
      expect(find.byIcon(LucideIcons.layoutGrid), findsOneWidget);
      expect(find.byIcon(LucideIcons.heart), findsOneWidget);
      expect(find.byIcon(LucideIcons.messageCircle), findsOneWidget);
    });
  });
}
