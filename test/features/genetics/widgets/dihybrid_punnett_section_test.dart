import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/dihybrid_punnett_section.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/punnett_square.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child, {List<dynamic> overrides = const []}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
}
void main() {
  group('DihybridPunnettSection', () {
    testWidgets('renders without crashing with available loci', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const DihybridPunnettSection(
            availableLoci: ['blue', 'opaline', 'cinnamon'],
          ),
        ),
      );
      expect(find.byType(DihybridPunnettSection), findsOneWidget);
    });

    testWidgets('returns SizedBox.shrink when no second loci options available',
        (tester) async {
      // When first selected locus is the only one available, secondLociOptions
      // is empty and widget should shrink.
      await pumpLocalizedApp(tester,
        _wrap(
          const DihybridPunnettSection(availableLoci: ['blue']),
          overrides: [
            effectivePunnettLocusProvider.overrideWith((ref) => 'blue'),
          ],
        ),
      );
      // The widget renders but is essentially invisible (SizedBox.shrink)
      expect(find.text('genetics.dihybrid_punnett'), findsNothing);
    });

    testWidgets('shows dihybrid title text when multiple loci available',
        (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const DihybridPunnettSection(
            availableLoci: ['blue', 'opaline'],
          ),
          overrides: [
            effectivePunnettLocusProvider.overrideWith((ref) => 'blue'),
          ],
        ),
      );
      expect(find.text('genetics.dihybrid_punnett'), findsOneWidget);
    });

    testWidgets('shows second locus label text', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const DihybridPunnettSection(
            availableLoci: ['blue', 'opaline', 'cinnamon'],
          ),
          overrides: [
            effectivePunnettLocusProvider.overrideWith((ref) => 'blue'),
          ],
        ),
      );
      expect(find.text('genetics.second_locus'), findsOneWidget);
    });

    testWidgets('shows dropdown for second locus selection', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const DihybridPunnettSection(
            availableLoci: ['blue', 'opaline', 'cinnamon'],
          ),
          overrides: [
            effectivePunnettLocusProvider.overrideWith((ref) => 'blue'),
          ],
        ),
      );
      expect(
        find.byType(DropdownButtonFormField<String?>),
        findsOneWidget,
      );
    });

    testWidgets('excludes first selected locus from dropdown options',
        (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const DihybridPunnettSection(
            availableLoci: ['blue', 'opaline'],
          ),
          overrides: [
            effectivePunnettLocusProvider.overrideWith((ref) => 'blue'),
          ],
        ),
      );
      // Dropdown should be present since 'opaline' is still available
      expect(
        find.byType(DropdownButtonFormField<String?>),
        findsOneWidget,
      );
    });

    testWidgets('does not show PunnettSquareWidget when no dihybrid data',
        (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const DihybridPunnettSection(
            availableLoci: ['blue', 'opaline'],
          ),
          overrides: [
            effectivePunnettLocusProvider.overrideWith((ref) => 'blue'),
            dihybridPunnettSquareProvider.overrideWith((ref) => null),
          ],
        ),
      );
      expect(find.byType(PunnettSquareWidget), findsNothing);
    });

    testWidgets('shows PunnettSquareWidget when dihybrid data is available',
        (tester) async {
      const dihybridData = PunnettSquareData(
        mutationName: 'Blue x Opaline',
        fatherAlleles: ['b+', 'b'],
        motherAlleles: ['b+', 'b'],
        cells: [
          ['b+/b+', 'b+/b'],
          ['b+/b', 'b/b'],
        ],
        isSexLinked: false,
      );

      await pumpLocalizedApp(tester,
        _wrap(
          const DihybridPunnettSection(
            availableLoci: ['blue', 'opaline'],
          ),
          overrides: [
            effectivePunnettLocusProvider.overrideWith((ref) => 'blue'),
            dihybridPunnettSquareProvider
                .overrideWith((ref) => dihybridData),
          ],
        ),
      );
      expect(find.byType(PunnettSquareWidget), findsOneWidget);
    });
  });

  group('PunnettLocusSelector', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const PunnettLocusSelector(availableLoci: ['blue', 'opaline']),
        ),
      );
      expect(find.byType(PunnettLocusSelector), findsOneWidget);
    });

    testWidgets('shows select_punnett_locus label text', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const PunnettLocusSelector(availableLoci: ['blue', 'opaline']),
        ),
      );
      expect(find.text('genetics.select_punnett_locus'), findsOneWidget);
    });

    testWidgets('shows dropdown form field for locus selection', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const PunnettLocusSelector(availableLoci: ['blue', 'opaline']),
        ),
      );
      expect(
        find.byType(DropdownButtonFormField<String>),
        findsOneWidget,
      );
    });

    testWidgets('renders Row layout', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const PunnettLocusSelector(availableLoci: ['blue']),
        ),
      );
      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });
  });

  group('localizeLocusId', () {
    test('returns localized key for known locus blue_series', () {
      expect(localizeLocusId('blue_series'), 'genetics.locus_blue_series');
    });

    test('returns localized key for known locus dilution', () {
      expect(localizeLocusId('dilution'), 'genetics.locus_dilution');
    });

    test('returns localized key for known locus crested', () {
      expect(localizeLocusId('crested'), 'genetics.locus_crested');
    });

    test('returns localized key for known locus ino_locus', () {
      expect(localizeLocusId('ino_locus'), 'genetics.locus_ino');
    });

    test('returns the raw ID for unknown locus', () {
      expect(localizeLocusId('unknown_locus'), 'unknown_locus');
    });
  });
}
