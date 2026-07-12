import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/linkage_phase.dart';

void main() {
  group('LinkagePhase', () {
    test('fromJson(null) returns auto', () {
      expect(LinkagePhase.fromJson(null), LinkagePhase.auto);
    });

    test('fromJson("coupling") returns coupling', () {
      expect(LinkagePhase.fromJson('coupling'), LinkagePhase.coupling);
    });

    test('fromJson("repulsion") returns repulsion', () {
      expect(LinkagePhase.fromJson('repulsion'), LinkagePhase.repulsion);
    });

    test('fromJson("auto") returns auto', () {
      expect(LinkagePhase.fromJson('auto'), LinkagePhase.auto);
    });

    test('fromJson with unknown value falls back to auto', () {
      expect(LinkagePhase.fromJson('garbage'), LinkagePhase.auto);
    });

    test('toJson round-trips through fromJson for every value', () {
      for (final phase in LinkagePhase.values) {
        expect(LinkagePhase.fromJson(phase.toJson()), phase);
      }
    });
  });

  group('linkagePairKey', () {
    test('produces order-independent key', () {
      expect(linkagePairKey('a', 'b'), 'a|b');
      expect(linkagePairKey('b', 'a'), 'a|b');
      expect(linkagePairKey('a', 'b'), linkagePairKey('b', 'a'));
    });

    test('joins sorted ids with a pipe', () {
      expect(linkagePairKey('ino', 'cinnamon'), 'cinnamon|ino');
    });
  });
}
