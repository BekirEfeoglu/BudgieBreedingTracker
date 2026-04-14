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

      expect(find.byKey(const Key('community_feed_skeleton')), findsOneWidget);
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

  group('GuidesLibrarySkeleton', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(wrap(const GuidesLibrarySkeleton()));
      await tester.pump();

      expect(find.byType(GuidesLibrarySkeleton), findsOneWidget);
    });

    testWidgets('has the expected key', (tester) async {
      await tester.pumpWidget(wrap(const GuidesLibrarySkeleton()));
      await tester.pump();

      expect(find.byKey(const Key('guides_library_skeleton')), findsOneWidget);
    });

    testWidgets('renders skeleton loaders inside list view', (tester) async {
      await tester.pumpWidget(wrap(const GuidesLibrarySkeleton()));
      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(SkeletonLoader), findsWidgets);
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
      expect(find.text(l10n('community.empty_filtered_title')), findsOneWidget);
      expect(find.text(l10n('community.empty_filtered_hint')), findsOneWidget);
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
      expect(find.text(l10n('community.empty_following_hint')), findsOneWidget);
    });

    testWidgets('renders guides tab empty state (non-founder)', (tester) async {
      await tester.pumpWidget(
        wrap(
          const FilteredFeedEmptyState(
            tab: CommunityFeedTab.guides,
            onReset: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.empty_guides_title')), findsOneWidget);
      // Non-founder sees "coming soon" subtitle instead of the generic hint
      expect(find.text(l10n('community.guides_coming_soon')), findsOneWidget);
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
      expect(find.text(l10n('community.empty_questions_hint')), findsOneWidget);
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

    testWidgets('explore: shows FilledButton.tonal when onReset is provided',
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

      expect(find.text(l10n('community.show_all')), findsOneWidget);

      await tester.tap(find.text(l10n('community.show_all')));
      expect(resetCalled, isTrue);
    });

    testWidgets('explore: hides reset button when onReset is null',
        (tester) async {
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
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('following: shows OutlinedButton.icon when onReset is provided',
        (tester) async {
      var resetCalled = false;
      await tester.pumpWidget(
        wrap(
          FilteredFeedEmptyState(
            tab: CommunityFeedTab.following,
            onReset: () => resetCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byIcon(LucideIcons.compass), findsOneWidget);
      expect(find.text(l10n('community.go_to_explore')), findsOneWidget);

      await tester.tap(find.byType(OutlinedButton));
      expect(resetCalled, isTrue);
    });

    testWidgets('following: hides button when onReset is null', (tester) async {
      await tester.pumpWidget(
        wrap(
          const FilteredFeedEmptyState(
            tab: CommunityFeedTab.following,
            onReset: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('guides (founder): shows FilledButton.icon with write guide CTA',
        (tester) async {
      var resetCalled = false;
      await tester.pumpWidget(
        wrap(
          FilteredFeedEmptyState(
            tab: CommunityFeedTab.guides,
            onReset: () => resetCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
      expect(find.text(l10n('community.write_first_guide')), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      expect(resetCalled, isTrue);
    });

    testWidgets(
        'guides (non-founder): shows guides_coming_soon subtitle, no CTA',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const FilteredFeedEmptyState(
            tab: CommunityFeedTab.guides,
            onReset: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.guides_coming_soon')), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('questions: no CTA button', (tester) async {
      await tester.pumpWidget(
        wrap(
          const FilteredFeedEmptyState(
            tab: CommunityFeedTab.questions,
            onReset: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });
}
