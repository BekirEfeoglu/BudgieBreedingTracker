import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/results_summary_banner.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('ResultsSummaryBanner', () {
    testWidgets('returns nothing (SizedBox.shrink) when results is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const ResultsSummaryBanner(results: [])));
      await tester.pump();

      expect(find.byType(Container), findsNothing);
    });

    testWidgets('renders without crashing with one result', (tester) async {
      const results = [OffspringResult(phenotype: 'Green', probability: 1.0)];
      await tester.pumpWidget(
        _wrap(const ResultsSummaryBanner(results: results)),
      );
      await tester.pump();

      expect(find.byType(ResultsSummaryBanner), findsOneWidget);
    });

    testWidgets('shows Container when results is not empty', (tester) async {
      const results = [OffspringResult(phenotype: 'Green', probability: 0.5)];
      await tester.pumpWidget(
        _wrap(const ResultsSummaryBanner(results: results)),
      );
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('shows total_variations label', (tester) async {
      const results = [
        OffspringResult(phenotype: 'Green', probability: 0.5),
        OffspringResult(phenotype: 'Blue', probability: 0.5),
      ];
      await tester.pumpWidget(
        _wrap(const ResultsSummaryBanner(results: results)),
      );
      await tester.pump();

      expect(find.text(l10n('genetics.total_variations')), findsOneWidget);
    });

    testWidgets('shows variation count as text', (tester) async {
      const results = [
        OffspringResult(phenotype: 'Green', probability: 0.75),
        OffspringResult(phenotype: 'Blue', probability: 0.25),
      ];
      await tester.pumpWidget(
        _wrap(const ResultsSummaryBanner(results: results)),
      );
      await tester.pump();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('shows top result probability as percentage', (tester) async {
      const results = [OffspringResult(phenotype: 'Lutino', probability: 0.75)];
      await tester.pumpWidget(
        _wrap(const ResultsSummaryBanner(results: results)),
      );
      await tester.pump();

      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('shows phenotype name of top result', (tester) async {
      const results = [OffspringResult(phenotype: 'Albino', probability: 0.5)];
      await tester.pumpWidget(
        _wrap(const ResultsSummaryBanner(results: results)),
      );
      await tester.pump();

      expect(find.textContaining(l10nContains('genetics.mutation')), findsAtLeastNWidgets(1));
    });

    testWidgets('shows carrier_ratio when carrier results exist', (
      tester,
    ) async {
      const results = [
        OffspringResult(phenotype: 'Green', probability: 0.5, isCarrier: true),
        OffspringResult(phenotype: 'Blue', probability: 0.5),
      ];
      await tester.pumpWidget(
        _wrap(const ResultsSummaryBanner(results: results)),
      );
      await tester.pump();

      expect(find.text(l10n('genetics.carrier_ratio')), findsOneWidget);
    });

    testWidgets('does not show carrier_ratio when no carrier results', (
      tester,
    ) async {
      const results = [OffspringResult(phenotype: 'Green', probability: 1.0)];
      await tester.pumpWidget(
        _wrap(const ResultsSummaryBanner(results: results)),
      );
      await tester.pump();

      expect(find.text(l10n('genetics.carrier_ratio')), findsNothing);
    });

    testWidgets('shows Row layout for the stat columns', (tester) async {
      const results = [OffspringResult(phenotype: 'Opaline', probability: 1.0)];
      await tester.pumpWidget(
        _wrap(const ResultsSummaryBanner(results: results)),
      );
      await tester.pump();

      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });
  });
}
