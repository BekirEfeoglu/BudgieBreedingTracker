@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/widgets/skeleton_loader.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_providers.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_feed_states.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('CommunityFeedSkeleton', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(wrap(const CommunityFeedSkeleton()));
      await tester.pump();

      expect(find.byType(CommunityFeedSkeleton), findsOneWidget);
    });

    testWidgets('has the expected key', (tester) async {
      await tester.pumpWidget(wrap(const CommunityFeedSkeleton()));
      await tester.pump();

      expect(
        find.byKey(const Key('community_feed_skeleton')),
        findsOneWidget,
      );
    });

    testWidgets('renders skeleton loaders', (tester) async {
      await tester.pumpWidget(wrap(const CommunityFeedSkeleton()));
      await tester.pump();

      // Should contain multiple SkeletonLoader widgets
      // (1 composer skeleton + 3 post skeletons with multiple loaders each)
      expect(find.byType(SkeletonLoader), findsWidgets);
    });

    testWidgets('renders inside a ListView', (tester) async {
      await tester.pumpWidget(wrap(const CommunityFeedSkeleton()));
      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('FilteredFeedEmptyState', () {
    testWidgets('renders explore tab empty state', (tester) async {
      await tester.pumpWidget(
        wrap(
          const FilteredFeedEmptyState(
            tab: CommunityFeedTab.explore,
            onReset: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilteredFeedEmptyState), findsOneWidget);
      expect(
        find.text(l10n('community.empty_filtered_title')),
        findsOneWidget,
      );
      expect(
        find.text(l10n('community.empty_filtered_hint')),
        findsOneWidget,
      );
    });

    testWidgets('renders following tab empty state', (tester) async {
      await tester.pumpWidget(
        wrap(
          const FilteredFeedEmptyState(
            tab: CommunityFeedTab.following,
            onReset: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(l10n('community.empty_following_title')),
        findsOneWidget,
      );
      expect(
        find.text(l10n('community.empty_following_hint')),
        findsOneWidget,
      );
    });

    testWidgets('renders guides tab empty state', (tester) async {
      await tester.pumpWidget(
        wrap(
          const FilteredFeedEmptyState(
            tab: CommunityFeedTab.guides,
            onReset: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(l10n('community.empty_guides_title')),
        findsOneWidget,
      );
      expect(
        find.text(l10n('community.empty_guides_hint')),
        findsOneWidget,
      );
    });

    testWidgets('renders questions tab empty state', (tester) async {
      await tester.pumpWidget(
        wrap(
          const FilteredFeedEmptyState(
            tab: CommunityFeedTab.questions,
            onReset: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(l10n('community.empty_questions_title')),
        findsOneWidget,
      );
      expect(
        find.text(l10n('community.empty_questions_hint')),
        findsOneWidget,
      );
    });

    testWidgets('shows searchX icon', (tester) async {
      await tester.pumpWidget(
        wrap(
          const FilteredFeedEmptyState(
            tab: CommunityFeedTab.explore,
            onReset: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.searchX), findsOneWidget);
    });

    testWidgets('shows reset button when onReset is provided',
        (tester) async {
      var resetCalled = false;
      await tester.pumpWidget(
        wrap(
          FilteredFeedEmptyState(
            tab: CommunityFeedTab.explore,
            onReset: () => resetCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final resetButton = find.byType(FilledButton);
      expect(resetButton, findsOneWidget);
      expect(
        find.text(l10n('community.show_all')),
        findsOneWidget,
      );

      await tester.tap(resetButton);
      expect(resetCalled, isTrue);
    });

    testWidgets('hides reset button when onReset is null', (tester) async {
      await tester.pumpWidget(
        wrap(
          const FilteredFeedEmptyState(
            tab: CommunityFeedTab.explore,
            onReset: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsNothing);
    });
  });
}
