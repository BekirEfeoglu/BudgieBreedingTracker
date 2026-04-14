@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/data/providers/action_feedback_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_data_providers.dart'
    show isFounderProvider;
import 'package:budgie_breeding_tracker/features/community/providers/community_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';
import 'package:budgie_breeding_tracker/features/community/screens/community_screen.dart';
import 'package:budgie_breeding_tracker/features/gamification/providers/gamification_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

class _EmptyActionFeedbackNotifier extends ActionFeedbackNotifier {
  @override
  List<ActionFeedback> build() => [];
}

void main() {
  const testUserId = 'test-user';

  Widget createSubject({bool communityEnabled = false, FeedState? feedState}) {
    return ProviderScope(
      overrides: [
        isCommunityEnabledProvider.overrideWithValue(communityEnabled),
        isFounderProvider.overrideWith((ref) async => false),
        currentUserIdProvider.overrideWithValue(testUserId),
        userProfileProvider.overrideWith((ref) => Stream.value(null)),
        userLevelProvider(testUserId).overrideWith((ref) => Future.value(null)),
        unreadNotificationsProvider(testUserId)
            .overrideWith((ref) => Stream.value([])),
        actionFeedbackProvider
            .overrideWith(_EmptyActionFeedbackNotifier.new),
        if (communityEnabled && feedState != null)
          communityFeedProvider.overrideWith(
            () => _FakeFeedNotifier(feedState),
          ),
      ],
      child: const MaterialApp(home: CommunityScreen()),
    );
  }

  group('CommunityScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(CommunityScreen), findsOneWidget);
    });

    testWidgets('shows AppBar with community title', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.title')), findsOneWidget);
    });

    testWidgets('shows coming soon empty state when community is disabled', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(communityEnabled: false));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(l10n('community.coming_soon')), findsOneWidget);
    });

    testWidgets('shows empty feed state when community enabled but no posts', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(
          communityEnabled: true,
          feedState: const FeedState(
            posts: [],
            isLoading: false,
            hasMore: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Advance past the swipe-hint timer (4 s) so no pending timers remain.
      await tester.pump(const Duration(seconds: 5));

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows loading indicator when feed is loading', (tester) async {
      await tester.pumpWidget(
        createSubject(
          communityEnabled: true,
          feedState: const FeedState(isLoading: true),
        ),
      );

      await tester.pump();

      expect(find.byKey(const Key('community_feed_skeleton')), findsOneWidget);

      // Advance past the swipe-hint timer to avoid pending timer assertion.
      await tester.pump(const Duration(seconds: 5));
    });
  });
}

class _FakeFeedNotifier extends CommunityFeedNotifier {
  final FeedState _initialState;

  _FakeFeedNotifier(this._initialState);

  @override
  FeedState build() => _initialState;
}
