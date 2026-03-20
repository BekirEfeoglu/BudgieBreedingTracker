import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/features/community/providers/community_providers.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_section_bar.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('CommunitySectionBar', () {
    testWidgets('renders explore tab with sort controls', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunitySectionBar(
            tab: CommunityFeedTab.explore,
            visibleCount: 10,
            exploreSort: CommunityExploreSort.newest,
            onExploreSortChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('community.tab_explore'), findsOneWidget);
      expect(find.text('community.sort_newest'), findsOneWidget);
      expect(find.text('community.sort_trending'), findsOneWidget);
    });

    testWidgets('renders following tab without sort controls', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunitySectionBar(
            tab: CommunityFeedTab.following,
            visibleCount: 5,
            exploreSort: CommunityExploreSort.newest,
            onExploreSortChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('community.tab_following'), findsOneWidget);
      expect(find.text('community.sort_newest'), findsNothing);
    });

    testWidgets('shows result count', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunitySectionBar(
            tab: CommunityFeedTab.guides,
            visibleCount: 42,
            exploreSort: CommunityExploreSort.newest,
            onExploreSortChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // .tr(args:) without easy_localization returns the key name
      expect(find.text('community.filter_results'), findsOneWidget);
    });

    testWidgets('sort filter icons are present on explore', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunitySectionBar(
            tab: CommunityFeedTab.explore,
            visibleCount: 0,
            exploreSort: CommunityExploreSort.trending,
            onExploreSortChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.clock3), findsOneWidget);
      expect(find.byIcon(LucideIcons.flame), findsOneWidget);
    });
  });
}
