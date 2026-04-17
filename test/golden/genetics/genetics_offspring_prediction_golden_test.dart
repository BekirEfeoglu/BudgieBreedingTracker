@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/theme/app_theme.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/offspring_prediction.dart';

// IMPROVED: golden tests for offspring prediction card visual regression detection

void main() {
  testWidgets('renders offspring prediction card with carrier badge', (
    tester,
  ) async {
    const result = OffspringResult(
      phenotype: 'Normal',
      probability: 0.25,
      sex: OffspringSex.both,
      isCarrier: true,
      visualMutations: [],
      carriedMutations: ['ino'],
    );

    await _pumpGolden(
      tester,
      const Size(500, 300),
      const OffspringPrediction(result: result),
    );

    await expectLater(
      find.byType(OffspringPrediction),
      matchesGoldenFile('goldens/offspring_prediction_carrier.png'),
    );
  });

  testWidgets('renders offspring prediction card with compound phenotype', (
    tester,
  ) async {
    const result = OffspringResult(
      phenotype: 'Ino Blue',
      probability: 0.0625,
      sex: OffspringSex.female,
      compoundPhenotype: 'Albino',
      visualMutations: ['ino', 'blue'],
    );

    await _pumpGolden(
      tester,
      const Size(500, 300),
      const OffspringPrediction(result: result),
    );

    await expectLater(
      find.byType(OffspringPrediction),
      matchesGoldenFile('goldens/offspring_prediction_compound.png'),
    );
  });

  testWidgets('renders offspring prediction with genotype expanded', (
    tester,
  ) async {
    const result = OffspringResult(
      phenotype: 'Opaline Cinnamon',
      probability: 0.125,
      sex: OffspringSex.male,
      genotype: 'Z_op/Z+ · Z_cin/Z+',
      visualMutations: ['opaline', 'cinnamon'],
    );

    await _pumpGolden(
      tester,
      const Size(500, 350),
      const OffspringPrediction(result: result, showGenotype: true),
    );

    await expectLater(
      find.byType(OffspringPrediction),
      matchesGoldenFile('goldens/offspring_prediction_genotype.png'),
    );
  });
}

Future<void> _pumpGolden(WidgetTester tester, Size size, Widget child) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
