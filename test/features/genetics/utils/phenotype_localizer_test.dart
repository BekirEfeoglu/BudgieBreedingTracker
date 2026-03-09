import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_localizer.dart';

String _t(String key) => '[$key]';

void main() {
  group('PhenotypeLocalizer', () {
    test('localizes mutation names and IDs', () {
      expect(
        PhenotypeLocalizer.localizeMutation('blue', translate: _t),
        '[genetics.mutation_blue]',
      );
      expect(
        PhenotypeLocalizer.localizeMutation('Opaline', translate: _t),
        '[genetics.mutation_opaline]',
      );
    });

    test('localizes carrier list suffix', () {
      final localized = PhenotypeLocalizer.localizePhenotype(
        'Albino (Blue, Opaline carrier)',
        translate: _t,
      );

      expect(
        localized,
        '[genetics.mutation_albino] '
        '([genetics.mutation_blue], [genetics.mutation_opaline] [genetics.carrier])',
      );
    });

    test('localizes single/double/homozygous labels', () {
      expect(
        PhenotypeLocalizer.localizePhenotype(
          'Dark Factor (single)',
          translate: _t,
        ),
        '[genetics.mutation_dark_factor] ([genetics.phenotype_single])',
      );
      expect(
        PhenotypeLocalizer.localizePhenotype('Spangle (double)', translate: _t),
        '[genetics.mutation_spangle] ([genetics.phenotype_double])',
      );
      expect(
        PhenotypeLocalizer.localizePhenotype('Ino (homozygous)', translate: _t),
        '[genetics.mutation_ino] ([genetics.phenotype_homozygous])',
      );
    });

    test('localizes custom compound phenotype labels', () {
      expect(
        PhenotypeLocalizer.localizePhenotype(
          'Melanistic Spangle',
          translate: _t,
        ),
        '[genetics.phenotype_melanistic_spangle]',
      );
      expect(
        PhenotypeLocalizer.localizePhenotype(
          'PallidIno (Lacewing)',
          translate: _t,
        ),
        '[genetics.phenotype_pallidino_lacewing]',
      );
    });

    test('localizes slash-separated phenotype labels', () {
      expect(
        PhenotypeLocalizer.localizePhenotype(
          'Cinnamon / Opaline',
          translate: _t,
        ),
        '[genetics.mutation_cinnamon] / [genetics.mutation_opaline]',
      );
    });
  });
}
