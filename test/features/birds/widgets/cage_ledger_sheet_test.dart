import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/cage_ledger_sheet.dart';

import '../../../helpers/test_fixtures.dart';
import '../../../helpers/test_localization.dart';

void main() {
  testWidgets(
    'renders cage groups with occupancy counts and unassigned birds',
    (tester) async {
      final birds = [
        createTestBird(id: 'b1', name: 'Mavi', cageNumber: 'K1'),
        createTestBird(
          id: 'b2',
          name: 'Sari',
          cageNumber: 'K1',
          gender: BirdGender.female,
        ),
        createTestBird(id: 'b3', name: 'Bos Kafes Yok'),
      ];

      await pumpLocalizedWidget(
        tester,
        CageLedgerSheet(birds: birds, onBirdTap: (_) {}),
      );

      expect(find.text('birds.cage_ledger'), findsOneWidget);
      expect(find.byTooltip('common.close'), findsOneWidget);
      expect(find.text('K1'), findsOneWidget);
      expect(find.text('2 birds.cage_occupants'), findsOneWidget);
      expect(find.text('birds.unassigned_cage'), findsOneWidget);
      expect(find.text('Mavi'), findsOneWidget);
      expect(find.text('Sari'), findsOneWidget);
      expect(find.text('Bos Kafes Yok'), findsOneWidget);
    },
  );

  testWidgets('calls onBirdTap when a bird row is tapped', (tester) async {
    String? tappedId;
    final birds = [createTestBird(id: 'b1', name: 'Mavi', cageNumber: 'K1')];

    await pumpLocalizedWidget(
      tester,
      CageLedgerSheet(birds: birds, onBirdTap: (bird) => tappedId = bird.id),
    );

    await tester.tap(find.text('Mavi'));
    await tester.pump();

    expect(tappedId, 'b1');
  });

  testWidgets('closes the bottom sheet from the header action', (tester) async {
    final birds = [createTestBird(id: 'b1', name: 'Mavi', cageNumber: 'K1')];

    await pumpLocalizedWidget(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              builder: (_) => CageLedgerSheet(birds: birds, onBirdTap: (_) {}),
            );
          },
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('birds.cage_ledger'), findsOneWidget);

    await tester.tap(find.byTooltip('common.close'));
    await tester.pumpAndSettle();

    expect(find.text('birds.cage_ledger'), findsNothing);
  });
}
