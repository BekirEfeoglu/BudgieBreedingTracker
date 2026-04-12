import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/z_linked_badge.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

void main() {
  group('ZLinkedBadge', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(const ZLinkedBadge(linkedIds: ['opaline', 'cinnamon'])),
      );
      await tester.pump();

      expect(find.byType(ZLinkedBadge), findsOneWidget);
    });

    testWidgets('shows z_linked text', (tester) async {
      await tester.pumpWidget(
        _wrap(const ZLinkedBadge(linkedIds: ['opaline', 'cinnamon'])),
      );
      await tester.pump();

      expect(find.text(l10n('genetics.z_linked')), findsOneWidget);
    });

    testWidgets('shows link icon', (tester) async {
      await tester.pumpWidget(
        _wrap(const ZLinkedBadge(linkedIds: ['opaline', 'cinnamon'])),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.link), findsOneWidget);
    });

    testWidgets('has GestureDetector for tap interaction', (tester) async {
      await tester.pumpWidget(
        _wrap(const ZLinkedBadge(linkedIds: ['opaline', 'cinnamon'])),
      );
      await tester.pump();

      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('shows linkage popup dialog on tap', (tester) async {
      await tester.pumpWidget(
        _wrap(const ZLinkedBadge(linkedIds: ['opaline', 'cinnamon'])),
      );
      await tester.pump();

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('popup shows z_linkage title', (tester) async {
      await tester.pumpWidget(
        _wrap(const ZLinkedBadge(linkedIds: ['opaline', 'cinnamon'])),
      );
      await tester.pump();

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(find.text(l10n('genetics.z_linkage')), findsOneWidget);
    });

    testWidgets('popup shows z_gene_order description', (tester) async {
      await tester.pumpWidget(
        _wrap(const ZLinkedBadge(linkedIds: ['opaline', 'cinnamon'])),
      );
      await tester.pump();

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(find.text(l10n('genetics.z_gene_order')), findsOneWidget);
    });

    testWidgets('popup shows linkage rate with cM unit', (tester) async {
      await tester.pumpWidget(
        _wrap(const ZLinkedBadge(linkedIds: ['opaline', 'cinnamon'])),
      );
      await tester.pump();

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // opaline-cinnamon linkage rate is 34 cM
      expect(find.textContaining('34 cM'), findsOneWidget);
    });

    testWidgets('popup shows close button', (tester) async {
      await tester.pumpWidget(
        _wrap(const ZLinkedBadge(linkedIds: ['opaline', 'cinnamon'])),
      );
      await tester.pump();

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(find.text(l10n('common.close')), findsOneWidget);
    });

    testWidgets('popup closes when close button is tapped', (tester) async {
      await tester.pumpWidget(
        _wrap(const ZLinkedBadge(linkedIds: ['opaline', 'cinnamon'])),
      );
      await tester.pump();

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text(l10n('common.close')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('shows multiple linkage pairs for 3 linked mutations',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const ZLinkedBadge(linkedIds: ['opaline', 'cinnamon', 'ino'])),
      );
      await tester.pump();

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // Should show 3 pairs: opaline-cinnamon (34cM), opaline-ino (30cM),
      // cinnamon-ino (3cM)
      expect(find.textContaining('cM'), findsNWidgets(3));
    });

    testWidgets('does not show popup when no linkage rates found',
        (tester) async {
      // Use mutations that have no linkage rate defined between them
      await tester.pumpWidget(
        _wrap(const ZLinkedBadge(linkedIds: ['pearly', 'texas_clearbody'])),
      );
      await tester.pump();

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // No dialog should appear since no pairs have defined rates
      // (pearly and texas_clearbody don't have a direct linkage rate)
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('renders Container with decoration', (tester) async {
      await tester.pumpWidget(
        _wrap(const ZLinkedBadge(linkedIds: ['opaline', 'cinnamon'])),
      );
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Row with icon and text', (tester) async {
      await tester.pumpWidget(
        _wrap(const ZLinkedBadge(linkedIds: ['opaline', 'cinnamon'])),
      );
      await tester.pump();

      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('linkage arrow symbol appears in popup pairs', (tester) async {
      await tester.pumpWidget(
        _wrap(const ZLinkedBadge(linkedIds: ['ino', 'slate'])),
      );
      await tester.pump();

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // Arrow symbol between linked mutations
      expect(find.textContaining('\u2194'), findsAtLeastNWidgets(1));
    });
  });

  group('hasLinkedSexLinkedMutations', () {
    test('returns true when 2+ linked sex-linked mutations present', () {
      const result = OffspringResult(
        phenotype: 'Test',
        probability: 0.25,
        visualMutations: ['opaline', 'cinnamon'],
      );
      expect(hasLinkedSexLinkedMutations(result), isTrue);
    });

    test('returns false when fewer than 2 linked mutations', () {
      const result = OffspringResult(
        phenotype: 'Test',
        probability: 0.25,
        visualMutations: ['opaline'],
      );
      expect(hasLinkedSexLinkedMutations(result), isFalse);
    });

    test('returns false when no sex-linked mutations present', () {
      const result = OffspringResult(
        phenotype: 'Test',
        probability: 0.25,
        visualMutations: ['blue', 'dark_factor'],
      );
      expect(hasLinkedSexLinkedMutations(result), isFalse);
    });

    test('returns true with ino and cinnamon', () {
      const result = OffspringResult(
        phenotype: 'Lacewing',
        probability: 0.125,
        visualMutations: ['ino', 'cinnamon', 'blue'],
      );
      expect(hasLinkedSexLinkedMutations(result), isTrue);
    });

    test('returns true with 3 linked sex-linked mutations', () {
      const result = OffspringResult(
        phenotype: 'Complex',
        probability: 0.05,
        visualMutations: ['opaline', 'cinnamon', 'ino'],
      );
      expect(hasLinkedSexLinkedMutations(result), isTrue);
    });
  });

  group('getLinkedIds', () {
    test('returns linked sex-linked IDs from offspring result', () {
      const result = OffspringResult(
        phenotype: 'Test',
        probability: 0.25,
        visualMutations: ['opaline', 'blue', 'cinnamon'],
      );
      final linked = getLinkedIds(result);
      expect(linked, containsAll(['opaline', 'cinnamon']));
      expect(linked.contains('blue'), isFalse);
    });

    test('returns empty list when no linked mutations', () {
      const result = OffspringResult(
        phenotype: 'Test',
        probability: 0.25,
        visualMutations: ['blue', 'dark_factor'],
      );
      expect(getLinkedIds(result), isEmpty);
    });

    test('returns all known linked IDs', () {
      const result = OffspringResult(
        phenotype: 'Test',
        probability: 0.1,
        visualMutations: [
          'opaline',
          'cinnamon',
          'ino',
          'slate',
          'pallid',
          'texas_clearbody',
          'pearly',
        ],
      );
      final linked = getLinkedIds(result);
      expect(linked.length, equals(7));
    });
  });
}
