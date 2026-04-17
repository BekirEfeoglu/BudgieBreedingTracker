@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/theme/app_theme.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/punnett_square.dart';

// IMPROVED: golden tests for Punnett square visual regression detection

void main() {
  testWidgets('renders 4x4 autosomal recessive Punnett square', (
    tester,
  ) async {
    const data = PunnettSquareData(
      mutationName: 'Ino',
      fatherAlleles: ['ino', '+'],
      motherAlleles: ['ino', '+'],
      cells: [
        ['ino/ino', 'ino/+'],
        ['+/ino', '+/+'],
      ],
      isSexLinked: false,
    );

    await _pumpGolden(tester, const Size(400, 300), const PunnettSquareWidget(data: data));

    await expectLater(
      find.byType(PunnettSquareWidget),
      matchesGoldenFile('goldens/punnett_square_autosomal.png'),
    );
  });

  testWidgets('renders sex-linked Punnett square', (tester) async {
    const data = PunnettSquareData(
      mutationName: 'Opaline',
      fatherAlleles: ['op', '+'],
      motherAlleles: ['op', 'W'],
      cells: [
        ['op/op', 'op/W'],
        ['+/op', '+/W'],
      ],
      isSexLinked: true,
    );

    await _pumpGolden(tester, const Size(400, 300), const PunnettSquareWidget(data: data));

    await expectLater(
      find.byType(PunnettSquareWidget),
      matchesGoldenFile('goldens/punnett_square_sex_linked.png'),
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
