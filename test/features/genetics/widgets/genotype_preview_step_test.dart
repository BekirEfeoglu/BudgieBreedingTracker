import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/genotype_preview_step.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/selection_summary.dart';

const _emptyMale = ParentGenotype.empty(gender: BirdGender.male);
const _emptyFemale = ParentGenotype.empty(gender: BirdGender.female);

final _maleMutation = ParentGenotype(
  mutations: {'nonexistent_id': AlleleState.visual},
  gender: BirdGender.male,
);

List<dynamic> _defaultOverrides() => [
  fatherGenotypeProvider.overrideWith(FatherGenotypeNotifier.new),
  motherGenotypeProvider.overrideWith(MotherGenotypeNotifier.new),
];

Widget _wrap(Widget child, {List<dynamic> overrides = const []}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('GenotypePreviewStep', () {
    testWidgets('renders without crashing with empty genotypes', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const GenotypePreviewStep(
            fatherGenotype: _emptyMale,
            motherGenotype: _emptyFemale,
          ),
          overrides: _defaultOverrides(),
        ),
      );
      await tester.pump();
      expect(find.byType(GenotypePreviewStep), findsOneWidget);
    });

    testWidgets('shows genotype_preview title key', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GenotypePreviewStep(
            fatherGenotype: _emptyMale,
            motherGenotype: _emptyFemale,
          ),
          overrides: _defaultOverrides(),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('genetics.genotype_preview')), findsOneWidget);
    });

    testWidgets('shows carrier_info_tip text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GenotypePreviewStep(
            fatherGenotype: _emptyMale,
            motherGenotype: _emptyFemale,
          ),
          overrides: _defaultOverrides(),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('genetics.carrier_info_tip')), findsOneWidget);
    });

    testWidgets('shows two SelectionSummary widgets', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GenotypePreviewStep(
            fatherGenotype: _emptyMale,
            motherGenotype: _emptyFemale,
          ),
          overrides: _defaultOverrides(),
        ),
      );
      await tester.pump();
      expect(find.byType(SelectionSummary), findsNWidgets(2));
    });

    testWidgets('shows father_mutations label key', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GenotypePreviewStep(
            fatherGenotype: _emptyMale,
            motherGenotype: _emptyFemale,
          ),
          overrides: _defaultOverrides(),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('genetics.father_mutations')), findsOneWidget);
    });

    testWidgets('shows mother_mutations label key', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GenotypePreviewStep(
            fatherGenotype: _emptyMale,
            motherGenotype: _emptyFemale,
          ),
          overrides: _defaultOverrides(),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('genetics.mother_mutations')), findsOneWidget);
    });

    testWidgets('renders with non-empty father genotype', (tester) async {
      await tester.pumpWidget(
        _wrap(
          GenotypePreviewStep(
            fatherGenotype: _maleMutation,
            motherGenotype: _emptyFemale,
          ),
          overrides: _defaultOverrides(),
        ),
      );
      await tester.pump();
      expect(find.byType(GenotypePreviewStep), findsOneWidget);
    });

    testWidgets('shows two Card widgets for father and mother', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GenotypePreviewStep(
            fatherGenotype: _emptyMale,
            motherGenotype: _emptyFemale,
          ),
          overrides: _defaultOverrides(),
        ),
      );
      await tester.pump();
      expect(find.byType(Card), findsAtLeastNWidgets(2));
    });
  });
}
