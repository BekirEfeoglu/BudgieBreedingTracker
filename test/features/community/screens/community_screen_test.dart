import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_feed_providers.dart';
import 'package:budgie_breeding_tracker/features/community/screens/community_screen.dart';

void main() {
  Widget createSubject({bool communityEnabled = false, FeedState? feedState}) {
    return ProviderScope(
      overrides: [
        supabaseInitializedProvider.overrideWithValue(false),
        isCommunityEnabledProvider.overrideWithValue(communityEnabled),
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

      expect(find.text('community.title'), findsOneWidget);
    });

    testWidgets('shows coming soon empty state when community is disabled', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(communityEnabled: false));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('community.coming_soon'), findsOneWidget);
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

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

class _FakeFeedNotifier extends CommunityFeedNotifier {
  final FeedState _initialState;

  _FakeFeedNotifier(this._initialState);

  @override
  FeedState build() => _initialState;
}
