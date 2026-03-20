import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/features/community/widgets/community_user_header.dart';

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

  group('CommunityUserHeader', () {
    testWidgets('renders username and date', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityUserHeader(
            userId: 'u1',
            username: 'BudgieKing',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BudgieKing'), findsOneWidget);
    });

    testWidgets('shows initial letter when no avatar', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityUserHeader(
            userId: 'u1',
            username: 'Ali',
            createdAt: DateTime.now(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('shows my_post badge for own posts', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityUserHeader(
            userId: 'u1',
            username: 'User',
            createdAt: DateTime.now(),
            isOwnPost: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('community.my_post'), findsOneWidget);
    });

    testWidgets('shows follow button for non-own posts', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityUserHeader(
            userId: 'u1',
            username: 'User',
            createdAt: DateTime.now(),
            isOwnPost: false,
            isFollowing: false,
            onFollowToggle: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('community.follow'), findsOneWidget);
    });

    testWidgets('shows following label when already following', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityUserHeader(
            userId: 'u1',
            username: 'User',
            createdAt: DateTime.now(),
            isOwnPost: false,
            isFollowing: true,
            onFollowToggle: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('community.following_label'), findsOneWidget);
    });

    testWidgets('shows delete option in popup for own posts', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityUserHeader(
            userId: 'u1',
            username: 'User',
            createdAt: DateTime.now(),
            isOwnPost: true,
            onDelete: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open popup
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('community.delete_post'), findsOneWidget);
    });
  });
}
