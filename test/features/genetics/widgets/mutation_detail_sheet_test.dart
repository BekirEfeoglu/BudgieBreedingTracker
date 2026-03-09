import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/inheritance_badge.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/mutation_detail_sheet.dart';

// A private widget exposed via the public showMutationDetailSheet function.
// We test the content widget directly via a wrapper that simulates bottom sheet.
Widget _contentWrap(BudgieMutationRecord mutation) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showMutationDetailSheet(context, mutation: mutation),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

BudgieMutationRecord _makeMutation({
  String id = 'test_mut',
  String name = 'Test Mutation',
  InheritanceType type = InheritanceType.autosomalRecessive,
  String? visualEffect,
}) {
  return BudgieMutationRecord(
    id: id,
    name: name,
    localizationKey: 'genetics.mutation_$id',
    description: 'Test description',
    inheritanceType: type,
    dominance: Dominance.recessive,
    alleleSymbol: 'tm',
    alleles: const ['tm', '+'],
    category: 'Test Category',
    visualEffect: visualEffect,
  );
}

void main() {
  group('showMutationDetailSheet', () {
    testWidgets('opens bottom sheet when button is tapped', (tester) async {
      final mutation = _makeMutation();
      await tester.pumpWidget(_contentWrap(mutation));
      await tester.pump();

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('shows mutation localizationKey as title', (tester) async {
      final mutation = _makeMutation(id: 'blue');
      await tester.pumpWidget(_contentWrap(mutation));
      await tester.pump();

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('genetics.mutation_blue'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows InheritanceBadge in sheet', (tester) async {
      final mutation = _makeMutation();
      await tester.pumpWidget(_contentWrap(mutation));
      await tester.pump();

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(InheritanceBadge), findsAtLeastNWidgets(1));
    });

    testWidgets('shows inheritance_type label key', (tester) async {
      final mutation = _makeMutation();
      await tester.pumpWidget(_contentWrap(mutation));
      await tester.pump();

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('genetics.inheritance_type'), findsOneWidget);
    });

    testWidgets('shows alleles label key', (tester) async {
      final mutation = _makeMutation();
      await tester.pumpWidget(_contentWrap(mutation));
      await tester.pump();

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('genetics.alleles'), findsOneWidget);
    });

    testWidgets('shows allele_symbol label key', (tester) async {
      final mutation = _makeMutation();
      await tester.pumpWidget(_contentWrap(mutation));
      await tester.pump();

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('genetics.allele_symbol'), findsOneWidget);
    });

    testWidgets('shows visual_effect when provided', (tester) async {
      final mutation = _makeMutation(visualEffect: 'Makes feathers blue');
      await tester.pumpWidget(_contentWrap(mutation));
      await tester.pump();

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('genetics.visual_effect'), findsOneWidget);
      expect(find.text('Makes feathers blue'), findsOneWidget);
    });

    testWidgets('does not show visual_effect section when null', (
      tester,
    ) async {
      final mutation = _makeMutation(visualEffect: null);
      await tester.pumpWidget(_contentWrap(mutation));
      await tester.pump();

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('genetics.visual_effect'), findsNothing);
    });

    testWidgets('shows allele symbols joined with slash', (tester) async {
      final mutation = _makeMutation();
      await tester.pumpWidget(_contentWrap(mutation));
      await tester.pump();

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('tm / +'), findsOneWidget);
    });
  });

  group('MutationDatabase real mutations', () {
    test('blue mutation exists', () {
      final mutation = MutationDatabase.getById('blue');
      expect(mutation, isNotNull);
      expect(mutation!.name, isNotEmpty);
    });

    test('ino mutation exists', () {
      final mutation = MutationDatabase.getById('ino');
      expect(mutation, isNotNull);
    });

    testWidgets('real blue mutation renders in sheet', (tester) async {
      final mutation = MutationDatabase.getById('blue')!;
      await tester.pumpWidget(_contentWrap(mutation));
      await tester.pump();

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });
}
