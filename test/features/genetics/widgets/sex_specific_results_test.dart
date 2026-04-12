import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/offspring_prediction.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/sex_specific_results.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

const _bothResult = OffspringResult(
  phenotype: 'Normal Green',
  probability: 0.5,
  sex: OffspringSex.both,
);

const _maleResult = OffspringResult(
  phenotype: 'Lutino Male',
  probability: 0.25,
  sex: OffspringSex.male,
);

const _femaleResult = OffspringResult(
  phenotype: 'Lutino Female',
  probability: 0.25,
  sex: OffspringSex.female,
);

void main() {
  group('SexSpecificResults', () {
    testWidgets('renders without crashing with all-both results', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        _wrap(const SexSpecificResults(results: [_bothResult])),
      );
      expect(find.byType(SexSpecificResults), findsOneWidget);
    });

    testWidgets('shows no TabBar when all results are OffspringSex.both', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        _wrap(const SexSpecificResults(results: [_bothResult])),
      );
      // No sex-specific results → no tab bar
      expect(find.byType(TabBar), findsNothing);
    });

    testWidgets('shows TabBar when sex-specific results exist', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const SexSpecificResults(results: [_maleResult, _femaleResult])),
      );
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('shows three tabs when sex-specific results exist', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        _wrap(const SexSpecificResults(results: [_maleResult, _femaleResult])),
      );
      expect(find.text(l10n('genetics.all_offspring')), findsOneWidget);
      expect(find.text(l10n('genetics.male_offspring')), findsOneWidget);
      expect(find.text(l10n('genetics.female_offspring')), findsOneWidget);
    });

    testWidgets('shows OffspringPrediction cards for results', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const SexSpecificResults(results: [_bothResult])),
      );
      expect(find.byType(OffspringPrediction), findsAtLeastNWidgets(1));
    });

    testWidgets('shows empty message when results list is empty', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,_wrap(const SexSpecificResults(results: [])));
      // _ResultsList shows no_results text
      expect(find.text(l10n('genetics.no_results')), findsOneWidget);
    });

    testWidgets(
      'shows show_more button when results exceed initial visible count',
      (tester) async {
        // Initial visible count is 6; create 7 results
        final results = List.generate(
          7,
          (i) => OffspringResult(
            phenotype: 'Phenotype $i',
            probability: 1 / 7,
            sex: OffspringSex.both,
          ),
        );
        await pumpLocalizedApp(tester,_wrap(SexSpecificResults(results: results)));
        expect(find.text(l10n('genetics.show_more_results')), findsOneWidget);
      },
    );

    testWidgets('does not show show_more when results are 6 or fewer', (
      tester,
    ) async {
      final results = List.generate(
        6,
        (i) => OffspringResult(
          phenotype: 'Phenotype $i',
          probability: 1 / 6,
          sex: OffspringSex.both,
        ),
      );
      await pumpLocalizedApp(tester,_wrap(SexSpecificResults(results: results)));
      expect(find.text(l10n('genetics.show_more_results')), findsNothing);
    });

    testWidgets('tapping show_more expands list', (tester) async {
      final results = List.generate(
        7,
        (i) => OffspringResult(
          phenotype: 'Phenotype $i',
          probability: 1 / 7,
          sex: OffspringSex.both,
        ),
      );
      await pumpLocalizedApp(tester,_wrap(SexSpecificResults(results: results)));
      final showMoreFinder = find.text(l10n('genetics.show_more_results'));
      await tester.ensureVisible(showMoreFinder);
      await tester.tap(showMoreFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text(l10n('genetics.show_less_results')), findsOneWidget);
    });

    testWidgets('renders with mixed sex results', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const SexSpecificResults(
            results: [_bothResult, _maleResult, _femaleResult],
          ),
        ),
      );
      expect(find.byType(SexSpecificResults), findsOneWidget);
    });
  });
}
