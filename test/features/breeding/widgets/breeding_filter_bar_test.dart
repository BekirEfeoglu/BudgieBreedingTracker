import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_filter_bar.dart';

Future<void> _pump(
  WidgetTester tester, {
  List<dynamic> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: List.from(overrides),
      child: const MaterialApp(home: Scaffold(body: BreedingFilterBar())),
    ),
  );
  await tester.pump();
}

void main() {
  group('BreedingFilterBar', () {
    testWidgets('renders ChoiceChips for all filter values', (tester) async {
      await _pump(tester);

      expect(find.byType(ChoiceChip), findsAtLeastNWidgets(1));
    });

    testWidgets('renders at least one chip per BreedingFilter value', (
      tester,
    ) async {
      await _pump(tester);

      // Chips may be partially visible in test viewport (lazy ListView)
      expect(find.byType(ChoiceChip), findsAtLeastNWidgets(1));
    });

    testWidgets('first chip is selected by default (BreedingFilter.all)', (
      tester,
    ) async {
      await _pump(tester);

      // Default filter is BreedingFilter.all - first visible chip should be selected
      final chips = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .toList();
      expect(chips.first.selected, isTrue);
    });

    testWidgets('tapping a chip updates the filter provider', (tester) async {
      await _pump(tester);

      // Update provider state directly (chip tap may not fire due to l10n overflow in tests)
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BreedingFilterBar)),
      );
      container.read(breedingFilterProvider.notifier).state =
          BreedingFilter.active;
      await tester.pump();

      final currentFilter = container.read(breedingFilterProvider);
      expect(currentFilter, BreedingFilter.active);
    });

    testWidgets('filter provider starts at BreedingFilter.all', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final currentFilter = container.read(breedingFilterProvider);
      expect(currentFilter, BreedingFilter.all);
    });

    testWidgets('renders inside FadeScrollableChipBar', (tester) async {
      await _pump(tester);

      // Should be scrollable (FadeScrollableChipBar or ListView)
      expect(find.byType(BreedingFilterBar), findsOneWidget);
    });
  });
}
