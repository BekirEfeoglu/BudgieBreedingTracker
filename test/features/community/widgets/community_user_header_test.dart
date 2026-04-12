@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
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

      expect(find.text(l10n('community.my_post')), findsOneWidget);
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

      expect(find.text(l10n('community.follow')), findsOneWidget);
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

      expect(find.text(l10n('community.following_label')), findsOneWidget);
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

      expect(find.text(l10n('community.delete_post')), findsOneWidget);
    });

    testWidgets('shows post type icon for non-general post types', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CommunityUserHeader(
            userId: 'u1',
            username: 'User',
            createdAt: DateTime.now(),
            postType: CommunityPostType.photo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.camera), findsOneWidget);
    });

    testWidgets('shows guide icon for guide post type', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityUserHeader(
            userId: 'u1',
            username: 'User',
            createdAt: DateTime.now(),
            postType: CommunityPostType.guide,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.bookOpen), findsOneWidget);
    });

    testWidgets('shows question icon for question post type', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityUserHeader(
            userId: 'u1',
            username: 'User',
            createdAt: DateTime.now(),
            postType: CommunityPostType.question,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.helpCircle), findsOneWidget);
    });

    testWidgets('does not show post type badge for general type', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CommunityUserHeader(
            userId: 'u1',
            username: 'User',
            createdAt: DateTime.now(),
            postType: CommunityPostType.general,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.camera), findsNothing);
      expect(find.byIcon(LucideIcons.bookOpen), findsNothing);
      expect(find.byIcon(LucideIcons.helpCircle), findsNothing);
    });
  });
}
