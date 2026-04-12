@Tags(['community'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/skeleton_loader.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_post_providers.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_following_list.dart';

void main() {
  Widget createSubject({
    List<Map<String, dynamic>>? followedUsers,
    Completer<List<Map<String, dynamic>>>? completer,
    Object? error,
    String currentUserId = 'me',
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(currentUserId),
        followedUsersProvider.overrideWith((ref) {
          if (error != null) return Future.error(error);
          if (completer != null) return completer.future;
          return Future.value(followedUsers ?? []);
        }),
      ],
      child: const MaterialApp(
        home: Scaffold(body: CommunityFollowingList()),
      ),
    );
  }

  group('CommunityFollowingList', () {
    testWidgets('shows skeleton while loading', (tester) async {
      final completer = Completer<List<Map<String, dynamic>>>();

      await tester.pumpWidget(
        createSubject(completer: completer),
      );
      await tester.pump();

      expect(find.byType(SkeletonLoader), findsWidgets);

      // Complete to avoid pending timer
      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('shows empty state when no followed users', (tester) async {
      await tester.pumpWidget(
        createSubject(followedUsers: []),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(
        find.text(l10n('community.empty_following_title')),
        findsOneWidget,
      );
    });

    testWidgets('shows followed user list with names', (tester) async {
      await tester.pumpWidget(
        createSubject(
          followedUsers: [
            {
              'id': 'u1',
              'display_name': 'Alice',
              'avatar_url': null,
            },
            {
              'id': 'u2',
              'display_name': 'Bob',
              'avatar_url': 'https://example.com/bob.jpg',
            },
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('shows unfollow button for each user', (tester) async {
      await tester.pumpWidget(
        createSubject(
          followedUsers: [
            {
              'id': 'u1',
              'display_name': 'Alice',
              'avatar_url': null,
            },
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(l10n('community.following_label')),
        findsOneWidget,
      );
    });

    testWidgets('shows DM button for non-anonymous users', (tester) async {
      await tester.pumpWidget(
        createSubject(
          currentUserId: 'me',
          followedUsers: [
            {
              'id': 'u1',
              'display_name': 'Alice',
              'avatar_url': null,
            },
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byTooltip(l10n('messaging.direct_message')),
        findsOneWidget,
      );
    });

    testWidgets('hides DM button for anonymous users', (tester) async {
      await tester.pumpWidget(
        createSubject(
          currentUserId: 'anonymous',
          followedUsers: [
            {
              'id': 'u1',
              'display_name': 'Alice',
              'avatar_url': null,
            },
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byTooltip(l10n('messaging.direct_message')),
        findsNothing,
      );
    });

    testWidgets('shows error message on failure', (tester) async {
      await tester.pumpWidget(
        createSubject(error: Exception('fail')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(l10n('community.following_load_error')),
        findsOneWidget,
      );
    });

    testWidgets('shows initial letter when no avatar', (tester) async {
      await tester.pumpWidget(
        createSubject(
          followedUsers: [
            {
              'id': 'u1',
              'display_name': 'Zeynep',
              'avatar_url': null,
            },
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Z'), findsOneWidget);
    });
  });
}
