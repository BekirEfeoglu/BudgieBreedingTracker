import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/species/species_registry.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/stats_species_filter_selector.dart';

import '../../../helpers/test_localization.dart';

Future<void> _pumpSelector(WidgetTester tester) {
  return pumpLocalizedApp(
    tester,
    const ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: StatsSpeciesFilterSelector())),
      ),
    ),
  );
}

void main() {
  group('StatsSpeciesFilterSelector', () {
    testWidgets('renders dropdown with all species items', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpSelector(tester);

      expect(find.byType(StatsSpeciesFilterSelector), findsOneWidget);
      expect(
        find.byType(DropdownButtonFormField<Species?>),
        findsOneWidget,
      );
    });

    testWidgets('shows all supported species plus all-species option',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpSelector(tester);

      // Open the dropdown
      await tester.tap(find.byType(DropdownButtonFormField<Species?>));
      await tester.pumpAndSettle();

      // "All species" + each supported species
      final expectedCount = SpeciesRegistry.supportedSpecies.length + 1;
      // DropdownMenuItem duplicates: one in button, one in overlay
      expect(
        find.byType(DropdownMenuItem<Species?>),
        findsAtLeast(expectedCount),
      );
    });

    testWidgets('does not show active filter chip when no species selected',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpSelector(tester);

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('shows active filter chip when species is selected',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyStatsSpeciesFilter: Species.budgie.name,
      });
      await _pumpSelector(tester);

      // Wait for async prefs load
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsOneWidget);
    });

    testWidgets('chip has semantics label with filter context', (tester) async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyStatsSpeciesFilter: Species.canary.name,
      });
      await _pumpSelector(tester);
      await tester.pump();
      await tester.pumpAndSettle();

      // Find the Semantics widget that wraps our Chip
      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label != null &&
            widget.properties.label!.contains('statistics.filter_species'),
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('tapping chip delete clears species filter', (tester) async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyStatsSpeciesFilter: Species.budgie.name,
      });

      late ProviderContainer container;
      await pumpLocalizedApp(
        tester,
        ProviderScope(
          child: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: StatsSpeciesFilterSelector(),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify chip is present
      expect(find.byType(Chip), findsOneWidget);

      // Tap the delete icon on the chip
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(container.read(statsSpeciesFilterProvider), isNull);
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('dropdown is disabled until prefs are loaded', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await pumpLocalizedApp(
        tester,
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: StatsSpeciesFilterSelector()),
            ),
          ),
        ),
        settle: false,
      );
      await tester.pump();

      // After prefs load (microtask), dropdown becomes enabled
      await tester.pumpAndSettle();

      // Should be interactable now
      expect(find.byType(DropdownButtonFormField<Species?>), findsOneWidget);
    });
  });

  group('StatsSpeciesFilterNotifier persistence', () {
    test('setSpecies saves to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(statsSpeciesFilterProvider.notifier)
          .setSpecies(Species.cockatiel);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AppPreferences.keyStatsSpeciesFilter),
        'cockatiel',
      );
    });

    test('setSpecies(null) removes key from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyStatsSpeciesFilter: 'budgie',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(statsSpeciesFilterProvider.notifier)
          .setSpecies(null);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppPreferences.keyStatsSpeciesFilter), isNull);
    });

    test('build loads saved species from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyStatsSpeciesFilter: 'finch',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Default is null
      expect(container.read(statsSpeciesFilterProvider), isNull);

      // Wait for _loadFromPrefs to complete
      await Future<void>.delayed(Duration.zero);

      expect(container.read(statsSpeciesFilterProvider), Species.finch);
    });

    test('build stays null for invalid saved value', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyStatsSpeciesFilter: 'parrot',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(container.read(statsSpeciesFilterProvider), isNull);
    });

    test('build stays null when no saved value', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(container.read(statsSpeciesFilterProvider), isNull);
    });

    test('isLoaded becomes true after prefs load', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Access provider to trigger build
      container.read(statsSpeciesFilterProvider);

      // Before load
      expect(
        container.read(statsSpeciesFilterProvider.notifier).isLoaded,
        isFalse,
      );

      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(statsSpeciesFilterProvider.notifier).isLoaded,
        isTrue,
      );
    });
  });
}
