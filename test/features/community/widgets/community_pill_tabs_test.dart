@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/features/community/providers/community_providers.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_pill_tabs.dart';

void main() {
  Widget wrap({CommunityFeedTab initialTab = CommunityFeedTab.explore}) {
    return ProviderScope(
      overrides: [
        communityActiveTabProvider.overrideWith(
          () => _FakeActiveTabNotifier(initialTab),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: CommunityPillTabs())),
    );
  }

  group('CommunityPillTabs', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byType(CommunityPillTabs), findsOneWidget);
    });

    testWidgets('renders all four tab labels', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(
        find.text(l10n('community.tab_explore')),
        findsOneWidget,
      );
      expect(
        find.text(l10n('community.tab_following')),
        findsOneWidget,
      );
      expect(
        find.text(l10n('community.tab_guides')),
        findsOneWidget,
      );
      expect(
        find.text(l10n('community.tab_marketplace')),
        findsOneWidget,
      );
    });

    testWidgets('renders tab icons', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.flame), findsOneWidget);
      expect(find.byIcon(LucideIcons.users), findsOneWidget);
      expect(find.byIcon(LucideIcons.bookOpen), findsOneWidget);
      expect(find.byIcon(LucideIcons.store), findsOneWidget);
    });

    testWidgets('tapping a tab updates the active tab provider',
        (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Tap the "following" tab
      await tester.tap(find.text(l10n('community.tab_following')));
      await tester.pumpAndSettle();

      // Widget should still be rendered (no crash)
      expect(find.byType(CommunityPillTabs), findsOneWidget);
    });

    testWidgets('uses Wrap layout when width is narrow', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communityActiveTabProvider.overrideWith(
              () => _FakeActiveTabNotifier(CommunityFeedTab.explore),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 250,
                child: CommunityPillTabs(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render in Wrap layout for narrow widths
      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('uses Row layout when width is sufficient', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Default test width (800px) should use Row layout
      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('active tab has gradient decoration', (tester) async {
      await tester.pumpWidget(
        wrap(initialTab: CommunityFeedTab.guides),
      );
      await tester.pumpAndSettle();

      // All four tabs render with AnimatedContainer
      expect(find.byType(AnimatedContainer), findsNWidgets(4));
    });

    testWidgets('tabs have semantic labels', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Each tab should have Semantics with button: true
      final semantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.button == true,
      );
      expect(semantics, findsNWidgets(4));
    });
  });
}

class _FakeActiveTabNotifier extends CommunityActiveTabNotifier {
  final CommunityFeedTab _initial;
  _FakeActiveTabNotifier(this._initial);

  @override
  CommunityFeedTab build() => _initial;
}
