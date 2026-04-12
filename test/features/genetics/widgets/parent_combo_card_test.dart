import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/parent_combo_card.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}
ReverseCalculationResult _makeResult({
  Map<String, AlleleState>? fatherMutations,
  Map<String, AlleleState>? motherMutations,
  double probabilityMale = 0.25,
  double probabilityFemale = 0.25,
}) {
  return ReverseCalculationResult(
    father: ParentGenotype(
      mutations: fatherMutations ?? {'blue': AlleleState.visual},
      gender: BirdGender.male,
    ),
    mother: ParentGenotype(
      mutations: motherMutations ?? {'blue': AlleleState.visual},
      gender: BirdGender.female,
    ),
    probabilityMale: probabilityMale,
    probabilityFemale: probabilityFemale,
  );
}

void main() {
  group('ParentComboCard', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(ParentComboCard(result: _makeResult(), rank: 1)),
      );
      expect(find.byType(ParentComboCard), findsOneWidget);
    });

    testWidgets('shows Card widget', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(ParentComboCard(result: _makeResult(), rank: 1)),
      );
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows rank with option label', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(ParentComboCard(result: _makeResult(), rank: 3)),
      );
      expect(find.textContaining('#3'), findsOneWidget);
    });

    testWidgets('shows probability percentage', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          ParentComboCard(
            result: _makeResult(probabilityMale: 0.5, probabilityFemale: 0.5),
            rank: 1,
          ),
        ),
      );
      expect(find.textContaining('50.0%'), findsOneWidget);
    });

    testWidgets('shows chance label', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(ParentComboCard(result: _makeResult(), rank: 1)),
      );
      expect(find.textContaining(l10nContains('common.chance')), findsOneWidget);
    });

    testWidgets('shows father and mother labels', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(ParentComboCard(result: _makeResult(), rank: 1)),
      );
      expect(find.text(l10n('genetics.father')), findsOneWidget);
      expect(find.text(l10n('genetics.mother')), findsOneWidget);
    });

    testWidgets('shows X cross icon between parents', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(ParentComboCard(result: _makeResult(), rank: 1)),
      );
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets('shows AppIcon for parent gender icons', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(ParentComboCard(result: _makeResult(), rank: 1)),
      );
      // Both father and mother sides should have AppIcon
      expect(find.byType(AppIcon), findsAtLeastNWidgets(2));
    });

    testWidgets('shows mutation_normal for empty parent genotypes',
        (tester) async {
      const result = ReverseCalculationResult(
        father: ParentGenotype.empty(gender: BirdGender.male),
        mother: ParentGenotype.empty(gender: BirdGender.female),
        probabilityMale: 1.0,
        probabilityFemale: 1.0,
      );

      await pumpLocalizedApp(tester,
        _wrap(const ParentComboCard(result: result, rank: 1)),
      );
      expect(find.text(l10n('genetics.mutation_normal')), findsNWidgets(2));
    });

    testWidgets('shows carrier label for carrier mutations', (tester) async {
      final result = _makeResult(
        fatherMutations: {'ino': AlleleState.carrier},
        motherMutations: {},
      );

      await pumpLocalizedApp(tester,
        _wrap(ParentComboCard(result: result, rank: 1)),
      );
      expect(find.textContaining(l10nContains('genetics.carrier')), findsAtLeastNWidgets(1));
    });

    testWidgets('renders with different ranks', (tester) async {
      for (final rank in [1, 2, 5]) {
        await pumpLocalizedApp(tester,
          _wrap(ParentComboCard(result: _makeResult(), rank: rank)),
        );
        expect(find.textContaining('#$rank'), findsOneWidget);
      }
    });
  });

  group('ParentSideRender', () {
    testWidgets('renders without crashing for male parent', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const ParentSideRender(
            title: 'genetics.father',
            parent: ParentGenotype.empty(gender: BirdGender.male),
            iconColor: Colors.blue,
          ),
        ),
      );
      expect(find.byType(ParentSideRender), findsOneWidget);
    });

    testWidgets('renders without crashing for female parent', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const ParentSideRender(
            title: 'genetics.mother',
            parent: ParentGenotype.empty(gender: BirdGender.female),
            iconColor: Colors.pink,
          ),
        ),
      );
      expect(find.byType(ParentSideRender), findsOneWidget);
    });

    testWidgets('shows title text', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const ParentSideRender(
            title: 'genetics.father',
            parent: ParentGenotype.empty(gender: BirdGender.male),
            iconColor: Colors.blue,
          ),
        ),
      );
      expect(find.text(l10n('genetics.father')), findsOneWidget);
    });

    testWidgets('shows mutation_normal when no mutations', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const ParentSideRender(
            title: 'Test',
            parent: ParentGenotype.empty(gender: BirdGender.male),
            iconColor: Colors.blue,
          ),
        ),
      );
      expect(find.text(l10n('genetics.mutation_normal')), findsOneWidget);
    });

    testWidgets('shows mutation labels when parent has mutations',
        (tester) async {
      final parent = ParentGenotype(
        mutations: {'blue': AlleleState.visual},
        gender: BirdGender.male,
      );

      await pumpLocalizedApp(tester,
        _wrap(
          ParentSideRender(
            title: 'Test',
            parent: parent,
            iconColor: Colors.blue,
          ),
        ),
      );
      // Should show the mutation name and not show "Normal"
      expect(find.text(l10n('genetics.mutation_normal')), findsNothing);
    });

    testWidgets('shows AppIcon for gender', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const ParentSideRender(
            title: 'Test',
            parent: ParentGenotype.empty(gender: BirdGender.male),
            iconColor: Colors.blue,
          ),
        ),
      );
      expect(find.byType(AppIcon), findsOneWidget);
    });
  });
}
