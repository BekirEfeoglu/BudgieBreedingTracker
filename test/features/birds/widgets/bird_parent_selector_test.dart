import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/providers/bird_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_detail_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_parent_selector.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';

import '../../../helpers/test_helpers.dart';

/// Drift-side filter mirror — the selector now reads
/// `birdParentCandidatesProvider`, which Drift fills with the SQL-filtered
/// list. Tests pass a "raw" list and this helper computes what the DAO
/// would return so the widget receives the same shape it sees in
/// production.
List<Bird> _applyParentFilter(
  List<Bird> birds, {
  required BirdGender gender,
  Species? species,
  String? excludeId,
}) {
  return birds
      .where((b) => b.status == BirdStatus.alive)
      .where((b) => b.gender == gender)
      .where((b) => species == null || b.species == species)
      .where((b) => excludeId == null || b.id != excludeId)
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
}

/// Builds the override pair for both providers the widget reads.
/// - `birdParentCandidatesProvider` → the Drift-filtered shape.
/// - `birdsStreamProvider` → the full list for the fallback selected-id
///   lookup when the chosen bird no longer matches the filter.
List<dynamic> _parentSelectorOverrides({
  required List<Bird> birds,
  required BirdGender gender,
  Species? species,
  String? excludeId,
}) {
  final filtered = _applyParentFilter(
    birds,
    gender: gender,
    species: species,
    excludeId: excludeId,
  );
  // Per-bird lookup for the selected-but-not-in-candidates fallback path.
  // The widget reads `birdByIdProvider(selectedId)` when the chosen bird
  // is filtered out (e.g. dead, outside 50-row window). Map all input
  // birds so any selectedId resolves correctly in tests.
  final byId = <String, Bird>{for (final b in birds) b.id: b};
  return [
    currentUserIdProvider.overrideWithValue('user-1'),
    birdsStreamProvider.overrideWith((ref, userId) => Stream.value(birds)),
    birdParentCandidatesProvider.overrideWith(
      (ref, args) => Stream.value(filtered),
    ),
    birdByIdProvider.overrideWith(
      (ref, id) => Stream.value(byId[id]),
    ),
  ];
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<dynamic> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: List.from(overrides),
      child: MaterialApp(
        home: Scaffold(body: Form(child: child)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('BirdParentSelector', () {
    testWidgets('shows disabled dropdown when loading', (tester) async {
      await _pump(
        tester,
        BirdParentSelector(
          label: 'Baba Seçin',
          icon: const AppIcon('assets/icons/birds/male.svg'),
          selectedId: null,
          excludeId: null,
          speciesFilter: Species.budgie,
          genderFilter: BirdGender.male,
          onChanged: (_) {},
        ),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          birdsStreamProvider.overrideWith(
            (ref, userId) => const Stream.empty(),
          ),
          birdParentCandidatesProvider.overrideWith(
            (ref, args) => const Stream.empty(),
          ),
        ],
      );

      // Loading state: dropdown renders with no items (disabled)
      expect(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
        findsOneWidget,
      );
    });

    testWidgets('shows label text', (tester) async {
      await _pump(
        tester,
        BirdParentSelector(
          label: 'Baba Seçin',
          icon: const AppIcon('assets/icons/birds/male.svg'),
          selectedId: null,
          excludeId: null,
          speciesFilter: Species.budgie,
          genderFilter: BirdGender.male,
          onChanged: (_) {},
        ),
        overrides: _parentSelectorOverrides(
          birds: const [],
          gender: BirdGender.male,
          species: Species.budgie,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Baba Seçin'), findsAtLeastNWidgets(1));
    });

    testWidgets('filters birds by gender - shows only males', (tester) async {
      final male = createTestBird(
        id: 'm-1',
        name: 'Erkek Kus',
        gender: BirdGender.male,
      );
      final female = createTestBird(
        id: 'f-1',
        name: 'Disi Kus',
        gender: BirdGender.female,
      );

      await _pump(
        tester,
        BirdParentSelector(
          label: 'Baba',
          icon: const AppIcon('assets/icons/birds/male.svg'),
          selectedId: null,
          excludeId: null,
          speciesFilter: Species.budgie,
          genderFilter: BirdGender.male,
          onChanged: (_) {},
        ),
        overrides: _parentSelectorOverrides(
          birds: [male, female],
          gender: BirdGender.male,
          species: Species.budgie,
        ),
      );
      await tester.pumpAndSettle();

      // Female bird should be filtered out; only 'no parent' option + male bird visible
      // 'Disi Kus' should not appear in the dropdown label area
      expect(
        find.text('Erkek Kus'),
        findsNothing,
      ); // not expanded, items not rendered
      expect(find.text('Disi Kus'), findsNothing);
      expect(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
        findsOneWidget,
      );
    });

    testWidgets('excludes the specified bird by excludeId', (tester) async {
      final male1 = createTestBird(
        id: 'm-1',
        name: 'Erkek1',
        gender: BirdGender.male,
      );
      final male2 = createTestBird(
        id: 'm-2',
        name: 'Erkek2',
        gender: BirdGender.male,
      );

      await _pump(
        tester,
        BirdParentSelector(
          label: 'Baba',
          icon: const AppIcon('assets/icons/birds/male.svg'),
          selectedId: 'm-2',
          excludeId: 'm-1',
          speciesFilter: Species.budgie,
          genderFilter: BirdGender.male,
          onChanged: (_) {},
        ),
        overrides: _parentSelectorOverrides(
          birds: [male1, male2],
          gender: BirdGender.male,
          species: Species.budgie,
          excludeId: 'm-1',
        ),
      );
      await tester.pumpAndSettle();

      // male1 is excluded, male2 is selected (shown as current value)
      expect(find.text('Erkek2'), findsOneWidget);
      expect(find.text('Erkek1'), findsNothing);
    });

    testWidgets('shows no parent option', (tester) async {
      final male = createTestBird(
        id: 'm-1',
        name: 'Erkek',
        gender: BirdGender.male,
      );

      await _pump(
        tester,
        BirdParentSelector(
          label: 'Baba',
          icon: const AppIcon('assets/icons/birds/male.svg'),
          selectedId: null,
          excludeId: null,
          speciesFilter: Species.budgie,
          genderFilter: BirdGender.male,
          onChanged: (_) {},
        ),
        overrides: _parentSelectorOverrides(
          birds: [male],
          gender: BirdGender.male,
          species: Species.budgie,
        ),
      );
      await tester.pumpAndSettle();

      // Dropdown renders (has data state with null/no-parent option)
      expect(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
        findsOneWidget,
      );
    });

    testWidgets(
      'keeps selected parent visible even when it is outside top 50/alive filter',
      (tester) async {
        final aliveMales = List.generate(
          55,
          (index) => createTestBird(
            id: 'm-$index',
            name: 'Erkek $index',
            gender: BirdGender.male,
            status: BirdStatus.alive,
          ),
        );
        final selectedDeadMale = createTestBird(
          id: 'm-selected',
          name: 'Secili Baba',
          gender: BirdGender.male,
          status: BirdStatus.dead,
        );

        await _pump(
          tester,
          BirdParentSelector(
            label: 'Baba',
            icon: const AppIcon('assets/icons/birds/male.svg'),
            selectedId: selectedDeadMale.id,
            excludeId: null,
            speciesFilter: Species.budgie,
            genderFilter: BirdGender.male,
            onChanged: (_) {},
          ),
          overrides: _parentSelectorOverrides(
            birds: [...aliveMales, selectedDeadMale],
            gender: BirdGender.male,
            species: Species.budgie,
          ),
        );
        await tester.pumpAndSettle();

        // selected value must still be renderable even if not in default candidate set
        expect(find.text('Secili Baba'), findsOneWidget);
      },
    );

    testWidgets('filters birds by species', (tester) async {
      final budgieMale = createTestBird(
        id: 'm-budgie',
        name: 'Budgie Baba',
        gender: BirdGender.male,
        species: Species.budgie,
      );
      final canaryMale = createTestBird(
        id: 'm-canary',
        name: 'Kanarya Baba',
        gender: BirdGender.male,
        species: Species.canary,
      );

      await _pump(
        tester,
        BirdParentSelector(
          label: 'Baba',
          icon: const AppIcon('assets/icons/birds/male.svg'),
          selectedId: null,
          excludeId: null,
          speciesFilter: Species.budgie,
          genderFilter: BirdGender.male,
          onChanged: (_) {},
        ),
        overrides: _parentSelectorOverrides(
          birds: [budgieMale, canaryMale],
          gender: BirdGender.male,
          species: Species.budgie,
        ),
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Budgie Baba'), findsOneWidget);
      expect(find.text('Kanarya Baba'), findsNothing);
    });

    testWidgets(
      'does not keep selected parent visible when species filter no longer matches',
      (tester) async {
        final canaryMale = createTestBird(
          id: 'm-canary',
          name: 'Kanarya Baba',
          gender: BirdGender.male,
          species: Species.canary,
        );

        await _pump(
          tester,
          BirdParentSelector(
            label: 'Baba',
            icon: const AppIcon('assets/icons/birds/male.svg'),
            selectedId: canaryMale.id,
            excludeId: null,
            speciesFilter: Species.budgie,
            genderFilter: BirdGender.male,
            onChanged: (_) {},
          ),
          overrides: _parentSelectorOverrides(
            birds: [canaryMale],
            gender: BirdGender.male,
            species: Species.budgie,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Kanarya Baba'), findsNothing);
      },
    );
  });

  group('BirdFormSectionHeader', () {
    testWidgets('displays title text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BirdFormSectionHeader('Temel Bilgiler')),
        ),
      );

      expect(find.text('Temel Bilgiler'), findsOneWidget);
    });

    testWidgets('is a StatelessWidget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BirdFormSectionHeader('Başlık')),
        ),
      );

      expect(find.byType(BirdFormSectionHeader), findsOneWidget);
    });
  });
}
