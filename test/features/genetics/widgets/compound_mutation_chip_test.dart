import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_types.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/compound_mutation_chip.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: Center(child: child)));
}

BudgieMutationRecord _mutation({
  required String id,
  required String name,
  required String localizationKey,
}) {
  return BudgieMutationRecord(
    id: id,
    name: name,
    localizationKey: localizationKey,
    description: '',
    inheritanceType: InheritanceType.autosomalRecessive,
    dominance: Dominance.recessive,
    alleleSymbol: id[0],
    alleles: ['+', id[0]],
    category: 'test',
  );
}

void main() {
  group('CompoundMutationChip', () {
    final records = [
      _mutation(
        id: 'greywing',
        name: 'Greywing',
        localizationKey: 'genetics.greywing',
      ),
      _mutation(
        id: 'clearwing',
        name: 'Clearwing',
        localizationKey: 'genetics.clearwing',
      ),
    ];

    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(CompoundMutationChip(records: records, onRemove: () {})),
      );
      await tester.pump();

      expect(find.byType(CompoundMutationChip), findsOneWidget);
    });

    testWidgets('shows compound label from mutation localization keys',
        (tester) async {
      await tester.pumpWidget(
        _wrap(CompoundMutationChip(records: records, onRemove: () {})),
      );
      await tester.pump();

      // Without EasyLocalization, .tr() returns the key itself
      expect(
        find.text('genetics.greywing / genetics.clearwing'),
        findsOneWidget,
      );
    });

    testWidgets('shows compound_short badge', (tester) async {
      await tester.pumpWidget(
        _wrap(CompoundMutationChip(records: records, onRemove: () {})),
      );
      await tester.pump();

      expect(find.text('genetics.compound_short'), findsOneWidget);
    });

    testWidgets('renders as InputChip', (tester) async {
      await tester.pumpWidget(
        _wrap(CompoundMutationChip(records: records, onRemove: () {})),
      );
      await tester.pump();

      expect(find.byType(InputChip), findsOneWidget);
    });

    testWidgets('shows delete icon', (tester) async {
      await tester.pumpWidget(
        _wrap(CompoundMutationChip(records: records, onRemove: () {})),
      );
      await tester.pump();

      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets('calls onRemove when delete is tapped', (tester) async {
      var removed = false;
      await tester.pumpWidget(
        _wrap(CompoundMutationChip(
          records: records,
          onRemove: () => removed = true,
        )),
      );
      await tester.pump();

      // Tap the delete icon on the InputChip
      await tester.tap(find.byIcon(LucideIcons.x));
      expect(removed, isTrue);
    });

    testWidgets('shows single mutation when only one record', (tester) async {
      final singleRecord = [
        _mutation(
          id: 'greywing',
          name: 'Greywing',
          localizationKey: 'genetics.greywing',
        ),
      ];
      await tester.pumpWidget(
        _wrap(CompoundMutationChip(records: singleRecord, onRemove: () {})),
      );
      await tester.pump();

      expect(find.text('genetics.greywing'), findsOneWidget);
    });
  });
}
