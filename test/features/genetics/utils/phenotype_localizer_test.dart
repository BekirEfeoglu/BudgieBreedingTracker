import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_localizer.dart';

String _t(String key) => '[$key]';

/// Resolves a dot-separated key in a nested JSON map.
dynamic _resolveKey(Map<String, dynamic> json, String dotKey) {
  final parts = dotKey.split('.');
  dynamic current = json;
  for (final part in parts) {
    if (current is! Map<String, dynamic> || !current.containsKey(part)) {
      return null;
    }
    current = current[part];
  }
  return current;
}

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

  group('L10n validation', () {
    late Map<String, dynamic> trJson;
    late Map<String, dynamic> enJson;
    late Map<String, dynamic> deJson;

    setUpAll(() {
      trJson = jsonDecode(
        File('assets/translations/tr.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      enJson = jsonDecode(
        File('assets/translations/en.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      deJson = jsonDecode(
        File('assets/translations/de.json').readAsStringSync(),
      ) as Map<String, dynamic>;
    });

    test('all PhenotypeLocalizer phrase keys exist in tr.json', () {
      final missing = <String>[];
      for (final key in PhenotypeLocalizer.allReferencedKeys) {
        if (_resolveKey(trJson, key) == null) missing.add(key);
      }
      expect(missing, isEmpty, reason: 'Missing keys in tr.json: $missing');
    });

    test('all PhenotypeLocalizer phrase keys exist in en.json', () {
      final missing = <String>[];
      for (final key in PhenotypeLocalizer.allReferencedKeys) {
        if (_resolveKey(enJson, key) == null) missing.add(key);
      }
      expect(missing, isEmpty, reason: 'Missing keys in en.json: $missing');
    });

    test('all PhenotypeLocalizer phrase keys exist in de.json', () {
      final missing = <String>[];
      for (final key in PhenotypeLocalizer.allReferencedKeys) {
        if (_resolveKey(deJson, key) == null) missing.add(key);
      }
      expect(missing, isEmpty, reason: 'Missing keys in de.json: $missing');
    });

    test('all MutationDatabase localizationKeys exist in tr.json', () {
      final missing = <String>[];
      for (final m in MutationDatabase.getAll()) {
        if (_resolveKey(trJson, m.localizationKey) == null) {
          missing.add('${m.id}: ${m.localizationKey}');
        }
      }
      expect(missing, isEmpty,
          reason: 'Missing mutation l10n keys in tr.json: $missing');
    });

    test('all MutationDatabase localizationKeys exist in en.json', () {
      final missing = <String>[];
      for (final m in MutationDatabase.getAll()) {
        if (_resolveKey(enJson, m.localizationKey) == null) {
          missing.add('${m.id}: ${m.localizationKey}');
        }
      }
      expect(missing, isEmpty,
          reason: 'Missing mutation l10n keys in en.json: $missing');
    });

    test('all MutationDatabase localizationKeys exist in de.json', () {
      final missing = <String>[];
      for (final m in MutationDatabase.getAll()) {
        if (_resolveKey(deJson, m.localizationKey) == null) {
          missing.add('${m.id}: ${m.localizationKey}');
        }
      }
      expect(missing, isEmpty,
          reason: 'Missing mutation l10n keys in de.json: $missing');
    });
  });

  group('shortenPhenotype', () {
    test('returns original when shorter than maxLength', () {
      expect(
        PhenotypeLocalizer.shortenPhenotype('Skyblue'),
        'Skyblue',
      );
    });

    test('abbreviates Texas Clearbody', () {
      const long = 'Light Green Texas Clearbody Dominant Clearbody';
      final short = PhenotypeLocalizer.shortenPhenotype(long);

      expect(short, contains('TCB'));
      expect(short, contains('Dom.CB'));
      expect(short.length, lessThan(long.length));
    });

    test('abbreviates Turkish phenotype names', () {
      const long = 'Açık Yeşil Texas Açık Gövde Dominant Açık Gövde';
      final short = PhenotypeLocalizer.shortenPhenotype(long);

      expect(short, contains('TCB'));
      expect(short, contains('Dom.AG'));
      expect(short.length, lessThan(long.length));
    });

    test('abbreviates Yellowface types', () {
      const long = 'Cobalt Yellowface Type II Opaline Cinnamon';
      final short = PhenotypeLocalizer.shortenPhenotype(long);

      expect(short, contains('YF-II'));
      expect(short.length, lessThan(long.length));
    });

    test('stops abbreviating once under maxLength', () {
      const input = 'Light Green Texas Clearbody';
      final short = PhenotypeLocalizer.shortenPhenotype(input, maxLength: 25);

      expect(short.length, lessThanOrEqualTo(25));
    });

    test('respects custom maxLength', () {
      const input = 'Dark Green Spangle Opaline';
      // Already 25 chars, under default 28
      expect(
        PhenotypeLocalizer.shortenPhenotype(input),
        input,
      );
      // But not under 20
      final shortened = PhenotypeLocalizer.shortenPhenotype(input, maxLength: 20);
      expect(shortened.length, lessThan(input.length));
    });
  });
}
