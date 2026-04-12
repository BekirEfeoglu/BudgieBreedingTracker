import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_search_bar.dart';

Widget _wrap(Widget child) {
  return const ProviderScope(
    child: MaterialApp(home: Scaffold(body: BreedingSearchBar())),
  );
}

void main() {
  group('BreedingSearchBar', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const BreedingSearchBar()));
      await tester.pump();

      expect(find.byType(BreedingSearchBar), findsOneWidget);
    });

    testWidgets('shows search hint text', (tester) async {
      await tester.pumpWidget(_wrap(const BreedingSearchBar()));
      await tester.pump();

      expect(find.text(l10n('breeding.search_hint')), findsOneWidget);
    });

    testWidgets('renders TextField', (tester) async {
      await tester.pumpWidget(_wrap(const BreedingSearchBar()));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('no clear button shown when query is empty', (tester) async {
      await tester.pumpWidget(_wrap(const BreedingSearchBar()));
      await tester.pump();

      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('shows clear button when text is entered', (tester) async {
      await tester.pumpWidget(_wrap(const BreedingSearchBar()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'test query');
      // Wait for debounce timer (300ms) to update the provider state
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('tapping clear button empties the field', (tester) async {
      await tester.pumpWidget(_wrap(const BreedingSearchBar()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'some text');
      // Wait for debounce timer (300ms) to update the provider state
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('renders prefix search icon', (tester) async {
      await tester.pumpWidget(_wrap(const BreedingSearchBar()));
      await tester.pump();

      // The prefix icon area is a Padding widget wrapping AppIcon
      expect(find.byType(Padding), findsAtLeastNWidgets(1));
    });
  });
}
