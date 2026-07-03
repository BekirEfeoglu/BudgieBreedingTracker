import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_search_bar.dart';

Widget _wrap(Widget child) {
  return const ProviderScope(
    child: MaterialApp(home: Scaffold(body: BirdSearchBar())),
  );
}

void main() {
  group('BirdSearchBar', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const BirdSearchBar()));
      await tester.pump();

      expect(find.byType(BirdSearchBar), findsOneWidget);
    });

    testWidgets('shows search hint text', (tester) async {
      await tester.pumpWidget(_wrap(const BirdSearchBar()));
      await tester.pump();

      expect(find.text(l10n('birds.search_hint')), findsOneWidget);
    });

    testWidgets('renders TextField', (tester) async {
      await tester.pumpWidget(_wrap(const BirdSearchBar()));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('no clear button shown when query is empty', (tester) async {
      await tester.pumpWidget(_wrap(const BirdSearchBar()));
      await tester.pump();

      // IconButton for clear only appears when query is not empty
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('shows clear button when text is entered', (tester) async {
      await tester.pumpWidget(_wrap(const BirdSearchBar()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'test query');
      // Wait for debounce timer (300ms) to update the provider state
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('tapping clear button empties the field', (tester) async {
      await tester.pumpWidget(_wrap(const BirdSearchBar()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'some text');
      // Wait for debounce timer (300ms) to update the provider state
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('renders prefix search icon', (tester) async {
      await tester.pumpWidget(_wrap(const BirdSearchBar()));
      await tester.pump();

      // The prefix icon area is a Padding widget wrapping AppIcon
      expect(find.byType(Padding), findsAtLeastNWidgets(1));
    });

    testWidgets('should not update query provider until debounce elapses', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const BirdSearchBar()));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(BirdSearchBar)),
      );

      await tester.enterText(find.byType(TextField), 'mavi');
      // Before the 300ms debounce timer fires: provider must still be empty.
      // This is the regression guard — if the debounce were removed, the
      // provider would already read 'mavi' here and this assertion fails.
      await tester.pump(const Duration(milliseconds: 200));
      expect(container.read(birdSearchQueryProvider), '');

      // Advance past the 300ms mark (total 350ms) — timer has now fired.
      await tester.pump(const Duration(milliseconds: 150));
      expect(container.read(birdSearchQueryProvider), 'mavi');
    });

    testWidgets(
      'should clear query immediately without debounce when clear tapped',
      (tester) async {
        await tester.pumpWidget(_wrap(const BirdSearchBar()));
        await tester.pump();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(BirdSearchBar)),
        );

        await tester.enterText(find.byType(TextField), 'mavi');
        // Let the debounce settle so the provider reflects the typed value
        // and the clear button becomes visible.
        await tester.pump(const Duration(milliseconds: 350));
        expect(container.read(birdSearchQueryProvider), 'mavi');

        await tester.tap(find.byType(IconButton));
        // Single frame — no debounce wait. Clear must bypass the timer.
        await tester.pump();

        expect(container.read(birdSearchQueryProvider), '');
      },
    );
  });
}
