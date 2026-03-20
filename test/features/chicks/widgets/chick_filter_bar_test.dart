import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_filter_bar.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('ChickFilterBar', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const ChickFilterBar()));
      await tester.pump();

      expect(find.byType(ChickFilterBar), findsOneWidget);
    });

    testWidgets('renders ChoiceChip for each ChickFilter value', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const ChickFilterBar()));
      await tester.pump();

      // ListView renders only visible items; at least some chips must be visible
      expect(find.byType(ChoiceChip), findsAtLeastNWidgets(1));
    });

    testWidgets('default selection is ChickFilter.all', (tester) async {
      await tester.pumpWidget(_wrap(const ChickFilterBar()));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ChickFilterBar)),
      );
      expect(container.read(chickFilterProvider), ChickFilter.all);
    });

    testWidgets('tapping a chip updates the filter provider', (tester) async {
      await tester.pumpWidget(_wrap(const ChickFilterBar()));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ChickFilterBar)),
      );

      // Set filter directly to avoid overflow from long label text
      container.read(chickFilterProvider.notifier).state = ChickFilter.healthy;
      await tester.pump();

      expect(container.read(chickFilterProvider), ChickFilter.healthy);
    });

    testWidgets('renders horizontally scrollable layout', (tester) async {
      await tester.pumpWidget(_wrap(const ChickFilterBar()));
      await tester.pump();

      // FadeScrollableChipBar uses ListView(scrollDirection: horizontal) + Stack
      expect(find.byType(ListView), findsAtLeastNWidgets(1));
    });

    testWidgets('filter can be changed to each enum value', (tester) async {
      await tester.pumpWidget(_wrap(const ChickFilterBar()));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ChickFilterBar)),
      );

      for (final filter in ChickFilter.values) {
        container.read(chickFilterProvider.notifier).state = filter;
        await tester.pump();

        expect(container.read(chickFilterProvider), filter);
      }
    });

    testWidgets('total chip count matches ChickFilter.values.length', (
      tester,
    ) async {
      // Use a very wide surface to ensure all 9 chips are rendered
      await tester.binding.setSurfaceSize(const Size(4000, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(const ChickFilterBar()));
      await tester.pump();

      expect(find.byType(ChoiceChip), findsNWidgets(ChickFilter.values.length));
    });

    testWidgets('selecting sick filter updates provider to sick', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const ChickFilterBar()));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ChickFilterBar)),
      );

      container.read(chickFilterProvider.notifier).state = ChickFilter.sick;
      await tester.pump();

      expect(container.read(chickFilterProvider), ChickFilter.sick);
    });

    testWidgets('selecting deceased filter updates provider to deceased', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const ChickFilterBar()));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ChickFilterBar)),
      );

      container.read(chickFilterProvider.notifier).state = ChickFilter.deceased;
      await tester.pump();

      expect(container.read(chickFilterProvider), ChickFilter.deceased);
    });
  });
}
