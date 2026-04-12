import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/inheritance_badge.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/mutation_detail_sheet.dart';

import '../../../helpers/test_localization.dart';

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
      await pumpLocalizedApp(tester, _contentWrap(mutation));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('shows mutation localizationKey as title', (tester) async {
      final mutation = _makeMutation(id: 'blue');
      await pumpLocalizedApp(tester, _contentWrap(mutation));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l10n('genetics.mutation_blue')), findsAtLeastNWidgets(1));
    });

    testWidgets('shows InheritanceBadge in sheet', (tester) async {
      final mutation = _makeMutation();
      await pumpLocalizedApp(tester, _contentWrap(mutation));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(InheritanceBadge), findsAtLeastNWidgets(1));
    });

    testWidgets('shows inheritance_type label key', (tester) async {
      final mutation = _makeMutation();
      await pumpLocalizedApp(tester, _contentWrap(mutation));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l10n('genetics.inheritance_type')), findsOneWidget);
    });

    testWidgets('shows alleles label key', (tester) async {
      final mutation = _makeMutation();
      await pumpLocalizedApp(tester, _contentWrap(mutation));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l10n('genetics.alleles')), findsOneWidget);
    });

    testWidgets('shows allele_symbol label key', (tester) async {
      final mutation = _makeMutation();
      await pumpLocalizedApp(tester, _contentWrap(mutation));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l10n('genetics.allele_symbol')), findsOneWidget);
    });

    testWidgets('shows visual_effect when provided', (tester) async {
      final mutation = _makeMutation(visualEffect: 'Makes feathers blue');
      await pumpLocalizedApp(tester, _contentWrap(mutation));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l10n('genetics.visual_effect')), findsOneWidget);
      expect(find.text('Makes feathers blue'), findsOneWidget);
    });

    testWidgets('does not show visual_effect section when null', (
      tester,
    ) async {
      final mutation = _makeMutation(visualEffect: null);
      await pumpLocalizedApp(tester, _contentWrap(mutation));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l10n('genetics.visual_effect')), findsNothing);
    });

    testWidgets('shows allele symbols joined with slash', (tester) async {
      final mutation = _makeMutation();
      await pumpLocalizedApp(tester, _contentWrap(mutation));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('tm / +'), findsOneWidget);
    });
  });

  group('Z-chromosome linkage section', () {
    testWidgets('shows linkage section for sex-linked mutation with data', (
      tester,
    ) async {
      final cinnamon = MutationDatabase.getById('cinnamon')!;
      await pumpLocalizedApp(tester, _contentWrap(cinnamon));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Linkage header should appear
      expect(find.text(l10n('genetics.z_linkage')), findsOneWidget);
      // Gene order should appear
      expect(find.text(l10n('genetics.z_gene_order')), findsOneWidget);
      // Linkage partners should appear (Ino, Slate, Opaline)
      expect(find.text('Ino'), findsAtLeastNWidgets(1));
      expect(find.text('Slate'), findsAtLeastNWidgets(1));
      expect(find.text('Opaline'), findsAtLeastNWidgets(1));
    });

    testWidgets('does not show linkage section for autosomal mutation', (
      tester,
    ) async {
      final blue = MutationDatabase.getById('blue')!;
      await pumpLocalizedApp(tester, _contentWrap(blue));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l10n('genetics.z_linkage')), findsNothing);
    });

    testWidgets(
      'does not show linkage section for sex-linked mutation without data',
      (tester) async {
        // Create a sex-linked mutation not in the linkage map.
        final custom = _makeMutation(
          id: 'custom_sl',
          type: InheritanceType.sexLinkedRecessive,
        );
        await pumpLocalizedApp(tester, _contentWrap(custom));
        await tester.tap(find.text('open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        // Sex-linked but no linkage data → section hidden
        expect(find.text(l10n('genetics.z_linkage')), findsNothing);
      },
    );

    testWidgets('shows linkage for pearly (ino locus position)', (
      tester,
    ) async {
      final pearly = MutationDatabase.getById('pearly')!;
      await pumpLocalizedApp(tester, _contentWrap(pearly));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(l10n('genetics.z_linkage')), findsOneWidget);
      expect(find.text('Cinnamon'), findsAtLeastNWidgets(1));
    });
  });

  group('MutationDatabase real mutations', () {
    test('blue mutation exists', () {
      final mutation = MutationDatabase.getById('blue')!;
      expect(mutation.name, 'Blue');
    });

    test('ino mutation exists', () {
      final mutation = MutationDatabase.getById('ino')!;
      expect(mutation.name, 'Ino');
    });

    testWidgets('real blue mutation renders in sheet', (tester) async {
      final mutation = MutationDatabase.getById('blue')!;
      await pumpLocalizedApp(tester, _contentWrap(mutation));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });
}
