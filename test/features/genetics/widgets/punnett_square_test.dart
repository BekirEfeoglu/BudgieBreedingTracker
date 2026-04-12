import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/punnett_square.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

Widget _wrapDark(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}
const _autosomalData = PunnettSquareData(
  mutationName: 'Blue Series',
  fatherAlleles: ['b+', 'b'],
  motherAlleles: ['b+', 'b'],
  cells: [
    ['b+/b+', 'b+/b'],
    ['b+/b', 'b/b'],
  ],
  isSexLinked: false,
);

const _sexLinkedData = PunnettSquareData(
  mutationName: 'Ino Locus',
  fatherAlleles: ['Z+', 'Zino'],
  motherAlleles: ['Zino', 'W'],
  cells: [
    ['Z+/Zino', 'Z+/W'],
    ['Zino/Zino', 'Zino/W'],
  ],
  isSexLinked: true,
);

const _largeData = PunnettSquareData(
  mutationName: 'Test',
  fatherAlleles: ['a', 'b', 'c'],
  motherAlleles: ['x', 'y', 'z'],
  cells: [
    ['a/x', 'a/y', 'a/z'],
    ['b/x', 'b/y', 'b/z'],
    ['c/x', 'c/y', 'c/z'],
  ],
  isSexLinked: false,
);

void main() {
  group('PunnettSquareWidget', () {
    testWidgets('renders without crashing with autosomal data', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _autosomalData)),
      );
      expect(find.byType(PunnettSquareWidget), findsOneWidget);
    });

    testWidgets('renders without crashing with sex-linked data',
        (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _sexLinkedData)),
      );
      expect(find.byType(PunnettSquareWidget), findsOneWidget);
    });

    testWidgets('shows punnett_square title', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _autosomalData)),
      );
      expect(find.text(l10n('genetics.punnett_square')), findsOneWidget);
    });

    testWidgets('shows mutation name for known locus', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _autosomalData)),
      );
      // "Blue Series" maps to 'genetics.locus_blue_series' localization key
      expect(find.text(l10n('genetics.locus_blue_series')), findsOneWidget);
    });

    testWidgets('shows raw mutation name for unknown locus', (tester) async {
      const customData = PunnettSquareData(
        mutationName: 'CustomMutation',
        fatherAlleles: ['a', 'b'],
        motherAlleles: ['c', 'd'],
        cells: [
          ['a/c', 'a/d'],
          ['b/c', 'b/d'],
        ],
        isSexLinked: false,
      );

      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: customData)),
      );
      expect(find.text('CustomMutation'), findsOneWidget);
    });

    testWidgets('shows sex_linked badge for sex-linked data', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _sexLinkedData)),
      );
      expect(find.text(l10n('genetics.sex_linked')), findsOneWidget);
    });

    testWidgets('does not show sex_linked badge for autosomal data',
        (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _autosomalData)),
      );
      expect(find.text(l10n('genetics.sex_linked')), findsNothing);
    });

    testWidgets('shows AppIcon for punnett icon and gender icons', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _autosomalData)),
      );
      // 1 punnett icon + gender icons in header cells
      expect(find.byType(AppIcon), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Table widget', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _autosomalData)),
      );
      expect(find.byType(Table), findsOneWidget);
    });

    testWidgets('renders correct number of table rows for 2x2 grid',
        (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _autosomalData)),
      );
      // 1 header row + 2 data rows = 3 TableRow objects
      final table = tester.widget<Table>(find.byType(Table));
      expect(table.children.length, equals(3));
    });

    testWidgets('renders correct number of table rows for 3x3 grid',
        (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _largeData)),
      );
      // 1 header row + 3 data rows = 4 TableRow objects
      final table = tester.widget<Table>(find.byType(Table));
      expect(table.children.length, equals(4));
    });

    testWidgets('shows father allele labels in data rows', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _autosomalData)),
      );
      // Father alleles shown as text alongside AppIcon
      expect(find.text('b+'), findsAtLeastNWidgets(1));
      expect(find.text('b'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows mother allele labels in header row', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _autosomalData)),
      );
      // Mother alleles shown as text alongside AppIcon
      // b+ and b appear in header cells with female AppIcon
      expect(find.text('b+'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows genotype text in cells', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _autosomalData)),
      );
      expect(find.text('b+/b+'), findsOneWidget);
      expect(find.text('b/b'), findsOneWidget);
      // b+/b appears in two cells
      expect(find.text('b+/b'), findsNWidgets(2));
    });

    testWidgets('shows corner cell with backslash separator', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _autosomalData)),
      );
      // Corner cell now uses AppIcons for gender, with \\ text
      expect(find.text('\\'), findsOneWidget);
    });

    testWidgets('has Tooltip on data cells', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _autosomalData)),
      );
      expect(find.byType(Tooltip), findsAtLeastNWidgets(1));
    });

    testWidgets('renders in dark mode without crashing', (tester) async {
      await pumpLocalizedApp(tester,
        _wrapDark(const PunnettSquareWidget(data: _autosomalData)),
      );
      expect(find.byType(PunnettSquareWidget), findsOneWidget);
    });

    testWidgets('renders sex-linked data with W chromosome label',
        (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _sexLinkedData)),
      );
      // W chromosome should appear in the mother alleles header
      expect(find.textContaining('W'), findsAtLeastNWidgets(1));
    });

    testWidgets('has horizontal scroll for wide tables', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _autosomalData)),
      );
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });

    testWidgets('tooltip shows genotype description for homozygous normal',
        (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _autosomalData)),
      );
      // b+/b+ should have homozygous normal tooltip
      final tooltips = tester.widgetList<Tooltip>(find.byType(Tooltip));
      final messages = tooltips.map((t) => t.message).toList();
      expect(
        messages.any((m) => m == 'genetics.homozygous_normal'),
        isTrue,
      );
    });

    testWidgets('tooltip shows genotype description for homozygous visual',
        (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _autosomalData)),
      );
      // b/b should have homozygous visual tooltip
      final tooltips = tester.widgetList<Tooltip>(find.byType(Tooltip));
      final messages = tooltips.map((t) => t.message).toList();
      expect(
        messages.any((m) => m == 'genetics.homozygous_visual'),
        isTrue,
      );
    });

    testWidgets('tooltip shows genotype description for heterozygous carrier',
        (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const PunnettSquareWidget(data: _autosomalData)),
      );
      // b+/b should have heterozygous carrier tooltip
      final tooltips = tester.widgetList<Tooltip>(find.byType(Tooltip));
      final messages = tooltips.map((t) => t.message).toList();
      expect(
        messages.any((m) => m == 'genetics.heterozygous_carrier'),
        isTrue,
      );
    });
  });
}
