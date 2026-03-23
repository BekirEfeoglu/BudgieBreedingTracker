import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/genetics/widgets/mutation_linkage_data.dart';

void main() {
  group('mutationLinkageMap', () {
    test('contains opaline entry', () {
      expect(mutationLinkageMap.containsKey('opaline'), isTrue);
    });

    test('contains cinnamon entry', () {
      expect(mutationLinkageMap.containsKey('cinnamon'), isTrue);
    });

    test('contains ino entry', () {
      expect(mutationLinkageMap.containsKey('ino'), isTrue);
    });

    test('contains slate entry', () {
      expect(mutationLinkageMap.containsKey('slate'), isTrue);
    });

    test('contains pearly entry', () {
      expect(mutationLinkageMap.containsKey('pearly'), isTrue);
    });

    test('contains pallid entry', () {
      expect(mutationLinkageMap.containsKey('pallid'), isTrue);
    });

    test('contains texas_clearbody entry', () {
      expect(mutationLinkageMap.containsKey('texas_clearbody'), isTrue);
    });

    test('has 7 mutation entries total', () {
      expect(mutationLinkageMap.length, equals(7));
    });

    test('opaline has 3 linkage entries', () {
      expect(mutationLinkageMap['opaline']!.length, equals(3));
    });

    test('opaline-cinnamon linkage is 34 cM', () {
      final entry = mutationLinkageMap['opaline']!
          .firstWhere((e) => e.label == 'Cinnamon');
      expect(entry.centiMorgans, equals(34));
    });

    test('opaline-ino linkage is 30 cM', () {
      final entry = mutationLinkageMap['opaline']!
          .firstWhere((e) => e.label == 'Ino');
      expect(entry.centiMorgans, equals(30));
    });

    test('opaline-slate linkage is 40 cM', () {
      final entry = mutationLinkageMap['opaline']!
          .firstWhere((e) => e.label == 'Slate');
      expect(entry.centiMorgans, equals(40));
    });

    test('cinnamon-ino linkage is 3 cM', () {
      final entry = mutationLinkageMap['cinnamon']!
          .firstWhere((e) => e.label == 'Ino');
      expect(entry.centiMorgans, equals(3));
    });

    test('ino-slate linkage is 2 cM', () {
      final entry = mutationLinkageMap['ino']!
          .firstWhere((e) => e.label == 'Slate');
      expect(entry.centiMorgans, equals(2));
    });

    test('cinnamon-slate linkage is 5 cM', () {
      final entry = mutationLinkageMap['cinnamon']!
          .firstWhere((e) => e.label == 'Slate');
      expect(entry.centiMorgans, equals(5));
    });

    test('pearly shares ino locus position linkages', () {
      final pearlyEntries = mutationLinkageMap['pearly']!;
      final inoEntries = mutationLinkageMap['ino']!;

      for (var i = 0; i < pearlyEntries.length; i++) {
        expect(pearlyEntries[i].label, equals(inoEntries[i].label));
        expect(
            pearlyEntries[i].centiMorgans, equals(inoEntries[i].centiMorgans));
      }
    });

    test('pallid shares ino locus position linkages', () {
      final pallidEntries = mutationLinkageMap['pallid']!;
      final inoEntries = mutationLinkageMap['ino']!;

      for (var i = 0; i < pallidEntries.length; i++) {
        expect(pallidEntries[i].label, equals(inoEntries[i].label));
        expect(
            pallidEntries[i].centiMorgans, equals(inoEntries[i].centiMorgans));
      }
    });

    test('texas_clearbody shares ino locus position linkages', () {
      final tcbEntries = mutationLinkageMap['texas_clearbody']!;
      final inoEntries = mutationLinkageMap['ino']!;

      for (var i = 0; i < tcbEntries.length; i++) {
        expect(tcbEntries[i].label, equals(inoEntries[i].label));
        expect(tcbEntries[i].centiMorgans, equals(inoEntries[i].centiMorgans));
      }
    });

    test('linkage distances are symmetric between opaline and cinnamon', () {
      final opalineToCinnamon = mutationLinkageMap['opaline']!
          .firstWhere((e) => e.label == 'Cinnamon')
          .centiMorgans;
      final cinnamonToOpaline = mutationLinkageMap['cinnamon']!
          .firstWhere((e) => e.label == 'Opaline')
          .centiMorgans;

      expect(opalineToCinnamon, equals(cinnamonToOpaline));
    });

    test('linkage distances are symmetric between ino and slate', () {
      final inoToSlate = mutationLinkageMap['ino']!
          .firstWhere((e) => e.label == 'Slate')
          .centiMorgans;
      final slateToIno = mutationLinkageMap['slate']!
          .firstWhere((e) => e.label == 'Ino')
          .centiMorgans;

      expect(inoToSlate, equals(slateToIno));
    });

    test('all centiMorgans values are positive', () {
      for (final entries in mutationLinkageMap.values) {
        for (final entry in entries) {
          expect(entry.centiMorgans, greaterThan(0));
        }
      }
    });
  });
}
