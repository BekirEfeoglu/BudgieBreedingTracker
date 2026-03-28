import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/offspring_prediction_details.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/action_feedback_providers.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));
}

void main() {
  setUp(() {
    ActionFeedbackService.resetForTesting();
  });

  group('PhenotypeBadges', () {
    testWidgets('renders display name', (tester) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.5,
      );

      await pumpLocalizedApp(
        tester,
        _wrap(const PhenotypeBadges(
          displayName: 'Normal Green',
          result: result,
        )),
      );

      expect(find.text('Normal Green'), findsOneWidget);
    });

    testWidgets('shows carrier badge when isCarrier', (tester) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.25,
        isCarrier: true,
        carriedMutations: ['Blue'],
      );

      await pumpLocalizedApp(
        tester,
        _wrap(const PhenotypeBadges(
          displayName: 'Normal Green',
          result: result,
        )),
      );

      expect(find.text('genetics.carrier'), findsOneWidget);
    });

    testWidgets('does not show carrier badge when not carrier', (
      tester,
    ) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.5,
      );

      await pumpLocalizedApp(
        tester,
        _wrap(const PhenotypeBadges(
          displayName: 'Normal Green',
          result: result,
        )),
      );

      expect(find.text('genetics.carrier'), findsNothing);
    });

    testWidgets('shows lethal badge when lethalCombinationIds is not empty', (
      tester,
    ) async {
      const result = OffspringResult(
        phenotype: 'DF Crested',
        probability: 0.25,
        lethalCombinationIds: ['df_crested'],
      );

      await pumpLocalizedApp(
        tester,
        _wrap(const PhenotypeBadges(
          displayName: 'DF Crested',
          result: result,
        )),
      );

      expect(find.text('genetics.lethal_badge'), findsOneWidget);
    });

    testWidgets('does not show lethal badge when no lethal combinations', (
      tester,
    ) async {
      const result = OffspringResult(
        phenotype: 'Normal',
        probability: 0.5,
      );

      await pumpLocalizedApp(
        tester,
        _wrap(const PhenotypeBadges(
          displayName: 'Normal',
          result: result,
        )),
      );

      expect(find.text('genetics.lethal_badge'), findsNothing);
    });
  });

  group('ExpandedDetails', () {
    testWidgets('shows carried mutations when not empty', (tester) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.25,
        isCarrier: true,
        carriedMutations: ['Blue', 'Opaline'],
      );

      await pumpLocalizedApp(
        tester,
        _wrap(const ExpandedDetails(
          result: result,
          localizedCarriedMutations: ['Blue', 'Opaline'],
          localizedMaskedMutations: [],
          showGenotype: false,
        )),
      );

      expect(find.text('Blue, Opaline'), findsOneWidget);
    });

    testWidgets('shows masked mutations when not empty', (tester) async {
      const result = OffspringResult(
        phenotype: 'Ino',
        probability: 0.25,
        maskedMutations: ['Opaline'],
      );

      await pumpLocalizedApp(
        tester,
        _wrap(const ExpandedDetails(
          result: result,
          localizedCarriedMutations: [],
          localizedMaskedMutations: ['Opaline'],
          showGenotype: false,
        )),
      );

      expect(
        find.textContaining('genetics.masked_mutations'),
        findsOneWidget,
      );
    });

    testWidgets('shows genotype when showGenotype is true', (tester) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.5,
        genotype: '+/+ bl/bl',
      );

      await pumpLocalizedApp(
        tester,
        _wrap(const ExpandedDetails(
          result: result,
          localizedCarriedMutations: [],
          localizedMaskedMutations: [],
          showGenotype: true,
        )),
      );

      expect(find.text('+/+ bl/bl'), findsOneWidget);
    });

    testWidgets('hides genotype when showGenotype is false', (tester) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.5,
        genotype: '+/+ bl/bl',
      );

      await pumpLocalizedApp(
        tester,
        _wrap(const ExpandedDetails(
          result: result,
          localizedCarriedMutations: [],
          localizedMaskedMutations: [],
          showGenotype: false,
        )),
      );

      expect(find.text('+/+ bl/bl'), findsNothing);
    });

    testWidgets('renders empty when no carried/masked/genotype', (
      tester,
    ) async {
      const result = OffspringResult(
        phenotype: 'Normal Green',
        probability: 0.5,
      );

      await pumpLocalizedApp(
        tester,
        _wrap(const ExpandedDetails(
          result: result,
          localizedCarriedMutations: [],
          localizedMaskedMutations: [],
          showGenotype: false,
        )),
      );

      // ExpandedDetails renders an empty Column
      expect(find.byType(ExpandedDetails), findsOneWidget);
    });
  });

  group('SexIcon', () {
    testWidgets('renders male icon as AppIcon', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const SexIcon(sex: OffspringSex.male)),
      );

      expect(find.byType(AppIcon), findsOneWidget);
    });

    testWidgets('renders female icon as AppIcon', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const SexIcon(sex: OffspringSex.female)),
      );

      expect(find.byType(AppIcon), findsOneWidget);
    });

    testWidgets('renders both sexes with unisex badge', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const SexIcon(sex: OffspringSex.both)),
      );

      expect(find.byType(AppIcon), findsOneWidget);
      expect(find.text('genetics.both_sexes_label'), findsOneWidget);
    });
  });
}
